import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Spalten, die jede synchronisierte Tabelle braucht.
///
/// Die Sync-Engine (ab v0.9) arbeitet mit Last-Write-Wins ueber [updatedAt]
/// und Soft-Deletes ueber [deletedAt]. Deshalb wird nie physisch geloescht,
/// solange ein Datensatz noch nicht durchsynchronisiert ist.
mixin SyncedRecord on Table {
  TextColumn get id => text().clientDefault(uuid.v4)();

  /// 'personal' oder 'household'.
  TextColumn get scopeKind => text().withLength(min: 1, max: 16)();

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  TextColumn get scopeId => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();

  /// Wurde lokal geaendert und noch nicht zum Server geschickt.
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
