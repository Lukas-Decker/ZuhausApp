import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';
import 'package:multiapp/data/repositories/medication_repository.dart';
import 'package:multiapp/features/sync/local_sync_store.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LocalSyncStore store;
  late InventoryRepository inventory;
  late MedicationRepository meds;

  setUp(() {
    db = createTestDatabase();
    store = LocalSyncStore(db);
    inventory = InventoryRepository(db);
    meds = MedicationRepository(db);
  });

  tearDown(() => db.close());

  group('Inventar-Zaehler', () {
    test('adjustQuantity verbucht das tatsaechlich angewendete Delta', () async {
      final id = await inventory.addItem(
        scope: personalScope,
        userId: 'u1',
        name: 'Eier',
        quantity: 10,
        unit: 'piece',
      );
      await inventory.adjustQuantity(id: id, userId: 'u1', delta: -3);
      await inventory.adjustQuantity(id: id, userId: 'u1', delta: 1);

      final deltas = await store.pendingDeltas('inventory_items', id);
      expect(deltas.values['quantity'], -2);
    });

    test('Clamp auf 0 verbucht nur das real angewendete Delta', () async {
      final id = await inventory.addItem(
        scope: personalScope,
        userId: 'u1',
        name: 'Eier',
        quantity: 1,
        unit: 'piece',
      );
      await inventory.adjustQuantity(id: id, userId: 'u1', delta: -5);
      final deltas = await store.pendingDeltas('inventory_items', id);
      // Von 1 auf 0: angewendet wurde -1, nicht -5.
      expect(deltas.values['quantity'], -1);
    });

    test('addItem erzeugt kein Delta (Startwert steckt in der Zeile)', () async {
      final id = await inventory.addItem(
        scope: personalScope,
        userId: 'u1',
        name: 'Neu',
        quantity: 7,
        unit: 'piece',
      );
      final deltas = await store.pendingDeltas('inventory_items', id);
      expect(deltas.values, isEmpty);
    });

    test('updateItem mit absoluter Menge verbucht die Differenz', () async {
      final id = await inventory.addItem(
        scope: personalScope,
        userId: 'u1',
        name: 'Milch',
        quantity: 2,
        unit: 'liter',
      );
      await inventory.updateItem(id: id, userId: 'u1', quantity: 5);
      final deltas = await store.pendingDeltas('inventory_items', id);
      expect(deltas.values['quantity'], 3);
    });
  });

  group('Medikamenten-Vorrat', () {
    test('recordIntake genommen verbucht negatives Delta', () async {
      final id = await meds.upsertPlan(
        scope: personalScope,
        userId: 'u1',
        name: 'Ibu',
        dosage: '1',
        form: 'tablet',
        scheduleType: 'daily',
        times: '08:00',
        weekdays: '',
        intervalHours: 8,
        stockCount: 10,
        dosePerIntake: 2,
      );
      final plan = await meds.getPlan(id);
      await meds.recordIntake(
        scope: personalScope,
        userId: 'u1',
        plan: plan!,
        scheduledFor: DateTime(2026, 7, 23, 8),
        status: 'taken',
      );
      final deltas = await store.pendingDeltas('medication_plans', id);
      expect(deltas.values['stock_count'], -2);
    });

    test('upsertPlan mit geaendertem Vorrat verbucht die Differenz', () async {
      final id = await meds.upsertPlan(
        scope: personalScope,
        userId: 'u1',
        name: 'Ibu',
        dosage: '1',
        form: 'tablet',
        scheduleType: 'daily',
        times: '08:00',
        weekdays: '',
        intervalHours: 8,
        stockCount: 10,
      );
      // Vorrat im Editor von 10 auf 25 gesetzt.
      await meds.upsertPlan(
        id: id,
        scope: personalScope,
        userId: 'u1',
        name: 'Ibu',
        dosage: '1',
        form: 'tablet',
        scheduleType: 'daily',
        times: '08:00',
        weekdays: '',
        intervalHours: 8,
        stockCount: 25,
      );
      final deltas = await store.pendingDeltas('medication_plans', id);
      expect(deltas.values['stock_count'], 15);
    });
  });
}
