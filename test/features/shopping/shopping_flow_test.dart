import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';
import 'package:multiapp/data/repositories/shopping_repository.dart';
import 'package:multiapp/features/shopping/domain/shopping_transfer.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ShoppingRepository shopping;
  late InventoryRepository inventory;
  late ShoppingTransferService transfer;
  late String listId;

  setUp(() async {
    db = createTestDatabase();
    shopping = ShoppingRepository(db);
    inventory = InventoryRepository(db);
    transfer = ShoppingTransferService(
      inventory: inventory,
      shopping: shopping,
    );
    final list = await shopping.ensureDefaultList(personalScope, testUserId);
    listId = list.id;
  });

  tearDown(() => db.close());

  group('addItem', () {
    test('legt einen Posten an', () async {
      await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Milch',
      );
      final items = await shopping.watchItems(listId).first;
      expect(items, hasLength(1));
      expect(items.single.name, 'Milch');
    });

    test('bündelt gleiche offene Posten statt zu duplizieren', () async {
      await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Milch',
        quantity: 1,
      );
      await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'milch',
        quantity: 2,
      );
      final items = await shopping.watchItems(listId).first;
      expect(items, hasLength(1));
      expect(items.single.quantity, 3);
    });

    test('ein abgehakter Posten blockiert das Bündeln nicht', () async {
      final id = await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Milch',
      );
      await shopping.setChecked(id: id, checked: true, userId: testUserId);

      await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Milch',
      );

      final items = await shopping.watchItems(listId).first;
      expect(items, hasLength(2));
    });
  });

  group('ensureDefaultList', () {
    test('liefert dieselbe Liste beim zweiten Aufruf', () async {
      final again = await shopping.ensureDefaultList(personalScope, testUserId);
      expect(again.id, listId);
      final all = await shopping.watchLists(personalScope).first;
      expect(all, hasLength(1));
    });

    test('Kontexte bekommen getrennte Listen', () async {
      await shopping.ensureDefaultList(householdScope, testUserId);
      final personal = await shopping.watchLists(personalScope).first;
      final household = await shopping.watchLists(householdScope).first;
      expect(personal, hasLength(1));
      expect(household, hasLength(1));
      expect(personal.single.id, isNot(household.single.id));
    });
  });

  group('Übernahme ins Inventar', () {
    Future<void> check(String id) =>
        shopping.setChecked(id: id, checked: true, userId: testUserId);

    test('unbekannter Posten wird neu angelegt', () async {
      final id = await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Butter',
        quantity: 2,
      );
      await check(id);

      final result = await transfer.transferChecked(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
      );

      expect(result.created, 1);
      expect(result.increased, 0);
      final items = await inventory.watchItems(personalScope).first;
      expect(items.single.item.name, 'Butter');
      expect(items.single.item.quantity, 2);
    });

    test('vorhandener Bestand wird additiv erhöht', () async {
      await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Butter',
        quantity: 1,
        unit: 'piece',
      );
      final id = await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'butter',
        quantity: 2,
      );
      await check(id);

      final result = await transfer.transferChecked(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
      );

      expect(result.increased, 1);
      expect(result.created, 0);
      final items = await inventory.watchItems(personalScope).first;
      expect(items, hasLength(1));
      expect(items.single.item.quantity, 3);
    });

    test('verknüpfter Vorrat wird gezielt erhöht', () async {
      final invId = await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Spülmittel',
        quantity: 1,
        unit: 'bottle',
        minQuantity: 2,
      );
      final id = await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Spülmittel',
        quantity: 3,
        inventoryItemId: invId,
      );
      await check(id);

      await transfer.transferChecked(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
      );

      final item = await inventory.findById(invId);
      expect(item!.quantity, 4);
    });

    test('nicht abgehakte Posten bleiben unberührt', () async {
      await shopping.addItem(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
        name: 'Offen',
      );
      final result = await transfer.transferChecked(
        scope: personalScope,
        listId: listId,
        userId: testUserId,
      );
      expect(result.total, 0);
    });
  });
}
