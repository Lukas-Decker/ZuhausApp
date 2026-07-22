import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Wer diese App auf diesem Gerät bedient.
///
/// Bis zur Anmeldung (v0.7) ist das eine rein lokale Identität. Beim späteren
/// Login wird [userId] auf die Konto-ID umgeschrieben, damit vorhandene lokale
/// Daten erhalten bleiben.
@immutable
class LocalIdentity {
  const LocalIdentity({
    required this.userId,
    required this.displayName,
    required this.isLinkedToAccount,
  });

  final String userId;
  final String displayName;

  /// True, sobald die Identität an ein Supabase-Konto gebunden ist.
  final bool isLinkedToAccount;

  LocalIdentity copyWith({
    String? userId,
    String? displayName,
    bool? isLinkedToAccount,
  }) => LocalIdentity(
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    isLinkedToAccount: isLinkedToAccount ?? this.isLinkedToAccount,
  );

  /// Initialen für Avatare, z.B. "LM" aus "Lukas Müller".
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters1();
    return '${parts.first.characters1()}${parts.last.characters1()}';
  }
}

extension on String {
  String characters1() => isEmpty ? '' : substring(0, 1).toUpperCase();
}

/// Lädt und speichert die lokale Identität in den SharedPreferences.
class LocalIdentityStore {
  LocalIdentityStore(this._prefs);

  static const _keyUserId = 'identity.userId';
  static const _keyDisplayName = 'identity.displayName';
  static const _keyLinked = 'identity.linked';

  final SharedPreferences _prefs;

  LocalIdentity loadOrCreate() {
    var userId = _prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) {
      userId = const Uuid().v4();
      _prefs.setString(_keyUserId, userId);
    }
    return LocalIdentity(
      userId: userId,
      displayName: _prefs.getString(_keyDisplayName) ?? 'Ich',
      isLinkedToAccount: _prefs.getBool(_keyLinked) ?? false,
    );
  }

  Future<void> save(LocalIdentity identity) async {
    await _prefs.setString(_keyUserId, identity.userId);
    await _prefs.setString(_keyDisplayName, identity.displayName);
    await _prefs.setBool(_keyLinked, identity.isLinkedToAccount);
  }
}
