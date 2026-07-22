import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// `uuid` wird von den generierten clientDefault-Aufrufen gebraucht.
import 'tables/common.dart';
import 'tables/household_tables.dart';

part 'app_database.g.dart';

/// Lokale SQLite-Datenbank.
///
/// Sie ist die einzige Wahrheit fuer die Oberflaeche. Die App funktioniert
/// vollstaendig offline; der Server ist ab v0.9 nur Abgleichspartner.
@DriftDatabase(
  tables: [
    Households,
    HouseholdMembers,
    AuditEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// Wird pro Ausbaustufe erhoeht, sobald Tabellen dazukommen.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() => driftDatabase(name: 'multiapp');
}
