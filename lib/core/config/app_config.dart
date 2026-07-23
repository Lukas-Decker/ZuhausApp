/// Zugangsdaten und Laufzeit-Konfiguration.
///
/// Die Werte kommen aus dem Compile-Time-Environment. Beim Start uebergibst du
/// sie entweder ueber eine Datei oder direkt:
///
///   flutter run --dart-define-from-file=env.json
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Direkte `--dart-define` uebersteuern die Werte aus der Datei. Ist nichts
/// gesetzt, laeuft die App im reinen Gastmodus (offline, ohne Konto/Sync).
abstract final class AppConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Deep-Link-Ziel fuer OAuth-Rueckleitungen (z.B. Google).
  ///
  /// Muss zu den Redirect-URLs im Supabase-Dashboard und zum Intent-Filter in
  /// der AndroidManifest.xml passen.
  static const String authRedirectScheme = 'de.lukas.multiapp';
  static const String authRedirectUrl = '$authRedirectScheme://login-callback';

  /// True, sobald gueltige Supabase-Zugangsdaten vorliegen.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl.startsWith('http');
}
