import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Laedt Produktbilder einmalig herunter und legt sie lokal ab.
///
/// Bewusst offline-first: ist ein Bild schon im Cache, wird es ohne Netz
/// angezeigt; fehlt es und es gibt keine Verbindung, faellt die Anzeige auf ein
/// Symbol zurueck. Nutzt das vorhandene http-/path_provider-Paket, keine
/// zusaetzliche Abhaengigkeit.
class ProductImageCache {
  ProductImageCache([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;
  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/product_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  /// Stabiler Dateiname aus der URL (FNV-1a), ohne Krypto-Abhaengigkeit.
  static String _hash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Liefert die lokale Bilddatei zur [url], laedt sie bei Bedarf herunter.
  /// Gibt `null` zurueck, wenn kein Bild verfuegbar ist.
  Future<File?> resolve(String url) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_hash(url)}.img');
      if (await file.exists() && await file.length() > 0) return file;

      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
