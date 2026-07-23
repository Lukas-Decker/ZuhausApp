import '../../../core/household/household_role.dart';

/// Ein Mitglied eines Haushalts, wie es vom Server kommt.
class RemoteMember {
  const RemoteMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String displayName;
  final HouseholdRole role;
  final DateTime joinedAt;

  factory RemoteMember.fromJson(Map<String, dynamic> json) => RemoteMember(
    userId: json['user_id'] as String,
    displayName: (json['display_name'] as String?) ?? '',
    role: _parseRole(json['role'] as String?),
    joinedAt:
        DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Ein Haushalt samt der Rolle des aktuellen Nutzers darin.
class RemoteHousehold {
  const RemoteHousehold({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.myRole,
  });

  final String id;
  final String name;
  final String ownerUserId;
  final HouseholdRole myRole;
}

/// Eine aktive Einladung.
class RemoteInvite {
  const RemoteInvite({
    required this.id,
    required this.code,
    required this.role,
    required this.uses,
    this.maxUses,
    this.expiresAt,
  });

  final String id;
  final String code;
  final HouseholdRole role;
  final int uses;
  final int? maxUses;
  final DateTime? expiresAt;

  factory RemoteInvite.fromJson(Map<String, dynamic> json) => RemoteInvite(
    id: json['id'] as String,
    code: json['code'] as String,
    role: _parseRole(json['role'] as String?),
    uses: (json['uses'] as int?) ?? 0,
    maxUses: json['max_uses'] as int?,
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.tryParse(json['expires_at'] as String),
  );

  /// Formatiert den Code lesbar in zwei Gruppen, z.B. "ABCD-2345".
  String get prettyCode =>
      code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
}

HouseholdRole _parseRole(String? value) => HouseholdRole.values.firstWhere(
  (r) => r.name == value,
  orElse: () => HouseholdRole.member,
);
