import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// `uuid` wird von den generierten clientDefault-Aufrufen gebraucht.
import 'tables/common.dart';
import 'tables/household_tables.dart';
import 'tables/inventory_tables.dart';
import 'tables/shopping_tables.dart';

part 'app_database.g.dart';

/// Lokale SQLite-Datenbank.
///
/// Sie ist die einzige Wahrheit für die Oberfläche. Die App funktioniert
/// vollständig offline; der Server ist ab v0.9 nur Abgleichspartner.
@DriftDatabase(
  tables: [
    Households,
    HouseholdMembers,
    AuditEntries,
    StorageLocations,
    Products,
    InventoryItems,
    ShoppingLists,
    ShoppingItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// Wird pro Ausbaustufe erhöht, sobald Tabellen dazukommen.
  ///
  /// 1: Haushalte, Mitglieder, Audit-Log (v0.1)
  /// 2: Lagerorte, Produkte, Vorräte (v0.2)
  /// 3: Einkaufslisten und Posten (v0.3)
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(storageLocations);
        await m.createTable(products);
        await m.createTable(inventoryItems);
      }
      if (from < 3) {
        await m.createTable(shoppingLists);
        await m.createTable(shoppingItems);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() => driftDatabase(name: 'multiapp');
}
