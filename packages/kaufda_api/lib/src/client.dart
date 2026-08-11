import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'geo.dart';
import 'models/brochure.dart';
import 'models/common.dart';
import 'models/json.dart';
import 'models/offer.dart';
import 'models/page.dart';
import 'models/search.dart';
import 'models/shelf.dart';
import 'models/store.dart';
import 'session.dart';

/// Bekannte Werte fuer den `placement`-Parameter der Related-Abfrage.
abstract final class AdPlacement {
  /// Empfehlung am Prospektende ("naechster Prospekt").
  static const nextBrochure = 'ad_placement__next_brochure';

  /// Prospektleiste neben dem Viewer.
  static const brochureBar = 'ad_placement__brochure_bar';

  /// Kacheln auf der letzten Prospektseite.
  static const lastPageDisplay = 'ad_placement__last_page_display';
}

/// Client fuer die kaufDA Content-Viewer-API (`content-viewer-be.kaufda.de`).
///
/// Reines Dart ohne `dart:io`, laeuft damit unveraendert in Flutter auf
/// Android, iOS, Desktop und Web.
///
/// ```dart
/// final client = KaufdaClient(
///   location: const GeoLocation(lat: 49.6378338, lng: 7.1113922),
/// );
/// final brochure = await client.brochure('72a3b683-90ff-4d09-9815-6baebe0a1b1d');
/// final pages = await client.pages(brochure.id);
/// client.close();
/// ```
class KaufdaClient {
  KaufdaClient({
    http.Client? httpClient,
    SessionProvider? sessionProvider,
    Uri? baseUri,
    Uri? portalUri,
    this.location,
    this.partner = 'kaufda_web',
    this.brochureKey = '',
    this.apiConsumer = 'web-content-viewer-fe',
    this.deliveryChannel = 'dest.kaufda',
    this.userPlatformCategory = 'desktop.web.browser',
    this.userPlatformOs = 'windows',
    this.userAgent = defaultUserAgent,
    this.sendBrowserHeaders = true,
  })  : _http = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        baseUri = baseUri ?? defaultBaseUri,
        portalUri = portalUri ?? defaultPortalUri,
        _ownsSessionProvider = sessionProvider == null {
    _sessionProvider = sessionProvider ?? WebSessionProvider(httpClient: _http);
  }

  /// Basis der Content-Viewer-API.
  static final Uri defaultBaseUri =
      Uri.https('content-viewer-be.kaufda.de', '/v1/');

  /// Portal, das Session und Account-ID ausliefert.
  static final Uri defaultPortalUri = Uri.https('www.kaufda.de', '/');

  /// User-Agent aus der aufgezeichneten Sitzung.
  static const defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; '
      'rv:153.0) Gecko/20100101 Firefox/153.0';

  final http.Client _http;
  final bool _ownsHttpClient;
  final bool _ownsSessionProvider;
  late final SessionProvider _sessionProvider;

  final Uri baseUri;
  final Uri portalUri;

  /// Standardstandort, wenn eine Methode keinen eigenen bekommt.
  final GeoLocation? location;

  /// Partnerkennung, im Web-Frontend `kaufda_web`.
  final String partner;

  /// Wird bei nicht oeffentlichen Prospekten gefuellt, sonst leer.
  final String brochureKey;

  /// Wert des Headers `Bonial-Api-Consumer`.
  final String apiConsumer;

  final String deliveryChannel;
  final String userPlatformCategory;
  final String userPlatformOs;
  final String userAgent;

  /// Sendet `User-Agent`, `Origin` und `Referer` wie das Web-Frontend.
  /// In Flutter Web verwirft der Browser diese Header, dort ohne Wirkung.
  final bool sendBrowserHeaders;

  /// Der aktive Session-Provider, z. B. um den Token weiterzureichen.
  SessionProvider get sessionProvider => _sessionProvider;

