import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/scope/app_scope.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository inventory;

  setUp(() {
    db = createTestDatabase();
    inventory = InventoryRepository(db);
  });

  tearDown(() => db.close());

  test('rebindPersonalScope verschiebt private Daten auf die Konto-ID', () async {
    const guestId = 'guest-uuid';
    const accountId = 'account-uuid';
    final guestScope = AppScope.personal(guestId);

    final itemId = await inventory.addItem(
      scope: guestScope,
      userId: guestId,
      name: 'Milch',
      quantity: 1,
      unit: 'liter',
    );

    await db.rebindPersonalScope(guestId, accountId);

    // Unter der alten ID ist nichts mehr.
    expect(
      await inventory.watchItems(AppScope.personal(guestId)).first,
      isEmpty,
    );
    // Unter der Konto-ID taucht der Vorrat auf.
    final migrated =
        await inventory.watchItems(AppScope.personal(accountId)).first;
    expect(migrated, hasLength(1));
    expect(migrated.single.item.id, itemId);

    // Als dirty markiert, damit die Sync-Engine es hochlaedt.
    final row = await inventory.findById(itemId);
    expect(row!.isDirty, isTrue);
    expect(row.scopeId, accountId);
  });

  test('Haushalts-Daten bleiben unberuehrt', () async {
    const guestId = 'guest-uuid';
    const accountId = 'account-uuid';
    final householdScope = AppScope.household('h1', 'Familie');

    await inventory.addItem(
      scope: householdScope,
      userId: guestId,
      name: 'Familienmilch',
      quantity: 2,
      unit: 'liter',
    );

    await db.rebindPersonalScope(guestId, accountId);

    final household = await inventory.watchItems(householdScope).first;
    expect(household, hasLength(1));
    expect(household.single.item.scopeId, 'h1');
  });

  test('gleiche IDs sind ein No-op', () async {
    const id = 'same';
    await inventory.addItem(
      scope: AppScope.personal(id),
      userId: id,
      name: 'Milch',
      quantity: 1,
      unit: 'liter',
    );
    await db.rebindPersonalScope(id, id);
    expect(
      await inventory.watchItems(AppScope.personal(id)).first,
      hasLength(1),
    );
  });
}
