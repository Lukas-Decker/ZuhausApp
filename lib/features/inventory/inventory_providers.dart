import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/inventory_repository.dart';
import 'data/open_food_facts_service.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(databaseProvider)),
);

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  final service = OpenFoodFactsService();
  ref.onDispose(service.dispose);
  return service;
});

/// Lagerorte des aktiven Kontexts. Legt beim ersten Zugriff die Standardorte an.
final storageLocationsProvider = StreamProvider<List<StorageLocation>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  final identity = ref.watch(identityProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  repository.ensureDefaultLocations(scope, identity.userId);
  return repository.watchLocations(scope);
});

class InventorySearchController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final inventorySearchProvider =
    NotifierProvider<InventorySearchController, String>(
      InventorySearchController.new,
    );

class InventoryFilterController extends Notifier<InventoryFilter> {
  @override
  InventoryFilter build() => InventoryFilter.all;

  void set(InventoryFilter value) => state = value;
}

final inventoryFilterProvider =
    NotifierProvider<InventoryFilterController, InventoryFilter>(
      InventoryFilterController.new,
    );

/// Die gefilterte Vorratsliste des aktiven Kontexts.
final inventoryItemsProvider = StreamProvider<List<InventoryEntry>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  final search = ref.watch(inventorySearchProvider);
  final filter = ref.watch(inventoryFilterProvider);

  return ref
      .watch(inventoryRepositoryProvider)
      .watchItems(scope, search: search, filter: filter);
});

/// Knappe Artikel, unabhängig von Suche und Filter der Liste.
/// Grundlage für Abzeichen und die Einkaufsvorschläge ab v0.3.
final lowStockItemsProvider = StreamProvider<List<InventoryEntry>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  return ref
      .watch(inventoryRepositoryProvider)
      .watchItems(scope, filter: InventoryFilter.low);
});

/// Bald ablaufende oder abgelaufene Artikel, unabhängig von der Listenansicht.
final expiringItemsProvider = StreamProvider<List<InventoryEntry>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  return ref
      .watch(inventoryRepositoryProvider)
      .watchItems(scope, filter: InventoryFilter.expiring);
});
