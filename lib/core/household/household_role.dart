import 'package:flutter/material.dart';

/// Rollen innerhalb eines Haushalts.
///
/// Der Ersteller ist [owner] und behaelt Sonderrechte, die kein [admin]
/// entziehen kann. [guest] ist die eingeschraenkte Kind-/Gastrolle.
enum HouseholdRole {
  owner,
  admin,
  member,
  guest;

  String get label => switch (this) {
    HouseholdRole.owner => 'Eigentuemer',
    HouseholdRole.admin => 'Admin',
    HouseholdRole.member => 'Mitglied',
    HouseholdRole.guest => 'Kind / Gast',
  };

  String get description => switch (this) {
    HouseholdRole.owner =>
      'Kann alles, inklusive Haushalt aufloesen und Eigentuemerschaft uebergeben.',
    HouseholdRole.admin =>
      'Kann einladen, Mitglieder verwalten und Einstellungen aendern.',
    HouseholdRole.member => 'Kann alle freigegebenen Inhalte lesen und bearbeiten.',
    HouseholdRole.guest =>
      'Sieht nur freigegebene Module, keine Gesundheitsdaten anderer.',
  };

  IconData get icon => switch (this) {
    HouseholdRole.owner => Icons.workspace_premium_rounded,
    HouseholdRole.admin => Icons.shield_rounded,
    HouseholdRole.member => Icons.person_rounded,
    HouseholdRole.guest => Icons.child_care_rounded,
  };

  /// Rangfolge, hoeher schlaegt niedriger. Der Owner zieht immer am meisten.
  int get rank => switch (this) {
    HouseholdRole.owner => 300,
    HouseholdRole.admin => 200,
    HouseholdRole.member => 100,
    HouseholdRole.guest => 10,
  };

  bool get canManageMembers => rank >= HouseholdRole.admin.rank;
  bool get canEditSharedContent => rank >= HouseholdRole.member.rank;
  bool get canDeleteHousehold => this == HouseholdRole.owner;
  bool get canTransferOwnership => this == HouseholdRole.owner;

  /// Darf diese Rolle eine andere Rolle vergeben oder entziehen?
  bool canAssign(HouseholdRole target) {
    if (this == HouseholdRole.owner) return true;
    if (this == HouseholdRole.admin) return target.rank < HouseholdRole.admin.rank;
    return false;
  }
}
