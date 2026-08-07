import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/diagnostics/debug_log.dart';
import '../../data/db/app_database.dart';
import 'local_sync_store.dart';

/// Definition einer synchronisierten Tabelle.
typedef SyncTableDef = ({String name, List<String> counters});

/// Synchronisiert die Modul-Inhalte zwischen lokaler Drift-Datenbank und
/// Supabase.
///
/// Arbeitsweise (offline-first):
///   * Push: lokal geaenderte Zeilen (is_dirty) gehen ueber die RPC
///     push_record zum Server. Zaehler-Deltas aus der Outbox werden additiv
///     angewendet, alle anderen Felder per Last-Write-Wins.
///   * Pull: seit dem letzten Abgleich geaenderte Server-Zeilen werden generisch
///     in die passende lokale Tabelle geschrieben (LWW-Guard ueber updated_at).
class SyncEngine {
  SyncEngine(AppDatabase db, this._client) : _store = LocalSyncStore(db);

  final SupabaseClient _client;
  final LocalSyncStore _store;

  /// Alle synchronisierten Tabellen und ihre additiven Zaehler-Spalten.
  static const List<SyncTableDef> tables = [
    (name: 'storage_locations', counters: <String>[]),
    (name: 'products', counters: <String>[]),
    (name: 'inventory_items', counters: ['quantity']),
    (name: 'inventory_batches', counters: ['quantity']),
    (name: 'shopping_lists', counters: <String>[]),
    (name: 'shopping_items', counters: <String>[]),
    (name: 'notes', counters: <String>[]),
    (name: 'note_checklist_items', counters: <String>[]),
    (name: 'medication_plans', counters: ['stock_count']),
    (name: 'medication_logs', counters: <String>[]),
    (name: 'pets', counters: <String>[]),
    (name: 'pet_tasks', counters: <String>[]),
    (name: 'pet_task_logs', counters: <String>[]),
    (name: 'pet_health_entries', counters: <String>[]),
    (name: 'pet_weight_entries', counters: <String>[]),
  ];

  static final Set<String> _knownTables = {for (final t in tables) t.name};
  static final List<String> _tableNames = [for (final t in tables) t.name];

  bool _running = false;

  /// True, wenn lokal noch nicht hochgeladene Aenderungen anstehen.
  Future<bool> hasPendingChanges() => _store.hasPendingChanges(_tableNames);

  /// Wendet einen per Realtime empfangenen sync_records-Datensatz direkt an.
  ///
  /// Spart den Pull-Roundtrip: das Event enthaelt bereits die geaenderte Zeile.
  /// Idempotent und sicher dank Last-Write-Wins in [LocalSyncStore.applyRemote];
  /// der periodische Voll-Pull bleibt als Sicherheitsnetz fuer verpasste Events.
  Future<void> applyRealtimeRecord(Map<String, dynamic> record) async {
    final table = record['table_name'] as String?;
    if (table == null || !_knownTables.contains(table)) return;

    final data = _asData(record['data']);
    if (data == null) return;

    try {
      await _store.applyRemote(table, data);
    } catch (error) {
      debugPrint('[sync] Realtime-Apply fehlgeschlagen: $error');
    }
  }

  /// Ein vollstaendiger Abgleich: erst hochladen, dann herunterladen.
  Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      await push();
      await pull();
    } catch (error, stack) {
      DebugLog.instance.error(
        'sync',
        'Abgleich fehlgeschlagen',
        error: error,
        stack: stack,
      );
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<void> push() async {
    for (final table in tables) {
      final dirty = await _store.dirtyRows(table.name);
      for (final row in dirty) {
        // Alles pro Datensatz absichern: ein einzelner Fehler (Netz, Cast,
        // Serverfehler) darf den gesamten Abgleich nicht abbrechen lassen.
        try {
          final id = row['id'] as String;
          final localUpdatedAt = (row['updated_at'] as num).toInt();

          final deltas = table.counters.isEmpty
              ? (values: <String, double>{}, ids: <String>[])
              : await _store.pendingDeltas(table.name, id);

          final payload = Map<String, dynamic>.from(row)..remove('is_dirty');
          final deletedAt = payload['deleted_at'];

          await _client.rpc(
            'push_record',
            params: {
              '_table': table.name,
              '_id': id,
              '_scope_kind': payload['scope_kind'],
              '_scope_id': payload['scope_id'],
              '_updated_at': _secondsToIso(localUpdatedAt),
              '_deleted_at': deletedAt == null
                  ? null
                  : _secondsToIso((deletedAt as num).toInt()),
              '_data': payload,
              '_counter_deltas': deltas.values,
            },
          );
          await _store.markSynced(table.name, id, localUpdatedAt);
          await _store.clearOutbox(deltas.ids);
        } catch (error) {
          debugPrint('[sync] Push ${table.name} fehlgeschlagen: $error');
        }
      }
    }
  }

  Future<void> pull() async {
    final lastPull = await _store.getMeta('lastPull') ?? '1970-01-01T00:00:00Z';

    // Aufsteigend: der zuletzt gelesene Satz ist der neueste, daraus wird der
    // Wasserstand. (Der Standard von .order() ist absteigend!)
    final records = await _client
        .from('sync_records')
        .select()
        .gt('synced_at', lastPull)
        .order('synced_at', ascending: true);

    String? maxSynced;
    for (final record in records as List) {
      final map = Map<String, dynamic>.from(record as Map);
      // Wasserstand immer mitziehen, auch wenn das Anwenden scheitert, sonst
      // wuerde ein einzelner problematischer Satz den Pull dauerhaft blockieren.
      final synced = map['synced_at'];
      if (synced is String) maxSynced = synced;
      try {
        final table = map['table_name'] as String?;
        if (table == null || !_knownTables.contains(table)) continue;
        final data = _asData(map['data']);
        if (data != null) await _store.applyRemote(table, data);
      } catch (error) {
        debugPrint('[sync] Pull-Datensatz uebersprungen: $error');
      }
    }

    if (maxSynced != null) await _store.setMeta('lastPull', maxSynced);
  }

  /// Bringt das jsonb-Feld `data` in eine Map, egal ob es schon als Map oder
  /// (je nach Transport) als JSON-String ankommt.
  static Map<String, dynamic>? _asData(dynamic data) {
    var value = data;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _secondsToIso(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
          .toIso8601String();
}
