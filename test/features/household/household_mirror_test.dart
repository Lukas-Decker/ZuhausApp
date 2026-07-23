import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/household/household_role.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/household_repository.dart';
import 'package:multiapp/features/household/domain/household_models.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late HouseholdRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = HouseholdRepository(db);
  });

  tearDown(() => db.close());

  test('mirror spiegelt Haushalte und Mitglieder in den Cache', () async {
    await repo.mirror(
      households: [(id: 'h1', name: 'Familie', ownerUserId: 'u1')],
      members: [
        (householdId: 'h1', userId: 'u1', displayName: 'Lukas', role: 'owner'),
        (householdId: 'h1', userId: 'u2', displayName: 'Anna', role: 'member'),
      ],
    );

    final forU1 = await repo.watchForUser('u1').first;
    expect(forU1, hasLength(1));
    expect(forU1.single.household.name, 'Familie');
    expect(forU1.single.role, HouseholdRole.owner);

    final members = await repo.watchMembers('h1').first;
    expect(members, hasLength(2));
  });

  test('mirror ersetzt den vorherigen Stand vollstaendig', () async {
    await repo.mirror(
      households: [(id: 'h1', name: 'Alt', ownerUserId: 'u1')],
      members: [
        (householdId: 'h1', userId: 'u1', displayName: 'Lukas', role: 'owner'),
      ],
    );
    // Zweiter Spiegel ohne h1: der Nutzer wurde entfernt/hat verlassen.
    await repo.mirror(
      households: [(id: 'h2', name: 'Neu', ownerUserId: 'u1')],
      members: [
        (householdId: 'h2', userId: 'u1', displayName: 'Lukas', role: 'admin'),
      ],
    );

    final list = await repo.watchForUser('u1').first;
    expect(list, hasLength(1));
    expect(list.single.household.id, 'h2');
    expect(list.single.role, HouseholdRole.admin);
    expect(await repo.watchMembers('h1').first, isEmpty);
  });

  test('clearCache leert den Cache (z.B. beim Abmelden)', () async {
    await repo.mirror(
      households: [(id: 'h1', name: 'Familie', ownerUserId: 'u1')],
      members: [
        (householdId: 'h1', userId: 'u1', displayName: 'Lukas', role: 'owner'),
      ],
    );
    await repo.clearCache();
    expect(await repo.watchForUser('u1').first, isEmpty);
  });

  group('RemoteInvite', () {
    test('prettyCode gruppiert achtstellige Codes', () {
      final invite = RemoteInvite.fromJson({
        'id': 'i1',
        'code': 'ABCD2345',
        'role': 'member',
        'uses': 0,
        'max_uses': null,
        'expires_at': null,
      });
      expect(invite.prettyCode, 'ABCD-2345');
      expect(invite.role, HouseholdRole.member);
    });

    test('parst Rolle und Nutzung', () {
      final invite = RemoteInvite.fromJson({
        'id': 'i1',
        'code': 'WXYZ7788',
        'role': 'guest',
        'uses': 2,
        'max_uses': 5,
        'expires_at': '2026-08-01T00:00:00Z',
      });
      expect(invite.role, HouseholdRole.guest);
      expect(invite.uses, 2);
      expect(invite.maxUses, 5);
      expect(invite.expiresAt, isNotNull);
    });
  });
}
