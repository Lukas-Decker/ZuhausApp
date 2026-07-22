import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/shopping_repository.dart';
import '../inventory/inventory_providers.dart';
import 'domain/shopping_transfer.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(databaseProvider)),
);

final shoppingTransferServiceProvider = Provider<ShoppingTransferService>(
  (ref) => ShoppingTransferService(
    inventory: ref.watch(inventoryRepositoryProvider),
    shopping: ref.watch(shoppingRepositoryProvider),
  ),
);

/// Alle Listen des aktiven Kontexts; legt bei Bedarf die Standardliste an.
final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  final identity = ref.watch(identityProvider);
  final repository = ref.watch(shoppingRepositoryProvider);

  repository.ensureDefaultList(scope, identity.userId);
  return repository.watchLists(scope);
});

/// Die gerade geöffnete Liste. `null` bedeutet: erste Liste des Kontexts.
class SelectedShoppingListController extends Notifier<String?> {
  @override
  String? build() {
    // Beim Kontextwechsel zurück auf die Standardliste.
    ref.watch(activeScopeProvider);
    return null;
  }

  void select(String? id) => state = id;
}

final selectedShoppingListIdProvider =
    NotifierProvider<SelectedShoppingListController, String?>(
      SelectedShoppingListController.new,
    );

/// Die tatsächlich angezeigte Liste, aufgelöst gegen die vorhandenen Listen.
final activeShoppingListProvider = Provider<ShoppingList?>((ref) {
  final lists = ref.watch(shoppingListsProvider).value ?? const [];
  if (lists.isEmpty) return null;
  final selected = ref.watch(selectedShoppingListIdProvider);
  if (selected == null) return lists.first;
  for (final list in lists) {
    if (list.id == selected) return list;
  }
  return lists.first;
});

final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final list = ref.watch(activeShoppingListProvider);
  if (list == null) return Stream.value(const []);
  return ref.watch(shoppingRepositoryProvider).watchItems(list.id);
});

/// Knappe Vorräte, die noch nicht offen auf der Liste stehen.
final shoppingSuggestionsProvider = Provider<List<({String id, String name})>>((
  ref,
) {
  final low = ref.watch(lowStockItemsProvider).value ?? const [];
  final items = ref.watch(shoppingItemsProvider).value ?? const [];
  final openNames = items
      .where((i) => !i.isChecked)
      .map((i) => i.name.toLowerCase())
      .toSet();

  return low
      .where((entry) => !openNames.contains(entry.item.name.toLowerCase()))
      .map((entry) => (id: entry.item.id, name: entry.item.name))
      .toList();
});
