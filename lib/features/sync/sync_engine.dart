import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _running = false;

  /// Ein vollstaendiger Abgleich: erst hochladen, dann herunterladen.
  Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      await push();
      await pull();
    } catch (error) {
      debugPrint('[sync] Abgleich fehlgeschlagen: $error');
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<void> push() async {
    for (final table in tables) {
      final dirty = await _store.dirtyRows(table.name);
      for (final data in dirty) {
        final id = data['id'] as String;
        final localUpdatedAt = data['updated_at'] as int;

        final deltas = table.counters.isEmpty
            ? (values: <String, double>{}, ids: <String>[])
            : await _store.pendingDeltas(table.name, id);

        data.remove('is_dirty');

        try {
          await _client.rpc(
            'push_record',
            params: {
              '_table': table.name,
              '_id': id,
              '_scope_kind': data['scope_kind'],
              '_scope_id': data['scope_id'],
              '_updated_at': _secondsToIso(localUpdatedAt),
              '_deleted_at': data['deleted_at'] == null
                  ? null
                  : _secondsToIso(data['deleted_at'] as int),
              '_data': data,
              '_counter_deltas': deltas.values,
            },
          );
          await _store.markSynced(table.name, id, localUpdatedAt);
          await _store.clearOutbox(deltas.ids);
        } catch (error) {
          debugPrint('[sync] Push ${table.name}/$id fehlgeschlagen: $error');
        }
      }
    }
  }

  Future<void> pull() async {
    final lastPull = await _store.getMeta('lastPull') ?? '1970-01-01T00:00:00Z';

    final records = await _client
        .from('sync_records')
        .select()
        .gt('synced_at', lastPull)
        .order('synced_at');

    String? maxSynced;
    for (final record in records as List) {
      final map = record as Map<String, dynamic>;
      maxSynced = map['synced_at'] as String;
      final table = map['table_name'] as String;
      if (!_knownTables.contains(table)) continue;
      await _store.applyRemote(table, Map<String, dynamic>.from(map['data'] as Map));
    }

    if (maxSynced != null) await _store.setMeta('lastPull', maxSynced);
  }

  static String _secondsToIso(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
          .toIso8601String();
}
