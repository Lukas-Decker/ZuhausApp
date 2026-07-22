import 'package:drift/drift.dart';

import 'common.dart';

/// Ein Haushalt / eine Familie.
class Households extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get ownerUserId => text()();

  /// Kurzcode zum Beitreten, wird ab v0.8 serverseitig vergeben.
  TextColumn get inviteCode => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mitgliedschaft einer Person in einem Haushalt.
class HouseholdMembers extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get householdId => text().references(Households, #id)();
  TextColumn get userId => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 80)();

  /// Name der [HouseholdRole].
  TextColumn get role => text().withLength(min: 1, max: 16)();

  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Protokoll relevanter Änderungen, Grundlage für die Audit-Ansicht (v1.0).
class AuditEntries extends Table with SyncedRecord {
  /// z.B. 'inventory_item', 'med_plan'.
  TextColumn get entityType => text().withLength(min: 1, max: 40)();
  TextColumn get entityId => text()();

  /// 'create', 'update', 'delete'.
  TextColumn get action => text().withLength(min: 1, max: 16)();

  /// Menschenlesbare Zusammenfassung, z.B. "Milch von 2 auf 1 reduziert".
  TextColumn get summary => text()();
  TextColumn get actorName => text().nullable()();
}
