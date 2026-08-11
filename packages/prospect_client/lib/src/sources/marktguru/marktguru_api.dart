import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/http/cache_policy.dart';
import '../../core/http/json_reader.dart';
import '../../core/source/source_credentials.dart';

/// Rohzugriff auf die Marktguru-API.
///
/// Basis: `https://api.marktguru.de`, Version v1. Verlangt die Kopfzeilen
/// `x-apikey` und `x-clientkey`. Ohne sie antwortet jeder Endpunkt mit
/// HTTP 401 `"Invalid or missing api key"`.
///
/// Die Schluessel kommen ausschliesslich aus [SourceCredentials], also aus der
/// Umgebung oder vom Aufrufer. Im Code steht keiner.
///
/// Vorhandene Endpunkte wurden ueber die Statuscodes ermittelt: 401 bedeutet
/// vorhanden und geschuetzt, 404 nicht vorhanden. Die Feldstrukturen stammen
/// aus den serverseitig gerenderten Daten von marktguru.de, sind also echte
/// Antworten und nicht geraten.
class MarktguruApi {
  MarktguruApi(
    this._client, {
    required this.apiKey,
    required this.clientKey,
    Uri? baseUrl,
    Uri? cdnUrl,
  })  : baseUrl = baseUrl ?? Uri.parse('https://api.marktguru.de'),
        cdnUrl = cdnUrl ?? Uri.parse('https://cdn.marktguru.de');

  static const String sourceId = 'marktguru';

  /// Ohne diese beiden Werte ist die Quelle nicht nutzbar.
  static const List<CredentialKey> requiredCredentials = [
    CredentialKey.marktguruApiKey,
    CredentialKey.marktguruClientKey,
  ];

  final ApiClient _client;
  final String apiKey;
  final String clientKey;
  final Uri baseUrl;

  /// Bilder liegen auf einem eigenen Host und brauchen **keine** Zugangsdaten.
  final Uri cdnUrl;

  Map<String, String> get _headers => {
        'x-apikey': apiKey,
        'x-clientkey': clientKey,
      };

  /// Prospekte im Umkreis einer Postleitzahl.
  ///
  /// Marktguru arbeitet mit Postleitzahlen, nicht mit Koordinaten. Ein
  /// Prospekt heisst dort "leaflet flight" und buendelt mehrere Einzelhefte.
  Future<List<Map<String, Object?>>> searchLeaflets({
    required String zipCode,
    int limit = 50,
    int offset = 0,
    String? retailerId,
  }) =>
      _getItems(
        _uri('/api/v1/leaflets/search', {
          'zipCode': zipCode,
          'limit': '$limit',
          'offset': '$offset',
          if (retailerId != null) 'allowedRetailers': retailerId,
        }),
        CacheKind.brochureList,
      );

  Future<Map<String, Object?>?> leaflet(String id) =>
      _getObject(_uri('/api/v1/leaflets/$id', const {}), CacheKind.brochureDetail);

  /// Angebote, optional mit Suchbegriff.
  Future<List<Map<String, Object?>>> searchOffers({
    required String zipCode,
    String? query,
    String? retailerId,
    int limit = 50,
    int offset = 0,
  }) =>
      _getItems(
        _uri('/api/v1/offers/search', {
          'zipCode': zipCode,
          if (query != null && query.isNotEmpty) 'q': query,
          if (retailerId != null) 'allowedRetailers': retailerId,
          'limit': '$limit',
          'offset': '$offset',
        }),
        CacheKind.search,
      );

  Future<List<Map<String, Object?>>> searchRetailers({int limit = 200}) =>
      _getItems(
        _uri('/api/v1/retailers/search', {'limit': '$limit'}),
        CacheKind.retailers,
      );

  Future<List<Map<String, Object?>>> stores({
    required String zipCode,
    String? retailerId,
    int limit = 100,
  }) =>
      _getItems(
        _uri('/api/v1/stores', {
          'zipCode': zipCode,
          if (retailerId != null) 'allowedRetailers': retailerId,
          'limit': '$limit',
        }),
        CacheKind.stores,
      );

  /// Bild einer Prospektseite. Ohne Zugangsdaten abrufbar.
  ///
  /// [pageIndex] ist zero-based, anders als [BrochurePage.number].
  Uri leafletPageImage(String leafletId, int pageIndex, {String size = 'large'}) =>
      cdnUrl.replace(
        path: '/api/v1/leaflets/$leafletId/images/pages/$pageIndex/$size.webp',
      );

  Uri offerImage(String offerId, {int index = 0, String size = 'medium'}) =>
      cdnUrl.replace(
        path: '/api/v1/offers/$offerId/images/default/$index/$size.webp',
      );

  Uri retailerLogo(String retailerId, {String size = 'medium'}) => cdnUrl.replace(
        path: '/api/v1/retailers/$retailerId/images/logos/0/$size.webp',
      );

  Uri _uri(String path, Map<String, String> query) => baseUrl.replace(
        path: path,
        queryParameters: query.isEmpty ? null : query,
      );

  /// Listenantworten sind entweder ein blankes Array oder ein Objekt mit
  /// `results` und Zaehlern. Beide Formen kommen vor, je nach Endpunkt.
  Future<List<Map<String, Object?>>> _getItems(Uri uri, CacheKind kind) async {
    final response = await _client.getJson(
      uri,
      kind: kind,
      sourceId: sourceId,
      headers: _headers,
    );
    final decoded = response.decodeJson(sourceId: sourceId);

    final list = switch (decoded) {
      final List<Object?> items => items,
      final Map<String, Object?> object =>
        object.listAt('results') ?? object.listAt('items') ?? const [],
      _ => null,
    };

    if (list == null) {
      throw ResponseParseFailure(
        'Unerwartete Antwortform von $uri: ${decoded.runtimeType}',
        sourceId: sourceId,
      );
    }
    return list.whereType<Map<String, Object?>>().toList();
  }

  Future<Map<String, Object?>?> _getObject(Uri uri, CacheKind kind) async {
    try {
      final response = await _client.getJson(
        uri,
        kind: kind,
        sourceId: sourceId,
        headers: _headers,
      );
      final decoded = response.decodeJson(sourceId: sourceId);
      return decoded is Map<String, Object?> ? decoded : null;
    } on NotFound {
      return null;
    }
  }
}
