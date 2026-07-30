import 'package:drift/drift.dart';

import 'common.dart';

/// Aufbewahrungsort, z.B. Kühlschrank oder Vorratskammer.
class StorageLocations extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Schlüssel aus [storageIcons], nicht der Icon-Codepoint selbst, damit die
  /// Zeile ohne Flutter-Abhängigkeit synchronisiert werden kann.
  TextColumn get iconKey => text().withDefault(const Constant('shelf'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Bekannte Produkte, gefüllt aus Open Food Facts oder von Hand.
///
/// Ein Produkt beschreibt, *was* etwas ist. Wie viel davon vorhanden ist,
/// steht in [InventoryItems].
class Products extends Table with SyncedRecord {
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get brand => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get defaultUnit => text().withDefault(const Constant('piece'))();
  RealColumn get defaultQuantity => real().withDefault(const Constant(1))();

  /// 'local' oder 'openfoodfacts'.
  TextColumn get source => text().withDefault(const Constant('local'))();
}

/// Eine datierte Teilmenge eines Vorrats: eine Menge mit eigenem MHD.
///
/// Damit kann ein Produkt mehrere Chargen mit unterschiedlichem
/// Mindesthaltbarkeitsdatum fuehren (z.B. drei Joghurts, zwei Daten). Vorraete
/// ohne Chargen verhalten sich unveraendert (eigene Menge + ein MHD am Artikel).
@DataClassName('InventoryBatch')
class InventoryBatches extends Table with SyncedRecord {
  TextColumn get itemId => text().references(InventoryItems, #id)();

  /// Additiver Zaehler wie die Artikelmenge (deltabasierter Sync).
  RealColumn get quantity => real().withDefault(const Constant(1))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
}

/// Ein konkreter Vorrat an einem Ort.
class InventoryItems extends Table with SyncedRecord {
  TextColumn get productId =>
      text().nullable().references(Products, #id)();
  TextColumn get locationId =>
      text().nullable().references(StorageLocations, #id)();

  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get barcode => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('piece'))();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Ab dieser Menge gilt der Vorrat als knapp.
  RealColumn get minQuantity => real().nullable()();

  TextColumn get note => text().nullable()();

  /// Erinnerung für genau diesen Artikel abschaltbar, unabhängig von der
  /// globalen Einstellung für Ablaufwarnungen.
  BoolColumn get remindOnExpiry => boolean().withDefault(const Constant(true))();
}
