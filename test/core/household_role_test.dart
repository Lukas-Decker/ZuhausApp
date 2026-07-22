import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/household/household_role.dart';

void main() {
  group('HouseholdRole', () {
    test('Owner zieht am meisten', () {
      expect(HouseholdRole.owner.rank, greaterThan(HouseholdRole.admin.rank));
      expect(HouseholdRole.admin.rank, greaterThan(HouseholdRole.member.rank));
      expect(HouseholdRole.member.rank, greaterThan(HouseholdRole.guest.rank));
    });

    test('nur der Owner darf auflösen und übergeben', () {
      expect(HouseholdRole.owner.canDeleteHousehold, isTrue);
      expect(HouseholdRole.owner.canTransferOwnership, isTrue);
      for (final role in HouseholdRole.values.where(
        (r) => r != HouseholdRole.owner,
      )) {
        expect(role.canDeleteHousehold, isFalse, reason: role.name);
        expect(role.canTransferOwnership, isFalse, reason: role.name);
      }
    });

    test('Admin darf keine Admins oder Owner ernennen', () {
      expect(HouseholdRole.admin.canAssign(HouseholdRole.member), isTrue);
      expect(HouseholdRole.admin.canAssign(HouseholdRole.guest), isTrue);
      expect(HouseholdRole.admin.canAssign(HouseholdRole.admin), isFalse);
      expect(HouseholdRole.admin.canAssign(HouseholdRole.owner), isFalse);
    });

    test('Owner darf jede Rolle vergeben', () {
      for (final role in HouseholdRole.values) {
        expect(HouseholdRole.owner.canAssign(role), isTrue, reason: role.name);
      }
    });

    test('Mitglied und Gast dürfen niemanden verwalten', () {
      expect(HouseholdRole.member.canManageMembers, isFalse);
      expect(HouseholdRole.guest.canManageMembers, isFalse);
      expect(HouseholdRole.guest.canEditSharedContent, isFalse);
      expect(HouseholdRole.member.canEditSharedContent, isTrue);
    });
  });
}
