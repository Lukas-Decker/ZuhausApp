import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = InventoryRepository(db);
  });

  tearDown(() => db.close());

  group('Kontext-Abschottung', () {
    test('Vorräte eines Kontexts tauchen im anderen nicht auf', () async {
      await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Privates Bier',
        quantity: 6,
        unit: 'bottle',
      );
      await repository.addItem(
        scope: householdScope,
        userId: testUserId,
        name: 'Familienmilch',
        quantity: 2,
        unit: 'liter',
      );

      final personal = await repository.watchItems(personalScope).first;
      final household = await repository.watchItems(householdScope).first;

      expect(personal.map((e) => e.item.name), ['Privates Bier']);
      expect(household.map((e) => e.item.name), ['Familienmilch']);
    });

    test('findMatching sucht nur im eigenen Kontext', () async {
      await repository.addItem(
        scope: householdScope,
        userId: testUserId,
        name: 'Butter',
        quantity: 1,
        unit: 'piece',
      );
      expect(
        await repository.findMatching(personalScope, name: 'Butter'),
        isNull,
      );
      expect(
        await repository.findMatching(householdScope, name: 'butter'),
        isNotNull,
      );
    });
  });

  group('ensureDefaultLocations', () {
    test('legt die Standardorte genau einmal an', () async {
      await repository.ensureDefaultLocations(personalScope, testUserId);
      await repository.ensureDefaultLocations(personalScope, testUserId);

      final locations = await repository.watchLocations(personalScope).first;
      expect(locations, hasLength(4));
      expect(locations.first.name, 'Kühlschrank');
    });

    test('jeder Kontext bekommt eigene Orte', () async {
      await repository.ensureDefaultLocations(personalScope, testUserId);
      await repository.ensureDefaultLocations(householdScope, testUserId);

      expect(
        await repository.watchLocations(personalScope).first,
        hasLength(4),
      );
      expect(
        await repository.watchLocations(householdScope).first,
        hasLength(4),
      );
    });
  });

  group('adjustQuantity', () {
    test('addiert und subtrahiert', () async {
      final id = await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Eier',
        quantity: 10,
        unit: 'piece',
      );

      expect(
        await repository.adjustQuantity(id: id, userId: testUserId, delta: 2),
        12,
      );
      expect(
        await repository.adjustQuantity(id: id, userId: testUserId, delta: -5),
        7,
      );
    });

    test('geht nie unter null', () async {
      final id = await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Eier',
        quantity: 1,
        unit: 'piece',
      );
      expect(
        await repository.adjustQuantity(id: id, userId: testUserId, delta: -5),
        0,
      );
    });

    test('mehrere Verbräuche summieren sich', () async {
      final id = await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Eier',
        quantity: 10,
        unit: 'piece',
      );
      for (var i = 0; i < 3; i++) {
        await repository.adjustQuantity(id: id, userId: testUserId, delta: -1);
      }
      final item = await repository.findById(id);
      expect(item!.quantity, 7);
    });
  });

  group('Löschen', () {
    test('deleteItem entfernt den Artikel nur weich', () async {
      final id = await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Alt',
        quantity: 1,
        unit: 'piece',
      );
      await repository.deleteItem(id, testUserId);

      expect(await repository.watchItems(personalScope).first, isEmpty);
      final row = await repository.findById(id);
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);
      expect(row.isDirty, isTrue);
    });

    test('deleteLocation behält die Vorräte und löst die Zuordnung', () async {
      final locationId = await repository.createLocation(
        scope: personalScope,
        userId: testUserId,
        name: 'Keller',
        iconKey: 'basement',
      );
      final itemId = await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Kartoffeln',
        quantity: 5,
        unit: 'kilogram',
        locationId: locationId,
      );

      await repository.deleteLocation(locationId, testUserId);

      final items = await repository.watchItems(personalScope).first;
      expect(items, hasLength(1));
      expect(items.single.item.id, itemId);
      expect(items.single.item.locationId, isNull);
      expect(items.single.location, isNull);
    });
  });

  group('Suche und Filter', () {
    setUp(() async {
      await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Milch',
        quantity: 1,
        unit: 'liter',
        minQuantity: 2,
        barcode: '4001234567890',
      );
      await repository.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Joghurt',
        quantity: 5,
        unit: 'piece',
        expiresAt: DateTime.now().add(const Duration(days: 2)),
      );
    });

    test('Suche trifft Name und Barcode', () async {
      expect(
        await repository.watchItems(personalScope, search: 'milc').first,
        hasLength(1),
      );
      expect(
        await repository.watchItems(personalScope, search: '400123').first,
        hasLength(1),
      );
      expect(
        await repository.watchItems(personalScope, search: 'xyz').first,
        isEmpty,
      );
    });

    test('Filter knapp und ablaufend', () async {
      final low = await repository
          .watchItems(personalScope, filter: InventoryFilter.low)
          .first;
      expect(low.map((e) => e.item.name), ['Milch']);

      final expiring = await repository
          .watchItems(personalScope, filter: InventoryFilter.expiring)
          .first;
      expect(expiring.map((e) => e.item.name), ['Joghurt']);
    });
  });

  group('Produkte', () {
    test('saveProduct aktualisiert statt zu duplizieren', () async {
      final first = await repository.saveProduct(
        scope: personalScope,
        userId: testUserId,
        name: 'Milch',
        barcode: '4001234567890',
      );
      final second = await repository.saveProduct(
        scope: personalScope,
        userId: testUserId,
        name: 'Vollmilch',
        barcode: '4001234567890',
        brand: 'Weihenstephan',
      );

      expect(second, first);
      final product = await repository.findProduct(
        personalScope,
        '4001234567890',
      );
      expect(product!.name, 'Vollmilch');
      expect(product.brand, 'Weihenstephan');
    });

    test('gleicher Barcode in zwei Kontexten bleibt getrennt', () async {
      final a = await repository.saveProduct(
        scope: personalScope,
        userId: testUserId,
        name: 'Milch',
        barcode: '4001234567890',
      );
      final b = await repository.saveProduct(
        scope: householdScope,
        userId: testUserId,
        name: 'Milch',
        barcode: '4001234567890',
      );
      expect(a, isNot(b));
    });
  });
}
