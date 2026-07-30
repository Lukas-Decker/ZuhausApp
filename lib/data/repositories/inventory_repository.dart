import 'package:drift/drift.dart';

import '../../core/scope/app_scope.dart';
import '../../features/inventory/domain/storage_icons.dart';
import '../db/app_database.dart';
import '../db/tables/common.dart';

/// Ein Vorrat samt seinem Lagerort, so wie ihn die Liste braucht.
class InventoryEntry {
  const InventoryEntry({
    required this.item,
    this.location,
    this.imageUrl,
    this.batchCount = 0,
  });

  final InventoryItem item;
  final StorageLocation? location;

  /// Bild-URL des verknuepften Produkts (aus Open Food Facts), falls vorhanden.
  final String? imageUrl;

  /// Anzahl Chargen mit eigenem MHD. 0 = einfacher Vorrat wie bisher.
  final int batchCount;

  bool get hasBatches => batchCount > 0;

  /// Vorrat unter dem gesetzten Mindestbestand.
  bool get isLow {
    final min = item.minQuantity;
    return min != null && item.quantity <= min;
  }

  /// Tage bis zum Ablauf, negativ wenn bereits abgelaufen.
  int? get daysUntilExpiry {
    final expiry = item.expiresAt;
    if (expiry == null) return null;
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(expiry.year, expiry.month, expiry.day);
    return b.difference(a).inDays;
  }

  bool get isExpired => (daysUntilExpiry ?? 1) < 0;

  bool expiresWithin(int days) {
    final left = daysUntilExpiry;
    return left != null && left >= 0 && left <= days;
  }
}

/// Zusammenfassung der Chargen eines Artikels (Gesamtmenge, fruehestes MHD).
class BatchAggregate {
  const BatchAggregate({
    required this.total,
    this.earliest,
    required this.count,
  });

  final double total;
  final DateTime? earliest;
  final int count;
}

enum InventoryFilter {
  all('Alle'),
  low('Knapp'),
  expiring('Läuft ab');

  const InventoryFilter(this.label);

  final String label;
}

class InventoryRepository {
  InventoryRepository(this._db);

  /// Vorwarnzeit für "läuft bald ab".
  static const int expiryWarningDays = 5;

  final AppDatabase _db;

  // --- Lagerorte -----------------------------------------------------------

  Stream<List<StorageLocation>> watchLocations(AppScope scope) {
    return (_db.select(_db.storageLocations)
          ..where((l) => l.scopeKind.equals(scope.kind.name))
          ..where((l) => l.scopeId.equals(scope.id))
          ..where((l) => l.deletedAt.isNull())
          ..orderBy([
            (l) => OrderingTerm.asc(l.sortOrder),
            (l) => OrderingTerm.asc(l.name),
          ]))
        .watch();
  }

  /// Legt beim ersten Öffnen eines Kontexts die Standard-Lagerorte an.
  Future<void> ensureDefaultLocations(AppScope scope, String userId) async {
    final existing = await (_db.select(_db.storageLocations)
          ..where((l) => l.scopeKind.equals(scope.kind.name))
          ..where((l) => l.scopeId.equals(scope.id))
          ..limit(1))
        .get();
    if (existing.isNotEmpty) return;

    await _db.batch((batch) {
      for (var i = 0; i < defaultStorageLocations.length; i++) {
        final preset = defaultStorageLocations[i];
        batch.insert(
          _db.storageLocations,
          StorageLocationsCompanion.insert(
            scopeKind: scope.kind.name,
            scopeId: scope.id,
            name: preset.name,
            iconKey: Value(preset.iconKey),
            sortOrder: Value(i),
            createdBy: Value(userId),
            updatedBy: Value(userId),
          ),
        );
      }
    });
  }

