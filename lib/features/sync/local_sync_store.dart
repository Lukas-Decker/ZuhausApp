import 'package:drift/drift.dart';

import '../../data/db/app_database.dart';

/// Die datenbanknahen Sync-Operationen, ohne Netzwerk.
///
/// Getrennt von der [SyncEngine], damit die Merge- und LWW-Logik ohne Supabase
/// testbar ist.
class LocalSyncStore {
  LocalSyncStore(this._db) {
    for (final table in _db.allTables) {
      _tableInfoByName[table.actualTableName] = table;
    }
  }

  final AppDatabase _db;
  final Map<String, TableInfo> _tableInfoByName = {};

  /// Summiert die ausstehenden Zaehler-Deltas eines Datensatzes.
  Future<({Map<String, double> values, List<String> ids})> pendingDeltas(
    String table,
    String rowId,
  ) async {
    final entries = await (_db.select(_db.syncOutbox)
          ..where((o) => o.targetTable.equals(table) & o.rowId.equals(rowId)))
        .get();
    final values = <String, double>{};
    final ids = <String>[];
    for (final entry in entries) {
      values[entry.field] = (values[entry.field] ?? 0) + entry.delta;
      ids.add(entry.id);
    }
    return (values: values, ids: ids);
  }

  Future<void> clearOutbox(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.syncOutbox)..where((o) => o.id.isIn(ids))).go();
  }

  /// True, wenn es lokal noch nicht hochgeladene Aenderungen gibt (dirty rows
  /// oder Zaehler-Deltas). Damit ein durch einen Server-Apply ausgeloestes
  /// Tabellen-Update keinen unnoetigen Abgleich anstoesst.
  Future<bool> hasPendingChanges(List<String> tables) async {
    final outbox = await (_db.select(_db.syncOutbox)..limit(1)).get();
    if (outbox.isNotEmpty) return true;
    for (final table in tables) {
      final rows = await _db
          .customSelect('SELECT 1 FROM $table WHERE is_dirty = 1 LIMIT 1')
          .get();
      if (rows.isNotEmpty) return true;
    }
    return false;
  }

  /// Lokal geaenderte Zeilen einer Tabelle (fuer den Push).
  Future<List<Map<String, dynamic>>> dirtyRows(String table) async {
    final rows = await _db
        .customSelect('SELECT * FROM $table WHERE is_dirty = 1')
        .get();
    return [for (final row in rows) Map<String, dynamic>.from(row.data)];
  }

  /// Markiert eine Zeile als abgeglichen, aber nur wenn sie seit dem Lesen
  /// unveraendert blieb (sonst wuerde eine zwischenzeitliche Aenderung verloren).
  Future<void> markSynced(String table, String id, int updatedAtSeconds) async {
    await _db.customUpdate(
      'UPDATE $table SET is_dirty = 0 WHERE id = ? AND updated_at = ?',
      variables: [Variable<String>(id), Variable<int>(updatedAtSeconds)],
      updateKind: UpdateKind.update,
    );
  }

  /// Schreibt einen vom Server geladenen Datensatz lokal, per Last-Write-Wins
  /// ueber updated_at. Aeltere Server-Staende ueberschreiben nichts.
  Future<void> applyRemote(String table, Map<String, dynamic> data) async {
    final info = _tableInfoByName[table];
    if (info == null) return;

    final validColumns = info.$columns.map((c) => c.$name).toSet();
    final cols = data.keys
        .where((k) => k != 'is_dirty' && validColumns.contains(k))
        .toList();
    if (!cols.contains('id') || !cols.contains('updated_at')) return;

    final allCols = [...cols, 'is_dirty'];
    final placeholders = List.filled(allCols.length, '?').join(', ');
    final updateSet =
        '${cols.map((c) => '$c = excluded.$c').join(', ')}, is_dirty = 0';

    final sql =
        'INSERT INTO $table (${allCols.join(', ')}) VALUES ($placeholders) '
        'ON CONFLICT(id) DO UPDATE SET $updateSet '
        'WHERE excluded.updated_at >= $table.updated_at';

    final variables = [
      for (final c in cols) Variable(data[c]),
      const Variable<int>(0),
    ];

    await _db.customInsert(sql, variables: variables, updates: {info});
  }

  Future<String?> getMeta(String key) async {
    final row = await (_db.select(_db.syncMeta)..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) async {
    await _db
        .into(_db.syncMeta)
        .insertOnConflictUpdate(SyncMetaData(key: key, value: value));
  }
}
