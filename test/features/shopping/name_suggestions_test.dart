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

  test('schlaegt Namen aus Produkten und Vorraeten vor', () async {
    await repo.saveProduct(
      scope: personalScope,
      userId: testUserId,
      name: 'Milch',
    );
    await repo.addItem(
      scope: personalScope,
      userId: testUserId,
      name: 'Milchreis',
      quantity: 1,
      unit: 'piece',
    );

    final all = await repo.suggestNames(personalScope, 'milch');
    expect(all.toSet(), {'Milch', 'Milchreis'});

    final reis = await repo.suggestNames(personalScope, 'reis');
    expect(reis, ['Milchreis']);
  });

  test('gleicher Name aus Produkt und Vorrat erscheint nur einmal', () async {
    await repo.saveProduct(
      scope: personalScope,
      userId: testUserId,
      name: 'Butter',
    );
    await repo.addItem(
      scope: personalScope,
      userId: testUserId,
      name: 'Butter',
      quantity: 1,
      unit: 'piece',
    );

    expect(await repo.suggestNames(personalScope, 'butter'), ['Butter']);
  });

  test('leere Eingabe liefert nichts', () async {
    await repo.saveProduct(
      scope: personalScope,
      userId: testUserId,
      name: 'Milch',
    );
    expect(await repo.suggestNames(personalScope, '   '), isEmpty);
  });

  test('respektiert den Kontext', () async {
    await repo.saveProduct(
      scope: householdScope,
      userId: testUserId,
      name: 'Haushaltsmilch',
    );
    // Im privaten Kontext nicht sichtbar.
    expect(await repo.suggestNames(personalScope, 'milch'), isEmpty);
    expect(
      await repo.suggestNames(householdScope, 'milch'),
      ['Haushaltsmilch'],
    );
  });
}
