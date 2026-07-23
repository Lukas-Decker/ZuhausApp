import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import 'data/auth_service.dart';

/// Wird in `main()` nach der Supabase-Initialisierung ueberschrieben.
final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError('AuthService nicht initialisiert'),
);

/// True, wenn ein Konto-Server (Supabase) eingerichtet ist.
final authConfiguredProvider = Provider<bool>(
  (ref) => ref.watch(authServiceProvider).isConfigured,
);

/// Auth-Ereignisse von Supabase (Login, Logout, Token-Refresh).
final authStateChangesProvider = StreamProvider<AuthState?>((ref) {
  final service = ref.watch(authServiceProvider);
  if (!service.isConfigured) return Stream.value(null);
  return service.onAuthStateChange;
});

/// Der aktuell angemeldete Supabase-Nutzer, oder `null` im Gastmodus.
///
/// Reagiert auf [authStateChangesProvider] und stoesst beim Login das Binden
/// der bisherigen Gast-Daten an die Konto-ID an.
final currentUserProvider = Provider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  if (!service.isConfigured) return null;

  // Auf Aenderungen lauschen; der konkrete Event-Inhalt ist hier egal.
  final change = ref.watch(authStateChangesProvider);

  final user = service.currentUser;

  change.whenData((state) {
    if (state?.event == AuthChangeEvent.signedIn && state?.session != null) {
      ref.read(accountBinderProvider).onSignedIn(state!.session!.user.id);
    }
  });

  return user;
});

/// Bindet lokale Gast-Daten einmalig an die Konto-ID.
final accountBinderProvider = Provider<AccountBinder>(
  (ref) => AccountBinder(ref),
);

class AccountBinder {
  AccountBinder(this._ref);

  final Ref _ref;
  String? _boundTo;

  Future<void> onSignedIn(String newUserId) async {
    if (_boundTo == newUserId) return;
    _boundTo = newUserId;

    final store = _ref.read(localIdentityStoreProvider);
    final guest = store.loadOrCreate();

    // Vorhandene private Gast-Daten auf die Konto-ID umschreiben.
    if (!guest.isLinkedToAccount && guest.userId != newUserId) {
      await _ref
          .read(databaseProvider)
          .rebindPersonalScope(guest.userId, newUserId);
    }

    // Lokale Identitaet als konto-gebunden markieren.
    await store.save(
      guest.copyWith(userId: newUserId, isLinkedToAccount: true),
    );
  }
}
