import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../config/app_config.dart';

/// Registriert das App-eigene URL-Schema (`de.lukas.multiapp://`) bei Windows.
///
/// Damit oeffnet der OAuth-Rueckweg (Google) und der Passwort-Reset auch auf
/// dem Desktop wieder die App. Auf anderen Plattformen ist das ein No-op:
/// Android nutzt den Intent-Filter, Linux/macOS ihre eigenen Mechanismen.
///
/// Der Eintrag liegt unter HKEY_CURRENT_USER und braucht keine Admin-Rechte.
/// Er zeigt auf die aktuell laufende exe; bei einem Release mit Installer
/// uebernimmt normalerweise der Installer die Registrierung.
Future<void> registerWindowsDeepLinkScheme() async {
  if (kIsWeb || !Platform.isWindows) return;

  try {
    final scheme = AppConfig.authRedirectScheme;
    final appPath = Platform.resolvedExecutable;

    final protocolKey = CURRENT_USER.create('Software\\Classes\\$scheme');
    // Kennzeichnet den Schluessel als URL-Protokoll-Handler.
    protocolKey.setValue('URL Protocol', const RegistryValue.string(''));

    final commandKey = protocolKey.create('shell\\open\\command');
    // Beim Oeffnen eines de.lukas.multiapp://-Links wird die exe mit der URL
    // als Argument gestartet.
    commandKey.setValue('', RegistryValue.string('"$appPath" "%1"'));

    commandKey.close();
    protocolKey.close();
  } catch (error) {
    debugPrint('Windows-Deep-Link-Registrierung fehlgeschlagen: $error');
  }
}
