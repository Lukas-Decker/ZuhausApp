import 'package:drift/drift.dart';

import '../../../core/scope/app_scope.dart';
import '../../../data/db/app_database.dart';

/// Schreibt und liest Eintraege im Aktivitaetsprotokoll (Audit-Log).
///
/// Bewusst nur lokal: das Protokoll dokumentiert datenschutzrelevante
/// Handlungen auf diesem Geraet (Einwilligungen, Export, App-Schloss,
/// Kontoloeschung) und wird nicht synchronisiert.
class AuditService {
  AuditService(this._db);

  final AppDatabase _db;

  Future<void> log({
    required AppScope scope,
    required String entityType,
    required String action,
    required String summary,
    String entityId = '-',
    String? actorName,
  }) async {
    await _db
        .into(_db.auditEntries)
        .insert(
          AuditEntriesCompanion.insert(
            scopeKind: scope.kind.name,
            scopeId: scope.id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            summary: summary,
            actorName: Value(actorName),
            // Rein lokal: nicht als "dirty" markieren, damit der Sync es
            // ignoriert.
            isDirty: const Value(false),
          ),
        );
  }

  /// Die neuesten Eintraege, fuer die Protokoll-Ansicht.
  Stream<List<AuditEntry>> watchRecent({int limit = 200}) {
    return (_db.select(_db.auditEntries)
          ..where((a) => a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .watch();
  }
}
