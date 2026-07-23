import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/repositories/household_repository.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/data/auth_service.dart';
import 'identity/local_identity.dart';
import 'scope/app_scope.dart';

/// Wird in `main()` mit der echten Instanz überschrieben.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences nicht initialisiert'),
);

/// Wird in `main()` mit der echten Instanz überschrieben.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('AppDatabase nicht initialisiert'),
);

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => HouseholdRepository(ref.watch(databaseProvider)),
);

final localIdentityStoreProvider = Provider<LocalIdentityStore>(
  (ref) => LocalIdentityStore(ref.watch(sharedPreferencesProvider)),
);

class IdentityController extends Notifier<LocalIdentity> {
  @override
  LocalIdentity build() {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      // Angemeldet: Identitaet kommt vom Konto.
      return LocalIdentity(
        userId: user.id,
        displayName: displayNameFor(user),
        isLinkedToAccount: true,
      );
    }
    // Gastmodus: lokale Identitaet.
    return ref.watch(localIdentityStoreProvider).loadOrCreate();
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.isLinkedToAccount) {
      await ref.read(authServiceProvider).updateDisplayName(trimmed);
      state = state.copyWith(displayName: trimmed);
    } else {
      final next = state.copyWith(displayName: trimmed);
      await ref.read(localIdentityStoreProvider).save(next);
      state = next;
    }
  }
}

final identityProvider =
    NotifierProvider<IdentityController, LocalIdentity>(IdentityController.new);

/// Alle Haushalte des aktuellen Nutzers.
final householdsProvider = StreamProvider<List<HouseholdWithRole>>((ref) {
  final identity = ref.watch(identityProvider);
  return ref.watch(householdRepositoryProvider).watchForUser(identity.userId);
});

/// Alle Kontexte, zwischen denen umgeschaltet werden kann.
///
/// Der persönliche Scope steht immer an erster Stelle und existiert immer.
final availableScopesProvider = Provider<List<AppScope>>((ref) {
  final identity = ref.watch(identityProvider);
  final households = ref.watch(householdsProvider).value ?? const [];
  return [
    AppScope.personal(identity.userId),
    for (final entry in households)
      AppScope.household(entry.household.id, entry.household.name),
  ];
});

class ActiveScopeController extends Notifier<AppScope> {
  static const _prefsKey = 'scope.active';

  @override
  AppScope build() {
    final available = ref.watch(availableScopesProvider);
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_prefsKey);
    return AppScope.tryParse(stored, available) ?? available.first;
  }

  Future<void> select(AppScope scope) async {
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, scope.key);
    state = scope;
  }
}

/// Der aktive Kontext. Färbt die gesamte Oberfläche.
final activeScopeProvider =
    NotifierProvider<ActiveScopeController, AppScope>(ActiveScopeController.new);

/// Rolle des Nutzers im aktiven Haushalt, `null` im privaten Kontext.
final activeRoleProvider = Provider((ref) {
  final scope = ref.watch(activeScopeProvider);
  if (scope.isPersonal) return null;
  final households = ref.watch(householdsProvider).value ?? const [];
  for (final entry in households) {
    if (entry.household.id == scope.id) return entry.role;
  }
  return null;
});
