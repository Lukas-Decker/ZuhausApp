import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Biometrisches App-Schloss.
///
/// Bewusst rein lokal: die Entsperrung passiert ueber die Geraete-Biometrie
/// (Windows Hello am Desktop, Fingerabdruck/Gesicht auf Android). Es verlaesst
/// nichts das Geraet, es gibt keinen Server-Anteil. Auf Plattformen ohne
/// Unterstuetzung (z.B. Linux) meldet [isSupported] schlicht `false`.
abstract class AppLock {
  /// Ob das Geraet ueberhaupt eine Nutzer-Verifikation anbietet
  /// (Biometrie oder Geraete-PIN/Passwort).
  Future<bool> isSupported();

  /// Fordert die Entsperrung an. `true` bei Erfolg, `false` bei Abbruch,
  /// Fehlschlag oder fehlender Unterstuetzung.
  Future<bool> authenticate();
}

/// Echte Umsetzung ueber das `local_auth`-Plugin.
class LocalAuthAppLock implements AppLock {
  LocalAuthAppLock([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (error) {
      // Nicht unterstuetzte Plattform (z.B. Linux) wirft MissingPluginException.
      debugPrint('[app-lock] isDeviceSupported nicht verfuegbar: $error');
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Zum Entsperren von MultiApp bestaetigen',
        // Bei App-Wechsel nicht abbrechen, sondern beim Zurueckkehren erneut
        // versuchen.
        persistAcrossBackgrounding: true,
        // Geraete-PIN/Passwort als Rueckfallebene zulassen, damit man sich
        // nicht aussperrt, wenn die Biometrie mal nicht greift.
        biometricOnly: false,
      );
    } catch (error) {
      debugPrint('[app-lock] authenticate fehlgeschlagen: $error');
      return false;
    }
  }
}

final appLockProvider = Provider<AppLock>((ref) => LocalAuthAppLock());

/// Ob dieses Geraet das App-Schloss unterstuetzt. Steuert, ob der Schalter in
/// den Einstellungen aktiv ist.
final appLockSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(appLockProvider).isSupported(),
);
