import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/inventory_repository.dart';
import 'data/expiry_notification_scheduler.dart';
import 'data/open_food_facts_service.dart';
import 'data/product_image_cache.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(databaseProvider)),
);

final expiryNotificationSchedulerProvider =
    Provider<ExpiryNotificationScheduler>(
      (ref) => ExpiryNotificationScheduler(
        inventory: ref.watch(inventoryRepositoryProvider),
        notifications: ref.watch(notificationServiceProvider),
      ),
    );

/// Emittiert bei jeder Aenderung an der Inventar-Tabelle (kontextuebergreifend).
final _inventoryChangesProvider = StreamProvider<void>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tableUpdates().where((set) {
    return set.any((u) => u.table == 'inventory_items');
  }).map((_) {});
});

/// Plant die taegliche Ablauf-Sammelbenachrichtigung neu, sobald sich das
/// Inventar oder die Einstellung aendert. Muss beobachtet werden (AppShell).
final expiryNotificationSyncProvider = Provider<void>((ref) {
  final settings = ref.watch(appSettingsProvider);
  ref.watch(_inventoryChangesProvider);
  ref.watch(expiryNotificationSchedulerProvider).reschedule(
    enabled: settings.expiryWarningsEnabled,
    warningDays: settings.expiryWarningDays,
  );
});

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  final service = OpenFoodFactsService();
  ref.onDispose(service.dispose);
  return service;
});

final productImageCacheProvider = Provider<ProductImageCache>((ref) {
  final cache = ProductImageCache();
  ref.onDispose(cache.dispose);
  return cache;
});

/// Lokale Bilddatei zu einer Produkt-URL (laedt bei Bedarf, `null` = kein Bild).
final productImageProvider = FutureProvider.family<File?, String>(
  (ref, url) => ref.watch(productImageCacheProvider).resolve(url),
);

/// Chargen-Zusammenfassung je Artikel im aktiven Kontext (fuer die Anzeige
/// "N Chargen" in der Liste).
final batchAggregatesProvider =
    StreamProvider<Map<String, BatchAggregate>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  return ref.watch(inventoryRepositoryProvider).watchBatchAggregates(scope);
});

/// Chargen eines einzelnen Artikels (fuer den Editor).
final itemBatchesProvider = StreamProvider.family<List<InventoryBatch>, String>(
  (ref, itemId) => ref.watch(inventoryRepositoryProvider).watchBatches(itemId),
);

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
