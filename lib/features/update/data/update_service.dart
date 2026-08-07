import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/release_manifest.dart';

/// Holt das Versions-Manifest vom eigenen Server.
///
/// Das Manifest ist eine simple JSON-Datei im oeffentlichen Storage-Bucket;
/// es braucht dafuer weder Konto noch Anmeldung.
class UpdateService {
  UpdateService({http.Client? client, String? manifestUrl})
    : _client = client ?? http.Client(),
      _manifestUrl = manifestUrl ?? AppConfig.updateManifestUrl;

  final http.Client _client;
  final String _manifestUrl;

  static const Duration _timeout = Duration(seconds: 15);

  bool get isConfigured => _manifestUrl.startsWith('http');

  /// Plattform-Schluessel im Manifest, oder `null` wo es keine Pakete gibt.
  static String? get currentPlatform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    return null;
  }

  Future<ReleaseManifest> fetchManifest() async {
    if (!isConfigured) {
      throw const UpdateException('Kein Update-Server konfiguriert.');
    }
    // Supabase Storage liefert ueber ein CDN aus. Ein Zeitstempel in der
    // Abfrage sorgt dafuer, dass wirklich die frische Datei ankommt.
    final uri = Uri.parse(
      '$_manifestUrl?t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Cache-Control': 'no-cache'})
          .timeout(_timeout);
    } on Object catch (error) {
      throw UpdateException('Server nicht erreichbar ($error).');
    }
    if (response.statusCode == 404) {
      throw const UpdateException(
        'Noch keine Version veröffentlicht (manifest.json fehlt).',
      );
    }
    if (response.statusCode != 200) {
      throw UpdateException('Server antwortet mit ${response.statusCode}.');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Manifest ist kein JSON-Objekt.');
      }
      return ReleaseManifest.fromJson(decoded);
    } on FormatException catch (error) {
      throw UpdateException('Manifest unlesbar (${error.message}).');
    }
  }

  void dispose() => _client.close();
}

/// Fehler, deren Text direkt angezeigt werden kann.
class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
