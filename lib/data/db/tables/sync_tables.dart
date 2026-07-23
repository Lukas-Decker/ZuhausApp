import 'package:drift/drift.dart';

import 'common.dart';

/// Ausstehende Zaehler-Deltas fuer den additiven Sync.
///
/// Wenn ein Zaehler (z.B. Vorratsmenge) lokal veraendert wird, landet das Delta
/// hier und wird beim naechsten Push serverseitig atomar addiert. So geht bei
/// gleichzeitiger Aenderung auf mehreren Geraeten nichts verloren.
class SyncOutbox extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();

  /// Tabellenname des betroffenen Datensatzes, z.B. 'inventory_items'.
  TextColumn get targetTable => text()();
  TextColumn get rowId => text()();

  /// Spalte des Zaehlers, z.B. 'quantity'.
  TextColumn get field => text()();
  RealColumn get delta => real()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Schluessel-Wert-Ablage fuer Sync-Metadaten (z.B. letzter Pull-Zeitpunkt).
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
