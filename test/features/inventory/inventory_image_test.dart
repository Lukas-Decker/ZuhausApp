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

  test('watchItems liefert die Produkt-Bild-URL des verknuepften Produkts',
      () async {
    final productId = await repo.saveProduct(
      scope: personalScope,
      userId: testUserId,
      name: 'Milch',
      imageUrl: 'https://example.org/milch.jpg',
    );
    await repo.addItem(
      scope: personalScope,
      userId: testUserId,
      name: 'Milch',
      quantity: 1,
      unit: 'piece',
      productId: productId,
    );

    final entries = await repo.watchItems(personalScope).first;
    expect(entries.single.imageUrl, 'https://example.org/milch.jpg');
  });

  test('ohne verknuepftes Produkt ist die Bild-URL null', () async {
    await repo.addItem(
      scope: personalScope,
      userId: testUserId,
      name: 'Handnotiz',
      quantity: 1,
      unit: 'piece',
    );

    final entries = await repo.watchItems(personalScope).first;
    expect(entries.single.imageUrl, isNull);
  });
}
