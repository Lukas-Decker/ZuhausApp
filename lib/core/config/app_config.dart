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
  static const String _rawSupabaseUrl =
      String.fromEnvironment('SUPABASE_URL');

  /// Basis-URL des Projekts, ohne Pfad.
  ///
  /// Im neuen Supabase-Dashboard steht unter "Data API" oft die REST-URL mit
  /// `/rest/v1/` am Ende. Supabase.initialize braucht aber nur `scheme://host`,
  /// deshalb schneiden wir einen eventuellen Pfad hier ab.
  static String get supabaseUrl {
    final raw = _rawSupabaseUrl.trim();
    if (raw.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return raw;
    return '${uri.scheme}://${uri.host}';
  }

  /// Akzeptiert den neuen "Publishable key" (sb_publishable_...) ebenso wie den
  /// aelteren "anon key". Beide Feldnamen werden unterstuetzt.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

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
