import 'package:drift/drift.dart';

import 'common.dart';
import 'inventory_tables.dart';

/// Eine Einkaufsliste. Pro Kontext gibt es mindestens eine.
class ShoppingLists extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Ein Posten auf einer Einkaufsliste.
class ShoppingItems extends Table with SyncedRecord {
  TextColumn get listId => text().references(ShoppingLists, #id)();

  TextColumn get name => text().withLength(min: 1, max: 160)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('piece'))();

  /// Name der [ShoppingCategory], für die Gruppierung im Laden.
  TextColumn get category => text().withDefault(const Constant('other'))();

  TextColumn get note => text().nullable()();

  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get checkedAt => dateTime().nullable()();
  TextColumn get checkedBy => text().nullable()();

  /// Gesetzt, wenn der Posten aus einem knappen Vorrat entstanden ist.
  /// Beim Übernehmen wird dann der Bestand erhöht statt ein neuer Artikel
  /// angelegt.
  TextColumn get inventoryItemId =>
      text().nullable().references(InventoryItems, #id)();

  TextColumn get barcode => text().nullable()();
}