  Future<String> createLocation({
    required AppScope scope,
    required String userId,
    required String name,
    required String iconKey,
  }) async {
    final id = uuid.v4();
    await _db.into(_db.storageLocations).insert(
      StorageLocationsCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        name: name,
        iconKey: Value(iconKey),
        sortOrder: const Value(100),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
    return id;
  }

  Future<void> updateLocation({
    required String id,
    required String userId,
    String? name,
    String? iconKey,
  }) async {
    await (_db.update(_db.storageLocations)..where((l) => l.id.equals(id)))
        .write(
      StorageLocationsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  /// Löscht den Ort weich; die Artikel darin bleiben erhalten und rutschen
  /// in die Gruppe "Ohne Ort".
  Future<void> deleteLocation(String id, String userId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.storageLocations)..where((l) => l.id.equals(id)))
          .write(
        StorageLocationsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(_db.inventoryItems)
            ..where((i) => i.locationId.equals(id)))
          .write(
        InventoryItemsCompanion(
          locationId: const Value(null),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
    });
  }

  // --- Vorräte -------------------------------------------------------------

  Stream<List<InventoryEntry>> watchItems(
    AppScope scope, {
    String search = '',
    InventoryFilter filter = InventoryFilter.all,
  }) {
    final query = _db.select(_db.inventoryItems).join([
      leftOuterJoin(
        _db.storageLocations,
        _db.storageLocations.id.equalsExp(_db.inventoryItems.locationId),
      ),
      leftOuterJoin(
        _db.products,
        _db.products.id.equalsExp(_db.inventoryItems.productId),
      ),
    ])
      ..where(
        _db.inventoryItems.scopeKind.equals(scope.kind.name) &
            _db.inventoryItems.scopeId.equals(scope.id) &
            _db.inventoryItems.deletedAt.isNull(),
      )
      ..orderBy([
        OrderingTerm.asc(_db.storageLocations.sortOrder),
        OrderingTerm.asc(_db.inventoryItems.name),
      ]);

    final term = search.trim().toLowerCase();

    return query.watch().map((rows) {
      final entries = rows.map((row) {
        return InventoryEntry(
          item: row.readTable(_db.inventoryItems),
          location: row.readTableOrNull(_db.storageLocations),
          imageUrl: row.readTableOrNull(_db.products)?.imageUrl,
        );
      });

      return entries.where((entry) {
        if (term.isNotEmpty &&
            !entry.item.name.toLowerCase().contains(term) &&
            !(entry.item.barcode ?? '').contains(term)) {
          return false;
        }
        return switch (filter) {
          InventoryFilter.all => true,
          InventoryFilter.low => entry.isLow,
          InventoryFilter.expiring =>
            entry.isExpired || entry.expiresWithin(expiryWarningDays),
        };
      }).toList();
    });
  }

  Future<InventoryItem?> findById(String id) {
    return (_db.select(_db.inventoryItems)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
  }

  /// Alle bald ablaufenden Vorraete ueber alle Kontexte, fuer die taegliche
  /// Sammelbenachrichtigung. Beruecksichtigt den Pro-Artikel-Schalter.
  Future<List<InventoryItem>> expiringSoon(int withinDays) {
    final today = DateTime.now();
    final horizon = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: withinDays + 1));
    return (_db.select(_db.inventoryItems)
          ..where((i) => i.deletedAt.isNull())
          ..where((i) => i.remindOnExpiry.equals(true))
          ..where((i) => i.expiresAt.isNotNull())
          ..where((i) => i.expiresAt.isSmallerThanValue(horizon))
          ..orderBy([(i) => OrderingTerm.asc(i.expiresAt)]))
        .get();
  }

