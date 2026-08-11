import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/models/brochure.dart';
import '../../core/models/brochure_page.dart';
import '../../core/models/geo.dart';
import '../../core/models/offer.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/prospect_source.dart';
import 'tjek_api.dart';
import 'tjek_mapper.dart';

/// Adapter fuer die Tjek-API.
///
/// Deckt laut Messung (RESEARCH.md, Abschnitt 2) in Deutschland ab: Netto,
/// Penny, Kaufland und CITTI mit vollstaendigen Preisdaten, ALDI Nord,
/// ALDI Sued, HIT und famila als reine Bildprospekte.
class TjekSource implements ProspectSource {
  TjekSource(ApiClient client, {Uri? baseUrl, this.countryCode = 'DE'})
      : _api = TjekApi(client, baseUrl: baseUrl);

  /// Laendercode, auf den Haendler eingeschraenkt werden.
  ///
  /// Ohne diesen Filter ist die Quelle im deutschen Kontext unbrauchbar: die
  /// Haendlerliste ist ueberwiegend daenisch, und Ketten wie Lidl oder Netto
  /// existieren dort mit eigenen daenischen Eintraegen. Die wuerden sonst auf
  /// dieselbe kanonische ID abgebildet und die App zeigte deutschen Nutzern
  /// daenische Prospekte. Null hebt den Filter auf.
  final String? countryCode;

  final TjekApi _api;
  final TjekMapper _mapper = const TjekMapper();

  /// Letzter Mapping-Bericht, fuer `prospect_client debug tjek`.
  ParseReport get lastReport => _lastReport;
  ParseReport _lastReport = ParseReport();

  @override
  String get id => TjekApi.sourceId;