  /// Prospekt-Metadaten: `GET /v1/brochures/{id}`.
  Future<Brochure> brochure(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
  }) async {
    final json = await _getJson(
      'brochures/$brochureId',
      {
        ..._baseQuery(location, brochureKey),
        'brochureId': brochureId,
      },
    );
    return Brochure.fromJson(asMap(json['content']) ?? json);
  }

  /// Alle Seiten inklusive Angebote: `GET /v1/brochures/{id}/pages`.
  Future<List<BrochurePage>> pages(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
  }) async {
    final json = await _getJson(
      'brochures/$brochureId/pages',
      _baseQuery(location, brochureKey),
    );
    return mapList(json['contents'], BrochurePage.fromJson);
  }

  /// Empfehlungen zum aktuellen Prospekt: `GET /v1/brochures/related`.
  Future<BrochureCollections> related(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
    String placement = AdPlacement.nextBrochure,
  }) async {
    final json = await _getJson(
      'brochures/related',
      {
        'brochureId': brochureId,
        ..._baseQuery(location, brochureKey),
        'placement': placement,
      },
      extraHeaders: _platformHeaders,
    );
    return BrochureCollections.fromJson(json);
  }

  /// Prospektleiste neben dem Viewer: `GET /v1/sidebar`.
  Future<BrochureCollections> sidebar(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
  }) async {
    final json = await _getJson(
      'sidebar',
      {'brochureId': brochureId, ..._baseQuery(location, brochureKey)},
      extraHeaders: _platformHeaders,
    );
    return BrochureCollections.fromJson(json);
  }

  /// Kacheln fuer die letzte Prospektseite: `GET /v1/lastPage`.
  Future<BrochureCollections> lastPage(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
  }) async {
    final json = await _getJson(
      'lastPage',
      {..._baseQuery(location, brochureKey), 'brochureId': brochureId},
      extraHeaders: _platformHeaders,
    );
    return BrochureCollections.fromJson(json);
  }

  /// Naechstgelegene Filiale: `GET /v1/nearestStore`.
  ///
  /// Gibt `null` zurueck, wenn es zum Prospekt keine passende Filiale gibt.
  Future<Store?> nearestStore(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
  }) async {
    final Map<String, dynamic> json;
    try {
      json = await _getJson(
        'nearestStore',
        {..._baseQuery(location, brochureKey), 'brochureId': brochureId},
      );
    } on KaufdaHttpException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    } on KaufdaParseException {
      return null;
    }
    if (json.isEmpty) return null;
    return Store.fromJson(json);
  }

  /// Volltextsuche: `GET https://www.kaufda.de/api/search`.
  ///
  /// Sucht standortbezogen nach Haendlern und Produkten. Die Antwort enthaelt
  /// passende Prospekte und Angebote sowie in
  /// [SearchResult.metadata] die Gesamttrefferzahlen und was die Suche im
  /// Begriff erkannt hat.
  ///
  /// [limit] gilt fuer beide Listen gemeinsam und wird bis mindestens 200
  /// respektiert, [offset] blaettert weiter (ab `offset > 0` liefert die API
  /// keine Prospekte mehr). Sortierung ueber [SearchSort].
  Future<SearchResult> search(
    String query, {
    GeoLocation? location,
    int limit = 24,
    int offset = 0,
    String? sort,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(query, 'query', 'darf nicht leer sein');
    }
    final geo = _requireLocation(location);
    final uri = portalUri.resolve('api/search').replace(
      queryParameters: {
        'lat': geo.latParam,
        'lng': geo.lngParam,
        'query': trimmed,
        'limit': '$limit',
        if (offset > 0) 'offset': '$offset',
        if (sort != null) 'sort': sort,
      },
    );
    return SearchResult.fromJson(await _getJsonAt(uri));
  }

  /// Sucht die Prospekte eines Haendlers ueber seinen Namen.
  ///
  /// Nutzt [search] und filtert das Ergebnis auf den Haendler, den die API im
  /// Begriff erkannt hat (`recognizedEntities`). Erkennt die API keinen
  /// Haendler, wird auf einen Namensvergleich zurueckgefallen, damit auch
  /// Schreibweisen wie `netto marken` etwas liefern.
  ///
  /// Der Endpunkt filtert selbst nicht nach Haendler, das passiert hier.
  Future<RetailerSearch> searchRetailer(
    String name, {
    GeoLocation? location,
    int limit = 100,
    bool onlyValid = false,
    bool includeOffers = true,
  }) async {
    final result = await search(name, location: location, limit: limit);
    final recognized = result.metadata.retailer;

    String? publisherId = recognized?.id;
    String? publisherName = recognized?.value;

    if (publisherId == null) {
      // Kein Haendler erkannt: ueber den Namen der Facetten gehen.
      final needle = name.trim().toLowerCase();
      for (final facet in result.metadata.publisherFacets) {
        final label = facet.name?.toLowerCase();
        if (label != null && label.contains(needle)) {
          publisherId = facet.value;
          publisherName = facet.name;
          break;
        }
      }
    }

    bool matchesBrochure(SearchBrochure brochure) {
      if (onlyValid && !brochure.isValidNow) return false;
      if (publisherId == null) return true;
      return brochure.publisher.id == publisherId;
    }

    return RetailerSearch(
      query: name,
      result: result,
      publisherId: publisherId,
      publisherName: publisherName,
      brochures: [
        for (final brochure in result.brochureContents)
          if (matchesBrochure(brochure)) brochure,
      ],
      offers: !includeOffers
          ? const []
          : [
              for (final offer in result.offers)
                if (publisherId == null || offer.publisherId == publisherId)
                  offer,
            ],
    );
  }

  /// Prospekte im Umkreis: `GET https://www.kaufda.de/api/shelf`.
  ///
  /// Das ist der Endpunkt hinter der Seite `www.kaufda.de/shelf`, also die
  /// vollstaendige Liste fuer einen Standort statt der Empfehlungen aus
  /// [nearbyBrochures].
  ///
  /// [size] wird bis mindestens 100 respektiert, [page] zaehlt ab 0.
  /// [sectorIds] filtert nach Branchen, siehe [KaufdaSector]; mehrere Werte
  /// wirken wie ein Oder.
  Future<ShelfPage> shelf({
    GeoLocation? location,
    int page = 0,
    int size = 24,
    Iterable<String> sectorIds = const [],
  }) async {
    final geo = _requireLocation(location);
    final uri = portalUri.resolve('api/shelf').replace(
      queryParameters: {
        'lat': geo.latParam,
        'lng': geo.lngParam,
        'size': '$size',
        'page': '$page',
        'sectorIds': sectorIds.join(','),
      },
    );
    return ShelfPage.fromJson(await _getJsonAt(uri));
  }

  /// Blaettert die Shelf-Suche durch und liefert alle Prospekte am Stueck.
  ///
  /// [maxPages] begrenzt die Zahl der Requests, [onlyValid] wirft abgelaufene
  /// und noch nicht gestartete Prospekte raus.
  Future<List<ShelfBrochure>> shelfAll({
    GeoLocation? location,
    int pageSize = 100,
    int maxPages = 10,
    Iterable<String> sectorIds = const [],
    bool onlyValid = false,
  }) async {
    final found = <String, ShelfBrochure>{};
    for (var page = 0; page < maxPages; page++) {
      final result = await shelf(
        location: location,
        page: page,
        size: pageSize,
        sectorIds: sectorIds,
      );
      for (final brochure in result.brochures) {
        if (brochure.id.isEmpty) continue;
        if (onlyValid && !brochure.isValidNow) continue;
        found.putIfAbsent(brochure.id, () => brochure);
      }
      if (!result.page.hasNext) break;
    }
    return found.values.toList(growable: false);
  }

  /// Prospekte im Umkreis, zusammengesucht ueber die Empfehlungslisten.
  ///
  /// Aelterer Weg aus der Zeit, als der Shelf-Endpunkt noch nicht bekannt war.
  /// Fuer eine vollstaendige Liste ist [shelf] bzw. [shelfAll] die bessere
  /// Wahl; diese Methode bleibt nuetzlich, wenn man von einem konkreten
  /// Prospekt aus dessen Umfeld sehen will.
  ///
  /// Diese Methode hangelt sich
  /// ueber die drei Empfehlungslisten (`sidebar`, `related`, `lastPage`), die
  /// alle `lat`/`lng` auswerten und neben dem eigenen Haendler auch Branchen-
  /// und Beliebt-Prospekte aus der Umgebung liefern.
  ///
  /// Deshalb braucht der Aufruf mindestens eine bekannte Prospekt-ID als
  /// Einstieg. Jede gefundene ID taugt als naechster Einstieg, also am besten
  /// eine davon speichern: Prospekte laufen nach ein bis zwei Wochen ab, ein
  /// fest verdrahteter Startwert veraltet.
  ///
  /// [depth] `1` fragt nur den Startpunkt ab (drei Requests), `2` nimmt die
  /// gefundenen Prospekte erneut als Einstieg (bis zu [seedsPerRound] Stueck,
  /// also bis zu `3 * seedsPerRound` weitere Requests).
  Future<List<BrochureSummary>> nearbyBrochures({
    required Iterable<String> seedBrochureIds,
    GeoLocation? location,
    String? brochureKey,
    int depth = 1,
    int maxBrochures = 250,
    int seedsPerRound = 8,
    bool onlyValid = false,
    String? publisherId,
  }) async {
    if (depth < 1) {
      throw ArgumentError.value(depth, 'depth', 'muss mindestens 1 sein');
    }
    final seeds = seedBrochureIds.toList();
    if (seeds.isEmpty) {
      throw ArgumentError.value(
        seedBrochureIds,
        'seedBrochureIds',
        'mindestens eine Start-Prospekt-ID noetig',
      );
    }

    final found = <String, BrochureSummary>{};
    final visited = <String>{};
    var frontier = seeds;
    var reachable = 0;

    for (var round = 0; round < depth; round++) {
      if (frontier.isEmpty || found.length >= maxBrochures) break;
      final discovered = <String>[];
      for (final seed in frontier.take(seedsPerRound)) {
        if (!visited.add(seed)) continue;
        final collections = await _collectionsFor(seed, location, brochureKey);
        if (collections == null) continue;
        reachable++;
        for (final item in collections) {
          final summary = item.content;
          if (summary.id.isEmpty) continue;
          if (found.containsKey(summary.id)) continue;
          discovered.add(summary.id);
          if (publisherId != null && summary.publisher.id != publisherId) {
            continue;
          }
          if (onlyValid && !summary.isValidNow) continue;
          found[summary.id] = summary;
          if (found.length >= maxBrochures) break;
        }
        if (found.length >= maxBrochures) break;
      }
      frontier = discovered;
    }

    if (reachable == 0) {
      throw KaufdaException(
        'Keine der Start-IDs war abrufbar: ${seeds.join(', ')}. '
        'Prospekte laufen ab, bitte eine aktuelle ID verwenden.',
      );
    }

    final result = found.values.toList()
      ..sort((a, b) {
        final byPublisher = a.publisher.name.compareTo(b.publisher.name);
        return byPublisher != 0 ? byPublisher : a.title.compareTo(b.title);
      });
    return result;
  }

  /// Holt die drei Empfehlungslisten zu einem Prospekt und fasst sie zusammen.
  /// Gibt `null` zurueck, wenn die ID nicht mehr abrufbar ist.
  Future<List<AdContent<BrochureSummary>>?> _collectionsFor(
    String brochureId,
    GeoLocation? location,
    String? brochureKey,
  ) async {
    final calls = [
      sidebar(brochureId, location: location, brochureKey: brochureKey),
      related(brochureId, location: location, brochureKey: brochureKey),
      lastPage(brochureId, location: location, brochureKey: brochureKey),
    ];
    final results = await Future.wait(
      calls.map(
        (call) => call.then<BrochureCollections?>(
          (value) => value,
          onError: (Object error) {
            if (error is KaufdaHttpException || error is KaufdaParseException) {
              return null;
            }
            throw error;
          },
        ),
      ),
    );
    if (results.every((e) => e == null)) return null;
    return [
      for (final collections in results)
        if (collections != null) ...collections.all,
    ];
  }

  /// Bonial-Account-ID zur aktuellen Session:
  /// `GET https://www.kaufda.de/api/user/account/id`.
  Future<String> accountId({String? userId}) async {
    final session = await _sessionProvider.session();
    final resolved = userId ?? 'anonymous-${session.userIdent}';
    final uri = portalUri.resolve('api/user/account/id').replace(
      queryParameters: {
        'deliveryChannel': deliveryChannel,
        'userPlatformCategory': userPlatformCategory,
        'userPlatformOs': userPlatformOs,
        'userId': resolved,
      },
    );
    final json = await _getJsonAt(uri);
    final id = asString(json['bonialAccountId']);
    if (id == null) {
      throw KaufdaParseException(
        'Antwort enthielt keine bonialAccountId',
        uri: uri,
      );
    }
    return id;
  }

  /// Prospekt, Seiten, Filiale und Empfehlungen in einem Rutsch.
  Future<BrochureBundle> bundle(
    String brochureId, {
    GeoLocation? location,
    String? brochureKey,
  }) async {
    final results = await Future.wait([
      brochure(brochureId, location: location, brochureKey: brochureKey),
      pages(brochureId, location: location, brochureKey: brochureKey),
      nearestStore(brochureId, location: location, brochureKey: brochureKey),
      related(brochureId, location: location, brochureKey: brochureKey),
      sidebar(brochureId, location: location, brochureKey: brochureKey),
      lastPage(brochureId, location: location, brochureKey: brochureKey),
    ]);
    return BrochureBundle(
      brochure: results[0] as Brochure,
      pages: results[1] as List<BrochurePage>,
      nearestStore: results[2] as Store?,
      related: results[3] as BrochureCollections,
      sidebar: results[4] as BrochureCollections,
      lastPage: results[5] as BrochureCollections,
    );
  }

  Map<String, String> get _platformHeaders => {
        'delivery_channel': deliveryChannel,
        'user_platform_category': userPlatformCategory,
        'user_platform_os': userPlatformOs,
      };

  GeoLocation _requireLocation(GeoLocation? override) {
    final geo = override ?? location;
    if (geo == null) {
      throw ArgumentError(
        'Kein Standort gesetzt: KaufdaClient(location: ...) oder den '
        'Parameter location uebergeben.',
      );
    }
    return geo;
  }

  Map<String, String> _baseQuery(GeoLocation? override, String? keyOverride) {
    final geo = _requireLocation(override);
    return {
      'partner': partner,
      'brochureKey': keyOverride ?? brochureKey,
      'lat': geo.latParam,
      'lng': geo.lngParam,
    };
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> query, {
    Map<String, String> extraHeaders = const {},
  }) {
    final uri = baseUri.resolve(path).replace(queryParameters: query);
    return _getJsonAt(uri, extraHeaders: extraHeaders);
  }

  Future<Map<String, dynamic>> _getJsonAt(
    Uri uri, {
    Map<String, String> extraHeaders = const {},
  }) async {
    var response = await _send(uri, extraHeaders, forceRefresh: false);
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Der Token laeuft nach etwa 30 Minuten ab: einmal erneuern und erneut
      // versuchen, bevor der Fehler nach oben geht.
      response = await _send(uri, extraHeaders, forceRefresh: true);
    }
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw KaufdaHttpException(
        statusCode: response.statusCode,
        uri: uri,
        body: body,
      );
    }
    if (body.trim().isEmpty) return const {};
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw KaufdaParseException(
        'Antwort war kein JSON: ${error.message}',
        uri: uri,
        body: body,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw KaufdaParseException(
        'Erwartet wurde ein JSON-Objekt, geliefert wurde '
        '${decoded.runtimeType}',
        uri: uri,
        body: body,
      );
    }
    return decoded;
  }

  Future<http.Response> _send(
    Uri uri,
    Map<String, String> extraHeaders, {
    required bool forceRefresh,
  }) async {
    final session = await _sessionProvider.session(forceRefresh: forceRefresh);
    final headers = <String, String>{
      'Accept': '*/*',
      'Accept-Language': 'de,en;q=0.9',
      'Bonial-Api-Consumer': apiConsumer,
      'Cookie': session.cookieHeader,
      if (sendBrowserHeaders) ...{
        'User-Agent': userAgent,
        'Origin': portalUri.origin,
        'Referer': '${portalUri.origin}/',
      },
      ...extraHeaders,
    };
    try {
      return await _http.get(uri, headers: headers);
    } on http.ClientException catch (error) {
      throw KaufdaException('Request an $uri fehlgeschlagen: ${error.message}');
    }
  }

  /// Gibt HTTP-Client und Session-Provider frei, sofern der Client sie selbst
  /// erzeugt hat.
  void close() {
    final provider = _sessionProvider;
    if (_ownsSessionProvider && provider is WebSessionProvider) {
      provider.close();
    }
    if (_ownsHttpClient) _http.close();
  }
}

/// Alles, was der Viewer beim Oeffnen eines Prospekts laedt.
class BrochureBundle {
  const BrochureBundle({
    required this.brochure,
    required this.pages,
    required this.related,
    required this.sidebar,
    required this.lastPage,
    this.nearestStore,
  });

  final Brochure brochure;
  final List<BrochurePage> pages;
  final Store? nearestStore;
  final BrochureCollections related;
  final BrochureCollections sidebar;
  final BrochureCollections lastPage;

  /// Alle Angebote aller Seiten.
  List<Offer> get offers => [
        for (final page in pages) ...page.offerContents,
      ];

  Map<String, dynamic> toJson() => {
        'brochure': brochure.toJson(),
        'pages': pages.map((e) => e.toJson()).toList(),
        'nearestStore': nearestStore?.toJson(),
        'related': related.toJson(),
        'sidebar': sidebar.toJson(),
        'lastPage': lastPage.toJson(),
      };

  @override
  String toString() => 'BrochureBundle(${brochure.id}, ${pages.length} Seiten, '
      '${offers.length} Angebote)';
}
