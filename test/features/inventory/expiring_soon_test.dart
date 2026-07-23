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

  test('expiringSoon liefert nur Artikel im Fenster', () async {
    await repo.addItem(
      scope: personalScope,
      userId: 'u1',
      name: 'Bald',
      quantity: 1,
      unit: 'piece',
      expiresAt: inDays(2),
    );
    await repo.addItem(
      scope: personalScope,
      userId: 'u1',
      name: 'Spaeter',
      quantity: 1,
      unit: 'piece',
      expiresAt: inDays(30),
    );
    await repo.addItem(
      scope: personalScope,
      userId: 'u1',
      name: 'Ohne Datum',
      quantity: 1,
      unit: 'piece',
    );

    final soon = await repo.expiringSoon(5);
    expect(soon.map((i) => i.name), ['Bald']);
  });

  test('respektiert den Pro-Artikel-Schalter', () async {
    await repo.addItem(
      scope: personalScope,
      userId: 'u1',
      name: 'Stumm',
      quantity: 1,
      unit: 'piece',
      expiresAt: inDays(1),
      remindOnExpiry: false,
    );
    expect(await repo.expiringSoon(5), isEmpty);
  });

  test('kontextuebergreifend (personal + household)', () async {
    await repo.addItem(
      scope: personalScope,
      userId: 'u1',
      name: 'Privat',
      quantity: 1,
      unit: 'piece',
      expiresAt: inDays(1),
    );
    await repo.addItem(
      scope: householdScope,
      userId: 'u1',
      name: 'Haushalt',
      quantity: 1,
      unit: 'piece',
      expiresAt: inDays(1),
    );
    final soon = await repo.expiringSoon(5);
    expect(soon.map((i) => i.name).toSet(), {'Privat', 'Haushalt'});
  });

  test('abgelaufene sind enthalten', () async {
    await repo.addItem(
      scope: personalScope,
      userId: 'u1',
      name: 'Abgelaufen',
      quantity: 1,
      unit: 'piece',
      expiresAt: inDays(-1),
    );
    expect((await repo.expiringSoon(5)).single.name, 'Abgelaufen');
  });
}