  @override
  String get displayName => 'Tjek (squid-api)';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
        supportsGeoSearch: true,
        supportsOfferSearch: true,
        supportsStores: true,
        providesPrices: true,
        providesPdf: true,
      );

  /// Ankerpunkte fuer die Haendlersuche ohne Ortsangabe.
  ///
  /// Notwendig wegen einer harten Eigenheit der Quelle: `/v2/dealers` deckelt
  /// bei rund 300 Eintraegen und liefert ueberwiegend daenische Haendler. Von
  /// den deutschen Ketten tauchen dort nur vier auf. Vollstaendig wird die
  /// Liste nur ueber Prospekte im Umkreis, deshalb wird ohne Ortsangabe an
  /// diesen Punkten gesucht. Sie decken Nord, Ost, Sued, West und Mitte ab.
  /// Nach dem ersten Durchlauf beantwortet der Cache die Abrufe.
  static const List<GeoPoint> discoveryAnchors = [
    GeoPoint(53.55, 9.99), // Hamburg
    GeoPoint(52.52, 13.41), // Berlin
    GeoPoint(50.94, 6.96), // Koeln
    GeoPoint(48.14, 11.58), // Muenchen
    GeoPoint(50.11, 8.68), // Frankfurt
  ];

  /// Haendler dieser Quelle.
  ///
  /// Kombiniert zwei Wege, weil keiner allein vollstaendig ist:
  ///
  /// 1. Prospekte im Umkreis. Findet die meisten Ketten, uebersieht aber
  ///    filialgebundene Prospekte. Kaufland setzt `all_stores: false`, seine
  ///    Prospekte tauchen deshalb in einer reinen Umkreissuche nicht auf.
  /// 2. Die Haendlerliste. Deckelt bei rund 300 Eintraegen und ist daenisch
  ///    dominiert, enthaelt aber genau die filialgebundenen Faelle.
  ///
  /// Die Vereinigung beider Wege deckt beides ab.
  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async {
    final report = ParseReport();
    final byId = <String, Retailer>{};

    final anchors = query.near != null ? [query.near!] : discoveryAnchors;
    final radius = query.near != null ? query.radiusMeters : 80000;

    void add(Retailer? retailer) {
      if (retailer == null || !_matchesCountry(retailer)) return;
      byId[retailer.id] = byId[retailer.id]?.mergedWith(retailer) ?? retailer;
    }

    for (final anchor in anchors) {
      // Paginiert, weil eine einzelne Seite mit 100 Katalogen in
      // Ballungsraeumen nicht alle Haendler enthaelt. Kaufland faellt sonst
      // durchs Raster, obwohl die Quelle es kennt.
      final catalogs = await _tolerate(
        () => _paginate(
          (offset) => _api.catalogs(
            near: anchor,
            radiusMeters: radius,
            offset: offset,
          ),
          maxItems: 300,
        ),
        const <Map<String, Object?>>[],
      );

      for (final catalog in catalogs) {
        final dealer = catalog['dealer'];
        final branding = catalog['branding'];
        final source = dealer is Map<String, Object?>
            ? dealer
            : (branding is Map<String, Object?> ? branding : null);
        if (source == null) continue;
        // Das eingebettete branding-Objekt hat keine id, die steht am Katalog.
        final nativeId = source['id'] ?? catalog['dealer_id'];
        if (nativeId is! String) continue;
        add(_mapper.retailer({...source, 'id': nativeId}, report));
      }
    }

    final dealers = await _tolerate(
      () => _paginate((offset) => _api.dealers(offset: offset), maxItems: 300),
      const <Map<String, Object?>>[],
    );
    for (final dealer in dealers) {
      add(_mapper.retailer(dealer, report));
    }

    _lastReport = report;
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Das eingebettete `branding`-Objekt hat kein Land. In dem Fall wird der
  /// Haendler durchgelassen, weil er ueber eine Umkreissuche im Zielland
  /// gefunden wurde und die Herkunft damit hinreichend belegt ist.
  bool _matchesCountry(Retailer retailer) =>
      countryCode == null || retailer.countryCode == countryCode;

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async {
    final report = ParseReport();
    final dealerId = query.binding?.nativeId;

    final raw = await _paginate(
      (offset) => _api.catalogs(
        dealerId: dealerId,
        near: query.near,
        radiusMeters: query.radiusMeters,
        offset: offset,
      ),
      maxItems: query.limit,
    );

    final now = DateTime.now().toUtc();
    final brochures = <Brochure>[];
    for (final entry in raw) {
      final brochure = _mapper.brochure(entry, report);
      if (brochure == null) continue;
      if (!query.includeExpired && brochure.isExpiredAt(now)) continue;

      // Ohne Ortsbezug filtert die API nicht nach Filiale. Fuer HIT kaemen
      // dann ueber 50 filialspezifische Wochenprospekte quer durch Deutschland
      // in einer Liste. Mit Ortsbezug hat die API bereits gefiltert, dann
      // duerfen filialgebundene Prospekte bleiben.
      if (query.near == null &&
          !query.includeOutOfArea &&
          brochure.coverage.needsLocation) {
        continue;
      }

      brochures.add(brochure);
    }
    _lastReport = report;
    return brochures;
  }

  /// Filialen, in denen ein Prospekt gilt.
  Future<List<Store>> storesForBrochure(Brochure brochure) async {
    final report = ParseReport();
    final raw = await _tolerate(
      () => _api.catalogStores(brochure.id.nativeId),
      const <Map<String, Object?>>[],
    );
    final stores = <Store>[];
    for (final entry in raw) {
      final store = _mapper.store(entry, brochure.retailerId, report);
      if (store != null) stores.add(store);
    }
    _lastReport = report;
    return stores;
  }

  @override
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  }) async {
    final report = ParseReport();

    final raw = await _api.catalog(nativeId);
    if (raw == null) {
      throw NotFound('Prospekt $nativeId existiert bei Tjek nicht', sourceId: id);
    }
    final base = _mapper.brochure(raw, report);
    if (base == null) {
      throw ResponseParseFailure(
        'Prospekt $nativeId konnte nicht gelesen werden',
        sourceId: id,
      );
    }

    // Seiten, Hotspots und Angebote sind drei getrennte Endpunkte. Faellt einer
    // aus, wird der Prospekt trotzdem mit dem Rest geliefert. Teilweise
    // fehlende Daten sind ein gueltiger Zustand, kein Abbruchgrund.
    const empty = <Map<String, Object?>>[];
    final pagesRaw = await _tolerate(() => _api.catalogPages(nativeId), empty);
    final hotspotsRaw =
        await _tolerate(() => _api.catalogHotspots(nativeId), empty);
    final offersRaw = base.contentLevel.hasProducts
        ? await _tolerate(
            () => _paginate(
              (offset) => _api.offers(catalogId: nativeId, offset: offset),
              maxItems: 500,
            ),
            empty,
          )
        : empty;

    final hotspots = _mapper.hotspotsByPage(hotspotsRaw);
    final List<BrochurePage> pages = _mapper.pages(pagesRaw, hotspots);

    final offers = <Offer>[];
    for (final entry in offersRaw) {
      final offer = _mapper.offer(entry, report);
      if (offer != null) offers.add(offer);
    }

    _lastReport = report;
    return base.copyWith(
      pages: pages,
      offers: offers,
      pageCount: base.pageCount == 0 ? pages.length : base.pageCount,
    );
  }

  @override
  Future<List<Offer>> searchOffers(OfferQuery query) async {
    // Ohne Geobezug sucht die API ueber alle Laender. Die Treffer sind dann
    // ueberwiegend daenisch, mit Preisen in DKK. Fuer einen deutschen Nutzer
    // ist das nicht nur nutzlos, sondern irrefuehrend, deshalb lieber nichts
    // liefern als das Falsche.
    if (query.near == null) {
      throw UnsupportedBySource(
        'Die Angebotssuche braucht Koordinaten. Ohne sie sucht Tjek ueber alle '
        'Laender und liefert ueberwiegend daenische Treffer.',
        operation: 'searchOffers',
        sourceId: id,
      );
    }

    final report = ParseReport();
    final raw = await _api.searchOffers(
      query: query.query,
      dealerId: query.binding?.nativeId,
      near: query.near,
      radiusMeters: query.radiusMeters,
      limit: query.limit,
    );
    final offers = <Offer>[];
    for (final entry in raw) {
      final offer = _mapper.offer(entry, report);
      if (offer != null) offers.add(offer);
    }
    _lastReport = report;
    return offers;
  }

  @override
  Future<List<Store>> fetchStores(StoreQuery query) async {
    final report = ParseReport();
    final raw = await _api.stores(
      dealerId: query.binding.nativeId,
      near: query.near,
      radiusMeters: query.radiusMeters,
      limit: query.limit,
    );
    final retailerId = _retailerIdFor(query.binding);
    final stores = <Store>[];
    for (final entry in raw) {
      final store = _mapper.store(entry, retailerId, report);
      if (store != null) stores.add(store);
    }
    _lastReport = report;
    return stores;
  }

  @override
  void close() {}

  String _retailerIdFor(SourceBinding binding) =>
      binding.params['retailerId'] ?? binding.nativeId;

  /// Holt so lange Seiten, bis [maxItems] erreicht sind oder die Quelle eine
  /// unvollstaendige Seite liefert.
  Future<List<Map<String, Object?>>> _paginate(
    Future<List<Map<String, Object?>>> Function(int offset) fetch, {
    required int maxItems,
  }) async {
    final all = <Map<String, Object?>>[];
    var offset = 0;
    while (all.length < maxItems) {
      final page = await fetch(offset);
      if (page.isEmpty) break;
      all.addAll(page);
      if (page.length < TjekApi.maxPageSize) break;
      offset += page.length;
    }
    return all.length > maxItems ? all.sublist(0, maxItems) : all;
  }

  /// Fuehrt einen Teilabruf aus und liefert bei einem erwartbaren Fehler den
  /// Ersatzwert. Nicht wiederholbare Fehler wie AccessDenied werden ebenfalls
  /// geschluckt, weil sie nur diesen Teil betreffen.
  Future<T> _tolerate<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } on ProspectException {
      return fallback;
    }
  }
}
