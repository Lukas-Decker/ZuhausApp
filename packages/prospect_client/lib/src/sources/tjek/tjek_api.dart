import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/http/cache_policy.dart';
import '../../core/models/geo.dart';

/// Rohzugriff auf die Tjek-API (frueher ShopGun).
///
/// Basis: `https://squid-api.tjek.com`, Version v2, ohne Authentifizierung.
/// Verifiziert am 2026-08-10, siehe RESEARCH.md Abschnitt 2.
///
/// Diese Klasse kennt ausschliesslich HTTP und Endpunktnamen. Die Uebersetzung
/// in das neutrale Modell macht der Mapper.
class TjekApi {
  TjekApi(this._client, {Uri? baseUrl})
      : baseUrl = baseUrl ?? Uri.parse('https://squid-api.tjek.com');

  static const String sourceId = 'tjek';

  /// Die API deckelt Listenabfragen. Bei Ueberschreitung liefert sie stumm
  /// weniger Eintraege, statt zu paginieren, deshalb wird hier begrenzt.
  static const int maxPageSize = 100;

  final ApiClient _client;
  final Uri baseUrl;

  Future<List<Map<String, Object?>>> dealers({
    int limit = maxPageSize,
    int offset = 0,
  }) =>
      _getList(
        _uri('/v2/dealers', {
          'limit': '${limit.clamp(1, maxPageSize)}',
          'offset': '$offset',
        }),
        CacheKind.retailers,
      );

  Future<Map<String, Object?>?> dealer(String id) =>
      _getObject(_uri('/v2/dealers/$id', const {}), CacheKind.retailers);

  /// Prospekte einer Quelle.
  ///
  /// Wichtig: der Filter heisst `dealer_id` im Singular. Die haeufig zitierte
  /// Variante `dealer_ids[]` wird von der API stillschweigend ignoriert und
  /// liefert dann ungefilterte Ergebnisse aus allen Laendern. Das ist im
  /// Betrieb schwer zu bemerken, deshalb hier explizit festgehalten.
  Future<List<Map<String, Object?>>> catalogs({
    String? dealerId,
    GeoPoint? near,
    int radiusMeters = 50000,
    int limit = maxPageSize,
    int offset = 0,
  }) =>
      _getList(
        _uri('/v2/catalogs', {
          if (dealerId != null) 'dealer_id': dealerId,
          if (near != null) ...{
            'r_lat': '${near.latitude}',
            'r_lng': '${near.longitude}',
            'r_radius': '$radiusMeters',
          },
          'limit': '${limit.clamp(1, maxPageSize)}',
          'offset': '$offset',
        }),
        CacheKind.brochureList,
      );

  Future<Map<String, Object?>?> catalog(String id) =>
      _getObject(_uri('/v2/catalogs/$id', const {}), CacheKind.brochureDetail);

  /// Seitenbilder in drei Aufloesungen. Reihenfolge im Array entspricht der
  /// Seitenreihenfolge, es gibt kein explizites Seitennummernfeld.
  Future<List<Map<String, Object?>>> catalogPages(String id) =>
      _getList(_uri('/v2/catalogs/$id/pages', const {}), CacheKind.brochureDetail);

  /// Positionen der Angebote auf den Seiten.
  Future<List<Map<String, Object?>>> catalogHotspots(String id) => _getList(
        _uri('/v2/catalogs/$id/hotspots', const {}),
        CacheKind.brochureDetail,
      );

  Future<List<Map<String, Object?>>> offers({
    String? dealerId,
    String? catalogId,
    GeoPoint? near,
    int radiusMeters = 50000,
    int limit = maxPageSize,
    int offset = 0,
  }) =>
      _getList(
        _uri('/v2/offers', {
          if (dealerId != null) 'dealer_id': dealerId,
          if (catalogId != null) 'catalog_id': catalogId,
          if (near != null) ...{
            'r_lat': '${near.latitude}',
            'r_lng': '${near.longitude}',
            'r_radius': '$radiusMeters',
          },
          'limit': '${limit.clamp(1, maxPageSize)}',
          'offset': '$offset',
        }),
        CacheKind.brochureDetail,
      );

  Future<List<Map<String, Object?>>> searchOffers({
    required String query,
    String? dealerId,
    GeoPoint? near,
    int radiusMeters = 50000,
    int limit = 50,
  }) =>
      _getList(
        _uri('/v2/offers/search', {
          'query': query,
          if (dealerId != null) 'dealer_id': dealerId,
          if (near != null) ...{
            'r_lat': '${near.latitude}',
            'r_lng': '${near.longitude}',
            'r_radius': '$radiusMeters',
          },
          'limit': '${limit.clamp(1, maxPageSize)}',
        }),
        CacheKind.search,
      );

  /// Filialen, in denen ein Prospekt gilt.
  ///
  /// Fuer filialgebundene Prospekte (`all_stores: false`) genau die
  /// zugehoerigen Filialen. Beim Berliner HIT-Wochenprospekt sind das drei.
  Future<List<Map<String, Object?>>> catalogStores(String id) =>
      _getList(_uri('/v2/catalogs/$id/stores', const {}), CacheKind.stores);

  Future<List<Map<String, Object?>>> stores({
    required String dealerId,
    GeoPoint? near,
    int radiusMeters = 50000,
    int limit = maxPageSize,
  }) =>
      _getList(
        _uri('/v2/stores', {
          'dealer_id': dealerId,
          if (near != null) ...{
            'r_lat': '${near.latitude}',
            'r_lng': '${near.longitude}',
            'r_radius': '$radiusMeters',
          },
          'limit': '${limit.clamp(1, maxPageSize)}',
        }),
        CacheKind.stores,
      );

  Uri _uri(String path, Map<String, String> query) => baseUrl.replace(
        path: path,
        queryParameters: query.isEmpty ? null : query,
      );

  Future<List<Map<String, Object?>>> _getList(Uri uri, CacheKind kind) async {
    final response = await _client.getJson(uri, kind: kind, sourceId: sourceId);
    final decoded = response.decodeJson(sourceId: sourceId);
    if (decoded is! List) {
      throw ResponseParseFailure(
        'Erwartet wurde eine Liste von $uri, erhalten: ${decoded.runtimeType}',
        sourceId: sourceId,
      );
    }
    return decoded.whereType<Map<String, Object?>>().toList();
  }

  Future<Map<String, Object?>?> _getObject(Uri uri, CacheKind kind) async {
    try {
      final response =
          await _client.getJson(uri, kind: kind, sourceId: sourceId);
      final decoded = response.decodeJson(sourceId: sourceId);
      return decoded is Map<String, Object?> ? decoded : null;
    } on NotFound {
      return null;
    }
  }
}
