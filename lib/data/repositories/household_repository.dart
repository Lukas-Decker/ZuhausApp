import 'package:drift/drift.dart';

import '../../core/household/household_role.dart';
import '../db/app_database.dart';
import '../db/tables/common.dart';

/// Ein Haushalt zusammen mit der Rolle des aktuellen Nutzers darin.
class HouseholdWithRole {
  const HouseholdWithRole({required this.household, required this.role});

  final Household household;
  final HouseholdRole role;
}

class HouseholdRepository {
  HouseholdRepository(this._db);

  final AppDatabase _db;

  /// Alle Haushalte, in denen [userId] aktives Mitglied ist.
  Stream<List<HouseholdWithRole>> watchForUser(String userId) {
    final query = _db.select(_db.households).join([
      innerJoin(
        _db.householdMembers,
        _db.householdMembers.householdId.equalsExp(_db.households.id),
      ),
    ])
      ..where(
        _db.householdMembers.userId.equals(userId) &
            _db.householdMembers.deletedAt.isNull() &
            _db.households.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm.asc(_db.households.name)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final member = row.readTable(_db.householdMembers);
        return HouseholdWithRole(
          household: row.readTable(_db.households),
          role: _parseRole(member.role),
        );
      }).toList(),
    );
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return (_db.select(_db.householdMembers)
          ..where((m) => m.householdId.equals(householdId))
          ..where((m) => m.deletedAt.isNull()))
        .watch();
  }

  /// Legt einen Haushalt an und macht [userId] zum Eigentümer.
  Future<Household> create({
    required String name,
    required String userId,
    required String displayName,
  }) async {
    final id = uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.households).insert(
        HouseholdsCompanion.insert(
          id: Value(id),
          name: name,
          ownerUserId: userId,
          inviteCode: Value(_generateInviteCode()),
        ),
      );
      await _db.into(_db.householdMembers).insert(
        HouseholdMembersCompanion.insert(
          householdId: id,
          userId: userId,
          displayName: displayName,
          role: HouseholdRole.owner.name,
        ),
      );
    });
    return (_db.select(_db.households)..where((h) => h.id.equals(id)))
        .getSingle();
  }

  Future<void> rename(String householdId, String name) async {
    await (_db.update(_db.households)..where((h) => h.id.equals(householdId)))
        .write(
      HouseholdsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
        isDirty: const Value(true),
      ),
    );
  }

  /// Soft-Delete, damit die Sync-Engine das Löschen weitergeben kann.
  Future<void> softDelete(String householdId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.households)..where((h) => h.id.equals(householdId)))
          .write(
        HouseholdsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(_db.householdMembers)
            ..where((m) => m.householdId.equals(householdId)))
          .write(
        HouseholdMembersCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
    });
  }

  /// Ersetzt den lokalen Haushalts-Cache durch den Server-Stand.
  ///
  /// Die Haushalts- und Mitgliederliste gehoert ab v0.8 dem Server; lokal ist
  /// sie nur ein Spiegel fuer Anzeige und Offline-Umschalten. Deshalb wird der
  /// Cache atomar komplett neu geschrieben.
  Future<void> mirror({
    required List<({String id, String name, String ownerUserId})> households,
    required List<
      ({String householdId, String userId, String displayName, String role})
    >
    members,
  }) async {
    await _db.transaction(() async {
      await _db.delete(_db.householdMembers).go();
      await _db.delete(_db.households).go();

      for (final h in households) {
        await _db.into(_db.households).insert(
          HouseholdsCompanion.insert(
            id: Value(h.id),
            name: h.name,
            ownerUserId: h.ownerUserId,
            isDirty: const Value(false),
          ),
        );
      }
      for (final m in members) {
        await _db.into(_db.householdMembers).insert(
          HouseholdMembersCompanion.insert(
            householdId: m.householdId,
            userId: m.userId,
            displayName: m.displayName,
            role: m.role,
            isDirty: const Value(false),
          ),
        );
      }
    });
  }

  /// Leert den lokalen Cache (z.B. beim Abmelden).
  Future<void> clearCache() async {
    await _db.transaction(() async {
      await _db.delete(_db.householdMembers).go();
      await _db.delete(_db.households).go();
    });
  }

  static HouseholdRole _parseRole(String value) => HouseholdRole.values
      .firstWhere((r) => r.name == value, orElse: () => HouseholdRole.member);

  static String _generateInviteCode() {
    // Ohne O/0/I/1, damit Codes vorlesbar bleiben.
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final raw = uuid.v4().replaceAll('-', '');
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      final chunk = int.parse(raw.substring(i * 2, i * 2 + 2), radix: 16);
      buffer.write(alphabet[chunk % alphabet.length]);
    }
    return buffer.toString();
  }
}
