import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

/// Ergebnis eines Anmelde- oder Registrierungsversuchs.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

/// Registrierung erfolgreich, aber die E-Mail muss noch bestaetigt werden.
class AuthNeedsEmailConfirmation extends AuthResult {
  const AuthNeedsEmailConfirmation(this.email);
  final String email;
}

/// Login gescheitert, weil die E-Mail noch nicht bestaetigt ist.
class AuthEmailNotConfirmed extends AuthResult {
  const AuthEmailNotConfirmed(this.email);
  final String email;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

/// Ergebnis eines Kontoloeschungs-Versuchs.
sealed class DeleteAccountResult {
  const DeleteAccountResult();
}

class DeleteAccountSuccess extends DeleteAccountResult {
  const DeleteAccountSuccess();
}

/// Loeschung abgelehnt: der Nutzer ist noch Eigentuemer von Haushalten mit
/// weiteren Mitgliedern und muss die Eigentuemerschaft erst uebergeben.
class DeleteAccountNeedsTransfer extends DeleteAccountResult {
  const DeleteAccountNeedsTransfer(this.households);
  final List<String> households;
}

class DeleteAccountFailure extends DeleteAccountResult {
  const DeleteAccountFailure(this.message);
  final String message;
}

/// Kapselt die Anmeldung ueber Supabase.
///
/// Ist kein Supabase-Projekt konfiguriert (kein URL/Key), meldet der Dienst
/// [isConfigured] == false und die App bleibt im Gastmodus.
class AuthService {
  AuthService._(this._client);

  /// Baut den Dienst; `null`-Client, wenn nicht konfiguriert.
  factory AuthService.resolve() {
    if (!AppConfig.hasSupabase) return AuthService._(null);
    return AuthService._(Supabase.instance.client);
  }

  @visibleForTesting
  factory AuthService.withClient(SupabaseClient client) =>
      AuthService._(client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Session? get currentSession => _client?.auth.currentSession;
  User? get currentUser => _client?.auth.currentUser;

  /// Strom der Auth-Ereignisse (Login, Logout, Token-Refresh ...).
  Stream<AuthState> get onAuthStateChange =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final client = _client;
    if (client == null) return const AuthFailure(_notConfigured);
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
      // Bei aktivierter E-Mail-Bestaetigung gibt es noch keine Session.
      if (response.session == null) {
        return AuthNeedsEmailConfirmation(email.trim());
      }
      return const AuthSuccess();
    } on AuthException catch (error) {
      return AuthFailure(_translate(error));
    } catch (error) {
      return AuthFailure('Unerwarteter Fehler: $error');
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return const AuthFailure(_notConfigured);
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthSuccess();
    } on AuthException catch (error) {
      if (_isNotConfirmed(error)) {
        return AuthEmailNotConfirmed(email.trim());
      }
      return AuthFailure(_translate(error));
    } catch (error) {
      return AuthFailure('Unerwarteter Fehler: $error');
    }
  }

  /// Sendet die Bestaetigungs-Mail erneut.
  Future<AuthResult> resendConfirmation(String email) async {
    final client = _client;
    if (client == null) return const AuthFailure(_notConfigured);
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
      return const AuthSuccess();
    } on AuthException catch (error) {
      return AuthFailure(_translate(error));
    } catch (error) {
      return AuthFailure('Unerwarteter Fehler: $error');
    }
  }

  static bool _isNotConfirmed(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final msg = error.message.toLowerCase();
    return code.contains('not_confirmed') ||
        code.contains('email_not_confirmed') ||
        msg.contains('not confirmed') ||
        msg.contains('confirm your');
  }

  /// Startet den Google-Login ueber den System-Browser mit Deep-Link-Rueckweg.
  Future<AuthResult> signInWithGoogle() async {
    final client = _client;
    if (client == null) return const AuthFailure(_notConfigured);
    try {
      final started = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // Der eigentliche Login schliesst per Deep Link ab; onAuthStateChange
      // liefert dann das Ergebnis.
      return started ? const AuthSuccess() : const AuthFailure(
        'Google-Anmeldung konnte nicht gestartet werden.',
      );
    } on AuthException catch (error) {
      return AuthFailure(_translate(error));
    } catch (error) {
      return AuthFailure('Unerwarteter Fehler: $error');
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    final client = _client;
    if (client == null) return const AuthFailure(_notConfigured);
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authRedirectUrl,
      );
      return const AuthSuccess();
    } on AuthException catch (error) {
      return AuthFailure(_translate(error));
    } catch (error) {
      return AuthFailure('Unerwarteter Fehler: $error');
    }
  }

  Future<void> updateDisplayName(String name) async {
    final client = _client;
    if (client == null) return;
    await client.auth.updateUser(
      UserAttributes(data: {'display_name': name.trim()}),
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// Loescht das Konto samt Serverdaten endgueltig ueber die Edge Function
  /// `delete-account`. Die lokale Datenbank raeumt der Aufrufer danach auf.
  Future<DeleteAccountResult> deleteAccount() async {
    final client = _client;
    if (client == null) return const DeleteAccountFailure(_notConfigured);
    try {
      await client.functions.invoke('delete-account');
      return const DeleteAccountSuccess();
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] == 'owner_transfer_required') {
        final names =
            (details['households'] as List?)?.map((e) => '$e').toList() ??
            const <String>[];
        return DeleteAccountNeedsTransfer(names);
      }
      final message = details is Map && details['error'] != null
          ? '${details['error']}'
          : (error.reasonPhrase ?? 'Loeschung fehlgeschlagen.');
      return DeleteAccountFailure(message);
    } catch (error) {
      return DeleteAccountFailure('Unerwarteter Fehler: $error');
    }
  }

  static const _notConfigured =
      'Kein Konto-Server eingerichtet. Die App laeuft im Gastmodus.';

  /// Uebersetzt haeufige Supabase-Fehlermeldungen ins Deutsche.
  static String _translate(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'E-Mail oder Passwort ist falsch.';
    }
    if (message.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'Für diese E-Mail gibt es bereits ein Konto.';
    }
    if (message.contains('password should be at least')) {
      return 'Das Passwort ist zu kurz (mindestens 6 Zeichen).';
    }
    if (message.contains('unable to validate email') ||
        message.contains('invalid email')) {
      return 'Die E-Mail-Adresse ist ungültig.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Zu viele Versuche. Bitte warte einen Moment.';
    }
    return error.message;
  }
}

/// Liefert den Anzeigenamen aus den Metadaten oder faellt auf die E-Mail zurueck.
String displayNameFor(User user) {
  final data = user.userMetadata;
  final name = data?['display_name'] ?? data?['full_name'] ?? data?['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  final email = user.email;
  if (email != null && email.isNotEmpty) return email.split('@').first;
  return 'Ich';
}
