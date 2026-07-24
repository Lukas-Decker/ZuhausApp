import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../data/db/app_database.dart';
import 'data/audit_service.dart';
import 'data/data_export_service.dart';
import 'data/retention_service.dart';

final dataExportServiceProvider = Provider<DataExportService>(
  (ref) => DataExportService(ref.watch(databaseProvider)),
);

final retentionServiceProvider = Provider<RetentionService>(
  (ref) => RetentionService(ref.watch(databaseProvider)),
);

final auditServiceProvider = Provider<AuditService>(
  (ref) => AuditService(ref.watch(databaseProvider)),
);

/// Die neuesten Audit-Eintraege fuer die Protokoll-Ansicht.
final auditLogProvider = StreamProvider<List<AuditEntry>>(
  (ref) => ref.watch(auditServiceProvider).watchRecent(),
);

/// Startet einmalig die Aufbewahrungs-Bereinigung.
///
/// Wird in der AppShell beobachtet, damit abgelaufene Grabsteine und alte
/// Audit-Eintraege beim Start endgueltig verschwinden.
final retentionRunnerProvider = Provider<void>((ref) {
  final days = ref.watch(
    appSettingsProvider.select((s) => s.retentionDays),
  );
  // Nicht blockierend; Fehler hier duerfen die App nicht stoeren.
  Future.microtask(() async {
    try {
      final removed = await ref.read(retentionServiceProvider).purge(days);
      if (removed > 0) {
        debugPrint('[retention] $removed alte Datensaetze entfernt.');
      }
    } catch (error) {
      debugPrint('[retention] Bereinigung fehlgeschlagen: $error');
    }
  });
});
