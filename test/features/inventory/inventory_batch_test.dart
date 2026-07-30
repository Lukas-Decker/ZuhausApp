import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = InventoryRepository(db);
  });

  tearDown(() => db.close());

  DateTime inDays(int d) => DateTime.now().add(Duration(days: d));

  Future<String> newItem() => repo.addItem(
    scope: personalScope,
    userId: testUserId,
    name: 'Joghurt',
    quantity: 0,
    unit: 'piece',
  );

  test('addBatch erhoeht den Gesamtbestand und setzt das fruehste MHD', () async {
    final itemId = await newItem();
    await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 2,
      expiresAt: inDays(10),
    );
    await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 1,
      expiresAt: inDays(3),
    );

    final item = await repo.findById(itemId);
    expect(item!.quantity, 3);
    // Fruehstes MHD (3 Tage) als Zusammenfassung.
    expect(item.expiresAt!.day, inDays(3).day);
  });

  test('consumeEarliest verbraucht die zuerst ablaufende Charge (FIFO)', () async {
    final itemId = await newItem();
    await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 2,
      expiresAt: inDays(10),
    );
    await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 1,
      expiresAt: inDays(3),
    );

    await repo.consumeEarliest(itemId: itemId, userId: testUserId);

    final item = await repo.findById(itemId);
    // Eine Einheit weniger im Gesamtbestand.
    expect(item!.quantity, 2);
    // Die 3-Tage-Charge ist leer und entfernt; fruehstes MHD nun 10 Tage.
    expect(item.expiresAt!.day, inDays(10).day);

    final batches = await repo.watchBatches(itemId).first;
    expect(batches, hasLength(1));
    expect(batches.single.quantity, 2);
  });

  test('deleteBatch zieht die Restmenge vom Gesamtbestand ab', () async {
    final itemId = await newItem();
    final batchId = await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 4,
      expiresAt: inDays(5),
    );
    expect((await repo.findById(itemId))!.quantity, 4);

    await repo.deleteBatch(batchId, testUserId);
    expect((await repo.findById(itemId))!.quantity, 0);
  });

  test('watchBatchAggregates fasst Menge, MHD und Anzahl zusammen', () async {
    final itemId = await newItem();
    await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 2,
      expiresAt: inDays(10),
    );
    await repo.addBatch(
      scope: personalScope,
      userId: testUserId,
      itemId: itemId,
      quantity: 3,
      expiresAt: inDays(4),
    );

    final aggregates = await repo.watchBatchAggregates(personalScope).first;
    final agg = aggregates[itemId]!;
    expect(agg.total, 5);
    expect(agg.count, 2);
    expect(agg.earliest!.day, inDays(4).day);
  });
}