  Future<InventoryItem?> findByBarcode(AppScope scope, String barcode) {
    return (_db.select(_db.inventoryItems)
          ..where((i) => i.scopeKind.equals(scope.kind.name))
          ..where((i) => i.scopeId.equals(scope.id))
          ..where((i) => i.barcode.equals(barcode))
          ..where((i) => i.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  /// Sucht einen vorhandenen Vorrat, zuerst über den Barcode, sonst über den
  /// Namen. Basis dafür, dass ein eingekaufter Posten den Bestand erhöht,
  /// statt einen zweiten Eintrag anzulegen.
  Future<InventoryItem?> findMatching(
    AppScope scope, {
    String? barcode,
    required String name,
  }) async {
    if (barcode != null && barcode.isNotEmpty) {
      final byBarcode = await findByBarcode(scope, barcode);
      if (byBarcode != null) return byBarcode;
    }
    return (_db.select(_db.inventoryItems)
          ..where((i) => i.scopeKind.equals(scope.kind.name))
          ..where((i) => i.scopeId.equals(scope.id))
          ..where((i) => i.name.lower().equals(name.trim().toLowerCase()))
          ..where((i) => i.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  Future<String> addItem({
    required AppScope scope,
    required String userId,
    required String name,
    required double quantity,
    required String unit,
    String? barcode,
    String? productId,
    String? locationId,
    DateTime? expiresAt,
    double? minQuantity,
    String? note,
    bool remindOnExpiry = true,
  }) async {
    final id = uuid.v4();
    await _db.into(_db.inventoryItems).insert(
      InventoryItemsCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        name: name,
        barcode: Value(barcode),
        productId: Value(productId),
        locationId: Value(locationId),
        quantity: Value(quantity),
        unit: Value(unit),
        expiresAt: Value(expiresAt),
        minQuantity: Value(minQuantity),
        note: Value(note),
        remindOnExpiry: Value(remindOnExpiry),
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
    Value<String?> locationId = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<double?> minQuantity = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? remindOnExpiry,
  }) async {
    await _db.transaction(() async {
      // Menge ist ein additiver Zaehler: eine absolute Aenderung aus dem
      // Formular wird als Delta (neu - alt) verbucht.
      if (quantity != null) {
        final current = await (_db.select(_db.inventoryItems)
              ..where((i) => i.id.equals(id)))
            .getSingleOrNull();
        if (current != null && current.quantity != quantity) {
          await _db.logCounterDelta(
            table: 'inventory_items',
            rowId: id,
            field: 'quantity',
            delta: quantity - current.quantity,
          );
        }
      }
      await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id)))
          .write(
        InventoryItemsCompanion(
          name: name == null ? const Value.absent() : Value(name),
          quantity: quantity == null ? const Value.absent() : Value(quantity),
          unit: unit == null ? const Value.absent() : Value(unit),
          locationId: locationId,
          expiresAt: expiresAt,
          minQuantity: minQuantity,
          note: note,
          remindOnExpiry: remindOnExpiry == null
              ? const Value.absent()
              : Value(remindOnExpiry),
          updatedAt: Value(DateTime.now()),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
    });
  }

  /// Verändert den Bestand relativ.
  ///
  /// Bewusst additiv statt absolut: bei gleichzeitigen Änderungen auf zwei
  /// Geräten soll sich der Verbrauch summieren und nicht überschrieben werden.
  /// Gibt die neue Menge zurück.
  Future<double> adjustQuantity({
    required String id,
    required String userId,
    required double delta,
  }) async {
    return _db.transaction(() async {
      final item = await (_db.select(_db.inventoryItems)
            ..where((i) => i.id.equals(id)))
          .getSingle();
      final next = (item.quantity + delta).clamp(0.0, double.maxFinite);
      final applied = next - item.quantity;
      await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id)))
          .write(
        InventoryItemsCompanion(
          quantity: Value(next),
          updatedAt: Value(DateTime.now()),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      // Additiv synchronisieren, damit gleichzeitiger Verbrauch nicht verloren
      // geht.
      await _db.logCounterDelta(
        table: 'inventory_items',
        rowId: id,
        field: 'quantity',
        delta: applied,
      );
      return next;
    });
  }

  Future<void> deleteItem(String id, String userId) async {
    final now = DateTime.now();
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id))).write(
      InventoryItemsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  // --- Chargen (MHD) -------------------------------------------------------

  /// Chargen eines Artikels, zuerst ablaufende oben.
  Stream<List<InventoryBatch>> watchBatches(String itemId) {
    return (_db.select(_db.inventoryBatches)
          ..where((b) => b.itemId.equals(itemId) & b.deletedAt.isNull())
          ..orderBy([
            (b) => OrderingTerm.asc(b.expiresAt),
            (b) => OrderingTerm.asc(b.createdAt),
          ]))
        .watch();
  }

  /// Legt eine Charge an. Ihre Menge erhoeht additiv den Artikel-Gesamtbestand
  /// (datierter Zugang), und das fruehste MHD wird am Artikel zusammengefasst.
  Future<String> addBatch({
    required AppScope scope,
    required String userId,
    required String itemId,
    double quantity = 1,
    DateTime? expiresAt,
  }) async {
    final id = uuid.v4();
    await _db.transaction(() async {
      final now = DateTime.now();
      await _db.into(_db.inventoryBatches).insert(
        InventoryBatchesCompanion.insert(
          id: Value(id),
          scopeKind: scope.kind.name,
          scopeId: scope.id,
          itemId: itemId,
          quantity: Value(quantity),
          expiresAt: Value(expiresAt),
          createdAt: Value(now),
          updatedAt: Value(now),
          createdBy: Value(userId),
          updatedBy: Value(userId),
        ),
      );
      await _mirrorToItem(itemId, userId, quantity);
      await _recomputeItemExpiry(itemId, userId);
    });
    return id;
  }

  /// Verändert die Menge einer Charge additiv und spiegelt die Änderung auf den
  /// Artikel-Gesamtbestand. Gibt die neue Chargenmenge zurück.
  Future<double> adjustBatchQuantity({
    required String id,
    required String userId,
    required double delta,
  }) async {
    return _db.transaction(() async {
      final batch = await (_db.select(_db.inventoryBatches)
            ..where((b) => b.id.equals(id)))
          .getSingle();
      final next = (batch.quantity + delta).clamp(0.0, double.maxFinite);
      final applied = next - batch.quantity;
      await (_db.update(_db.inventoryBatches)..where((b) => b.id.equals(id)))
          .write(
        InventoryBatchesCompanion(
          quantity: Value(next),
          updatedAt: Value(DateTime.now()),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      await _db.logCounterDelta(
        table: 'inventory_batches',
        rowId: id,
        field: 'quantity',
        delta: applied,
      );
      await _mirrorToItem(batch.itemId, userId, applied);
      await _recomputeItemExpiry(batch.itemId, userId);
      return next;
    });
  }

  /// Entfernt eine Charge und zieht ihre Restmenge vom Artikel ab.
  Future<void> deleteBatch(String id, String userId) async {
    await _db.transaction(() async {
      final batch = await (_db.select(_db.inventoryBatches)
            ..where((b) => b.id.equals(id)))
          .getSingleOrNull();
      if (batch == null || batch.deletedAt != null) return;
      final now = DateTime.now();
      await (_db.update(_db.inventoryBatches)..where((b) => b.id.equals(id)))
          .write(
        InventoryBatchesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      await _mirrorToItem(batch.itemId, userId, -batch.quantity);
      await _recomputeItemExpiry(batch.itemId, userId);
    });
  }

  /// Verbraucht [amount] Einheiten aus den zuerst ablaufenden Chargen (FIFO).
  /// Der Artikel-Gesamtbestand sinkt ueber die Spiegelung mit; leergewordene
  /// Chargen werden entfernt.
  Future<void> consumeEarliest({
    required String itemId,
    required String userId,
    double amount = 1,
  }) async {
    var remaining = amount;
    final batches = await (_db.select(_db.inventoryBatches)
          ..where((b) =>
              b.itemId.equals(itemId) &
              b.deletedAt.isNull() &
              b.quantity.isBiggerThanValue(0))
          ..orderBy([
            (b) => OrderingTerm.asc(b.expiresAt),
            (b) => OrderingTerm.asc(b.createdAt),
          ]))
        .get();
    for (final batch in batches) {
      if (remaining <= 0) break;
      final take = remaining < batch.quantity ? remaining : batch.quantity;
      final next =
          await adjustBatchQuantity(id: batch.id, userId: userId, delta: -take);
      if (next <= 0) await deleteBatch(batch.id, userId);
      remaining -= take;
    }
  }

  /// Spiegelt eine Mengenaenderung additiv auf den Artikel-Gesamtbestand
  /// (innerhalb der aufrufenden Transaktion).
  Future<void> _mirrorToItem(String itemId, String userId, double delta) async {
    if (delta == 0) return;
    final item = await (_db.select(_db.inventoryItems)
          ..where((i) => i.id.equals(itemId)))
        .getSingleOrNull();
    if (item == null) return;
    final next = (item.quantity + delta).clamp(0.0, double.maxFinite);
    final applied = next - item.quantity;
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(itemId)))
        .write(
      InventoryItemsCompanion(
        quantity: Value(next),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
    await _db.logCounterDelta(
      table: 'inventory_items',
      rowId: itemId,
      field: 'quantity',
      delta: applied,
    );
  }

  /// Schreibt das fruehste Chargen-MHD als Zusammenfassung ans Artikel-MHD,
  /// damit Filter und Ablauf-Benachrichtigung Chargen ohne Umbau beruecksichtigen.
  Future<void> _recomputeItemExpiry(String itemId, String userId) async {
    final batches = await (_db.select(_db.inventoryBatches)
          ..where((b) =>
              b.itemId.equals(itemId) &
              b.deletedAt.isNull() &
              b.quantity.isBiggerThanValue(0)))
        .get();
    if (batches.isEmpty) return;
    DateTime? earliest;
    for (final b in batches) {
      earliest = _earlier(earliest, b.expiresAt);
    }
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(itemId)))
        .write(
      InventoryItemsCompanion(
        expiresAt: Value(earliest),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  /// Fasst je Artikel die Chargen zusammen: Gesamtmenge, fruehestes MHD, Anzahl.
  Stream<Map<String, BatchAggregate>> watchBatchAggregates(AppScope scope) {
    return (_db.select(_db.inventoryBatches)
          ..where((b) =>
              b.scopeKind.equals(scope.kind.name) &
              b.scopeId.equals(scope.id) &
              b.deletedAt.isNull() &
              b.quantity.isBiggerThanValue(0)))
        .watch()
        .map((batches) {
      final map = <String, BatchAggregate>{};
      for (final b in batches) {
        final prev = map[b.itemId];
        map[b.itemId] = BatchAggregate(
          total: (prev?.total ?? 0) + b.quantity,
          earliest: _earlier(prev?.earliest, b.expiresAt),
          count: (prev?.count ?? 0) + 1,
        );
      }
      return map;
    });
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  // --- Produkte ------------------------------------------------------------

  Future<Product?> findProduct(AppScope scope, String barcode) {
    return (_db.select(_db.products)
          ..where((p) => p.scopeKind.equals(scope.kind.name))
          ..where((p) => p.scopeId.equals(scope.id))
          ..where((p) => p.barcode.equals(barcode))
          ..where((p) => p.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  /// Legt ein Produkt an oder aktualisiert es anhand des Barcodes.
  Future<String> saveProduct({
    required AppScope scope,
    required String userId,
    required String name,
    String? barcode,
    String? brand,
    String? imageUrl,
    String? category,
    String unit = 'piece',
    double defaultQuantity = 1,
    String source = 'local',
  }) async {
    if (barcode != null) {
      final existing = await findProduct(scope, barcode);
      if (existing != null) {
        await (_db.update(_db.products)..where((p) => p.id.equals(existing.id)))
            .write(
          ProductsCompanion(
            name: Value(name),
            brand: Value(brand),
            imageUrl: Value(imageUrl),
            category: Value(category),
            defaultUnit: Value(unit),
            updatedAt: Value(DateTime.now()),
            updatedBy: Value(userId),
            isDirty: const Value(true),
          ),
        );
        return existing.id;
      }
    }

    final id = uuid.v4();
    await _db.into(_db.products).insert(
      ProductsCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        name: name,
        barcode: Value(barcode),
        brand: Value(brand),
        imageUrl: Value(imageUrl),
        category: Value(category),
        defaultUnit: Value(unit),
        defaultQuantity: Value(defaultQuantity),
        source: Value(source),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
    return id;
  }
}
