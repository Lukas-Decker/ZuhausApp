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

  /// Name des oeffentlichen Storage-Buckets mit den Release-Dateien.
  static const String updateBucket = 'releases';

  static const String _rawUpdateBaseUrl =
      String.fromEnvironment('UPDATE_BASE_URL');

  /// Basis-URL des Update-Kanals, ohne Schraegstrich am Ende.
  ///
  /// Standardmaessig der oeffentliche Bucket im eigenen Supabase-Projekt.
  /// Mit `--dart-define=UPDATE_BASE_URL=https://...` laesst sich stattdessen
  /// ein beliebiger Webserver ansprechen, ohne die App umzubauen.
  static String get updateBaseUrl {
    final raw = _rawUpdateBaseUrl.trim();
    if (raw.isNotEmpty) {
      return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    }
    final base = supabaseUrl;
    if (base.isEmpty) return '';
    return '$base/storage/v1/object/public/$updateBucket';
  }

  /// Adresse des Versions-Manifests.
  static String get updateManifestUrl {
    final base = updateBaseUrl;
    return base.isEmpty ? '' : '$base/manifest.json';
  }

  /// True, sobald ein Update-Kanal erreichbar konfiguriert ist.
  static bool get hasUpdateChannel => updateManifestUrl.startsWith('http');

  /// True, sobald gueltige Supabase-Zugangsdaten vorliegen.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl.startsWith('http');
}
