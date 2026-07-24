import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';

/// Entfernt endgueltig, was nur noch als Grabstein (soft-deleted) herumliegt
/// oder als Audit-Eintrag zu alt ist.
///
/// Nur bereits synchronisierte Grabsteine (is_dirty = 0) werden geloescht,
/// damit eine noch nicht hochgeladene Loeschung nicht verloren geht.
class RetentionService {
  RetentionService(this._db);

  final AppDatabase _db;

  /// Loescht alles, dessen Aufbewahrungsfrist abgelaufen ist. Gibt die Anzahl
  /// entfernter Zeilen zurueck. Bei [retentionDays] <= 0 passiert nichts.
  Future<int> purge(int retentionDays) async {
    if (retentionDays <= 0) return 0;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final cutoffSeconds = cutoff.millisecondsSinceEpoch ~/ 1000;

    var removed = 0;
    await _db.transaction(() async {
      for (final table in AppDatabase.dataTables) {
        if (table == 'audit_entries') continue;
        removed += await _db.customUpdate(
          'DELETE FROM $table WHERE deleted_at IS NOT NULL '
          'AND deleted_at < ? AND is_dirty = 0',
          variables: [Variable<int>(cutoffSeconds)],
          updateKind: UpdateKind.delete,
        );
      }
      // Audit-Eintraege werden nach Alter (created_at) bereinigt.
      removed += await _db.customUpdate(
        'DELETE FROM audit_entries WHERE created_at < ?',
        variables: [Variable<int>(cutoffSeconds)],
        updateKind: UpdateKind.delete,
      );
    });
    return removed;
  }
}
