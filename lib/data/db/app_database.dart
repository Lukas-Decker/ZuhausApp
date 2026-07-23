import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// `uuid` wird von den generierten clientDefault-Aufrufen gebraucht.
import 'tables/common.dart';
import 'tables/household_tables.dart';
import 'tables/inventory_tables.dart';
import 'tables/medication_tables.dart';
import 'tables/notes_tables.dart';
import 'tables/pet_tables.dart';
import 'tables/shopping_tables.dart';
import 'tables/sync_tables.dart';

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
    Notes,
    NoteChecklistItems,
    MedicationPlans,
    MedicationLogs,
    Pets,
    PetTasks,
    PetTaskLogs,
    PetHealthEntries,
    PetWeightEntries,
    SyncOutbox,
    SyncMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// Wird pro Ausbaustufe erhöht, sobald Tabellen dazukommen.
  ///
  /// 1: Haushalte, Mitglieder, Audit-Log (v0.1)
  /// 2: Lagerorte, Produkte, Vorräte (v0.2)
  /// 3: Einkaufslisten und Posten (v0.3)
  /// 4: Notizen und Checklistenpunkte (v0.4)
  /// 5: Medikamentenpläne und Einnahme-Log (v0.5)
  /// 6: Tiere, Aufgaben, Gesundheit, Gewicht (v0.6)
  /// 7: Sync-Outbox und -Metadaten (v0.9)
  @override
  int get schemaVersion => 7;

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
      if (from < 4) {
        await m.createTable(notes);
        await m.createTable(noteChecklistItems);
      }
      if (from < 5) {
        await m.createTable(medicationPlans);
        await m.createTable(medicationLogs);
      }
      if (from < 6) {
        await m.createTable(pets);
        await m.createTable(petTasks);
        await m.createTable(petTaskLogs);
        await m.createTable(petHealthEntries);
        await m.createTable(petWeightEntries);
      }
      if (from < 7) {
        await m.createTable(syncOutbox);
        await m.createTable(syncMeta);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // WAL erlaubt gleichzeitiges Lesen waehrend eines Schreibvorgangs;
      // busy_timeout laesst konkurrierende Schreibzugriffe kurz warten statt
      // sofort mit "database is locked" zu scheitern (z.B. zwei App-Fenster).
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA busy_timeout = 4000');
    },
  );

  /// Alle Tabellen, deren Zeilen an einem Scope haengen (scope_kind/scope_id).
  static const _scopedTables = [
    'audit_entries',
    'storage_locations',
    'products',
    'inventory_items',
    'shopping_lists',
    'shopping_items',
    'notes',
    'note_checklist_items',
    'medication_plans',
    'medication_logs',
    'pets',
    'pet_tasks',
    'pet_task_logs',
    'pet_health_entries',
    'pet_weight_entries',
  ];

  /// Bindet die privaten Daten einer Gast-Identitaet an eine Konto-ID.
  ///
  /// Wird beim ersten Login aufgerufen: alle personal-Scope-Zeilen mit der
  /// alten lokalen Nutzer-ID werden auf die Supabase-Nutzer-ID umgeschrieben,
  /// damit vorhandene Vorraete, Notizen usw. erhalten bleiben. Zeilen werden
  /// dabei als "dirty" markiert, damit die spaetere Sync-Engine sie hochlaedt.
  Future<void> rebindPersonalScope(String oldUserId, String newUserId) async {
    if (oldUserId == newUserId) return;
    await transaction(() async {
      for (final table in _scopedTables) {
        await customUpdate(
          'UPDATE $table SET scope_id = ?, is_dirty = 1, updated_at = ? '
          "WHERE scope_kind = 'personal' AND scope_id = ?",
          variables: [
            Variable<String>(newUserId),
            Variable<DateTime>(DateTime.now()),
            Variable<String>(oldUserId),
          ],
          updateKind: UpdateKind.update,
        );
      }
    });
  }

  /// Vermerkt eine additive Zaehler-Aenderung fuer den Sync.
  ///
  /// Wird von den Repositories zusammen mit der eigentlichen Mengenaenderung
  /// aufgerufen. Beim Push werden diese Deltas serverseitig atomar addiert, so
  /// geht bei gleichzeitiger Aenderung auf mehreren Geraeten nichts verloren.
  Future<void> logCounterDelta({
    required String table,
    required String rowId,
    required String field,
    required double delta,
  }) async {
    if (delta == 0) return;
    await into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        targetTable: table,
        rowId: rowId,
        field: field,
        delta: delta,
      ),
    );
  }

  static QueryExecutor _open() => driftDatabase(name: 'multiapp');
}
