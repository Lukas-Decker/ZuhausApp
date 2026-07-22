import 'package:drift/drift.dart';

import '../../core/scope/app_scope.dart';
import '../db/app_database.dart';
import '../db/tables/common.dart';

class ShoppingRepository {
  ShoppingRepository(this._db);

  static const defaultListName = 'Einkauf';

  final AppDatabase _db;

  // --- Listen --------------------------------------------------------------

  Stream<List<ShoppingList>> watchLists(AppScope scope) {
    return (_db.select(_db.shoppingLists)
          ..where((l) => l.scopeKind.equals(scope.kind.name))
          ..where((l) => l.scopeId.equals(scope.id))
          ..where((l) => l.deletedAt.isNull())
          ..orderBy([
            (l) => OrderingTerm.asc(l.sortOrder),
            (l) => OrderingTerm.asc(l.createdAt),
          ]))
        .watch();
  }

  /// Stellt sicher, dass der Kontext mindestens eine Liste hat.
  Future<ShoppingList> ensureDefaultList(AppScope scope, String userId) async {
    final existing = await (_db.select(_db.shoppingLists)
          ..where((l) => l.scopeKind.equals(scope.kind.name))
          ..where((l) => l.scopeId.equals(scope.id))
          ..where((l) => l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing;

    return createList(scope: scope, userId: userId, name: defaultListName);
  }

  Future<ShoppingList> createList({
    required AppScope scope,
    required String userId,
    required String name,
  }) async {
    final id = uuid.v4();
    await _db.into(_db.shoppingLists).insert(
      ShoppingListsCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        name: name,
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
    return (_db.select(_db.shoppingLists)..where((l) => l.id.equals(id)))
        .getSingle();
  }

  Future<void> renameList(String id, String name, String userId) async {
    await (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
      ShoppingListsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> deleteList(String id, String userId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
        ShoppingListsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(_db.shoppingItems)..where((i) => i.listId.equals(id)))
          .write(
        ShoppingItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
    });
  }

  // --- Posten --------------------------------------------------------------

  Stream<List<ShoppingItem>> watchItems(String listId) {
    return (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId))
          ..where((i) => i.deletedAt.isNull())
          ..orderBy([
            (i) => OrderingTerm.asc(i.isChecked),
            (i) => OrderingTerm.asc(i.category),
            (i) => OrderingTerm.asc(i.createdAt),
          ]))
        .watch();
  }

  /// Fügt einen Posten hinzu.
  ///
  /// Steht derselbe Name schon offen auf der Liste, wird die Menge addiert
  /// statt ein Duplikat anzulegen. Gibt die ID des betroffenen Postens zurück.
  Future<String> addItem({
    required AppScope scope,
    required String listId,
    required String userId,
    required String name,
    double quantity = 1,
    String unit = 'piece',
    String category = 'other',
    String? note,
    String? inventoryItemId,
    String? barcode,
  }) async {
    final trimmed = name.trim();

    final open = await (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId))
          ..where((i) => i.deletedAt.isNull())
          ..where((i) => i.isChecked.equals(false))
          ..where((i) => i.name.lower().equals(trimmed.toLowerCase()))
          ..where((i) => i.unit.equals(unit))
          ..limit(1))
        .getSingleOrNull();

    if (open != null) {
      await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(open.id)))
          .write(
        ShoppingItemsCompanion(
          quantity: Value(open.quantity + quantity),
          updatedAt: Value(DateTime.now()),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      return open.id;
    }

    final id = uuid.v4();
    await _db.into(_db.shoppingItems).insert(
      ShoppingItemsCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        listId: listId,
        name: trimmed,
        quantity: Value(quantity),
        unit: Value(unit),
        category: Value(category),
        note: Value(note),
        inventoryItemId: Value(inventoryItemId),
        barcode: Value(barcode),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
    return id;
  }

  Future<void> updateItem({
    required String id,
    required String userId,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    Value<String?> note = const Value.absent(),
  }) async {
    await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id))).write(
      ShoppingItemsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        quantity: quantity == null ? const Value.absent() : Value(quantity),
        unit: unit == null ? const Value.absent() : Value(unit),
        category: category == null ? const Value.absent() : Value(category),
        note: note,
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> setChecked({
    required String id,
    required bool checked,
    required String userId,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id))).write(
      ShoppingItemsCompanion(
        isChecked: Value(checked),
        checkedAt: Value(checked ? now : null),
        checkedBy: Value(checked ? userId : null),
        updatedAt: Value(now),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> deleteItem(String id, String userId) async {
    final now = DateTime.now();
    await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id))).write(
      ShoppingItemsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> deleteCheckedItems(String listId, String userId) async {
    final now = DateTime.now();
    await (_db.update(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId))
          ..where((i) => i.isChecked.equals(true))
          ..where((i) => i.deletedAt.isNull()))
        .write(
      ShoppingItemsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<List<ShoppingItem>> checkedItems(String listId) {
    return (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId))
          ..where((i) => i.isChecked.equals(true))
          ..where((i) => i.deletedAt.isNull()))
        .get();
  }
}
