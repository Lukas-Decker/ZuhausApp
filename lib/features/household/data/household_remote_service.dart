import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/household/household_role.dart';
import '../domain/household_models.dart';

/// Fehler einer Haushalts-Aktion mit lesbarer Meldung.
class HouseholdException implements Exception {
  const HouseholdException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Spricht direkt mit Supabase: Haushalte, Mitglieder, Einladungen.
///
/// Alle Mutationen laufen ueber SECURITY-DEFINER-RPCs (siehe SQL-Migration),
/// die die Rollenlogik serverseitig durchsetzen. Der Client liest nur, was RLS
/// erlaubt.
class HouseholdRemoteService {
  HouseholdRemoteService(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  // --- Lesen ---------------------------------------------------------------

  /// Meine Haushalte samt meiner Rolle darin.
  Future<List<RemoteHousehold>> fetchMyHouseholds() async {
    final uid = _uid;
    if (uid == null) return const [];

    final rows = await _client
        .from('household_members')
        .select('role, households(id, name, owner_user_id)')
        .eq('user_id', uid);

    final result = <RemoteHousehold>[];
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final h = map['households'] as Map<String, dynamic>?;
      if (h == null) continue;
      result.add(
        RemoteHousehold(
          id: h['id'] as String,
          name: h['name'] as String,
          ownerUserId: h['owner_user_id'] as String,
          myRole: HouseholdRole.values.firstWhere(
            (r) => r.name == map['role'],
            orElse: () => HouseholdRole.member,
          ),
        ),
      );
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// Alle Mitglieder der angegebenen Haushalte (fuer den lokalen Cache).
  Future<List<({String householdId, RemoteMember member})>> fetchMembers(
    List<String> householdIds,
  ) async {
    if (householdIds.isEmpty) return const [];
    final rows = await _client
        .from('household_members')
        .select()
        .inFilter('household_id', householdIds);

    return [
      for (final row in rows as List)
        (
          householdId: (row as Map<String, dynamic>)['household_id'] as String,
          member: RemoteMember.fromJson(row),
        ),
    ];
  }

  Future<List<RemoteInvite>> fetchInvites(String householdId) async {
    final rows = await _client
        .from('household_invites')
        .select()
        .eq('household_id', householdId)
        .eq('active', true)
        .order('created_at');
    return [
      for (final row in rows as List)
        RemoteInvite.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Realtime-Kanal, der bei jeder Aenderung an Mitgliedschaften/Haushalten
  /// [onChange] aufruft. Der Aufrufer laedt daraufhin neu.
  RealtimeChannel subscribe(void Function() onChange) {
    return _client
        .channel('household-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'household_members',
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'households',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  // --- Mutationen (RPC) ----------------------------------------------------

  Future<String> createHousehold(String name, String displayName) {
    return _rpc<String>('create_household', {
      '_name': name,
      '_display_name': displayName,
    });
  }

  Future<void> renameHousehold(String householdId, String name) {
    return _rpc<void>('rename_household', {
      '_household': householdId,
      '_name': name,
    });
  }

  Future<String> createInvite({
    required String householdId,
    required HouseholdRole role,
    DateTime? expiresAt,
    int? maxUses,
  }) {
    return _rpc<String>('create_invite', {
      '_household': householdId,
      '_role': role.name,
      '_expires_at': expiresAt?.toUtc().toIso8601String(),
      '_max_uses': maxUses,
    });
  }

  Future<void> revokeInvite(String inviteId) {
    return _rpc<void>('revoke_invite', {'_invite': inviteId});
  }

  Future<String> joinWithCode(String code, String displayName) {
    return _rpc<String>('join_with_code', {
      '_code': code.replaceAll('-', '').trim(),
      '_display_name': displayName,
    });
  }

  Future<void> setMemberRole(
    String householdId,
    String userId,
    HouseholdRole role,
  ) {
    return _rpc<void>('set_member_role', {
      '_household': householdId,
      '_user': userId,
      '_role': role.name,
    });
  }

  Future<void> removeMember(String householdId, String userId) {
    return _rpc<void>('remove_member', {
      '_household': householdId,
      '_user': userId,
    });
  }

  Future<void> leaveHousehold(String householdId) {
    return _rpc<void>('leave_household', {'_household': householdId});
  }

  Future<void> transferOwnership(String householdId, String newOwnerId) {
    return _rpc<void>('transfer_ownership', {
      '_household': householdId,
      '_new_owner': newOwnerId,
    });
  }

  Future<void> deleteHousehold(String householdId) {
    return _rpc<void>('delete_household', {'_household': householdId});
  }

  Future<T> _rpc<T>(String name, Map<String, dynamic> params) async {
    try {
      final result = await _client.rpc(name, params: params);
      return result as T;
    } on PostgrestException catch (error) {
      throw HouseholdException(_translate(error.message));
    } catch (error) {
      throw HouseholdException('Unerwarteter Fehler: $error');
    }
  }

  static String _translate(String raw) {
    // Unsere RPCs werfen bereits deutsche Klartext-Meldungen; die reichen wir
    // durch. Postgres haengt teils Praefixe an, die wir entfernen.
    final cleaned = raw.replaceFirst(RegExp(r'^.*:\s*'), '');
    return cleaned.isEmpty ? raw : cleaned;
  }
}
