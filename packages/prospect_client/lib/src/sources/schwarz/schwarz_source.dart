import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/models/brochure.dart';
import '../../core/models/geo.dart';
import '../../core/models/offer.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/prospect_source.dart';
import '../../core/source/source_credentials.dart';
import '../tjek/tjek_mapper.dart' show ParseReport;
import 'kaufland_store_directory.dart';
import 'schwarz_api.dart';
import 'schwarz_mapper.dart';

/// Adapter fuer die Prospekt-API der Schwarz-Gruppe.
///
/// Deckt Lidl und Kaufland ab, beide erstanbieterig. Laut Messung
/// (RESEARCH.md, Abschnitt 3b) liefert Kaufland 422 Produkte pro Prospekt
/// inklusive Lebensmitteln, allerdings ohne Preise. Lidl liefert 162 Produkte
/// mit Preisen, aber ausschliesslich Non-Food.
class SchwarzSource implements ProspectSource {
  SchwarzSource(
    ApiClient client, {
    Uri? baseUrl,
    SourceCredentials credentials = const SourceCredentials.none(),
  })  : _api = SchwarzApi(client, baseUrl: baseUrl),
        _kauflandStores = KauflandStoreDirectory(client),
        _credentials = credentials;

  final SchwarzApi _api;
  final SchwarzMapper _mapper = const SchwarzMapper();

  /// Loest Koordinaten auf eine Kaufland-Filialnummer auf, die zugleich der
  /// Regionscode der Prospekt-API ist.
  final KauflandStoreDirectory _kauflandStores;

  final SourceCredentials _credentials;

  /// True, wenn ein Schluessel fuer die Filial-API der Schwarz-Gruppe
  /// hinterlegt ist. Nur damit laesst sich auch fuer Lidl eine Region
  /// bestimmen.
  bool get canResolveLidlRegion =>
      _credentials.has(CredentialKey.schwarzStoresApiKey);

  ParseReport get lastReport => _lastReport;
  ParseReport _lastReport = ParseReport();

  @override
  String get id => SchwarzApi.sourceId;

  @override
  String get displayName => 'Schwarz Leaflets (Lidl, Kaufland)';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
        // Die Quelle kennt keine Koordinaten, nur Regionscodes. Umkreissuche,
        // Angebotssuche und Filialdaten sind hier schlicht nicht vorhanden.
        // Die Prospekt-API selbst kennt keine Koordinaten, nur Regionscodes.
        // Fuer Kaufland laesst sich ein Ort trotzdem aufloesen, weil dessen
        // oeffentliche Filialliste Objektnummern mit Koordinaten fuehrt und
        // die Objektnummer der Regionscode ist.
        supportsGeoSearch: true,
        supportsOfferSearch: false,
        supportsStores: true,
        providesPrices: true,
        providesPdf: true,
        requiresRegion: true,
      );

  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async =>
      // Die Mandantenliste ist fest. Ein Abruf waere nicht moeglich, weil die
      // API keinen Endpunkt zum Auflisten der Mandanten hat.
      SchwarzApi.clients.map(_mapper.retailer).toList();

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async {
    final report = ParseReport();
    final clients = _clientsFor(query.binding);
    if (clients.isEmpty) return const [];

    final now = DateTime.now().toUtc();
    final brochures = <Brochure>[];

    for (final client in clients) {
      final region = await _resolveRegion(client, query);
      final entries = await _tolerate(
        () => _api.overview(client, region: region),
        const <Map<String, Object?>>[],
      );

      for (final entry in entries) {
        final brochure = _mapper.overviewEntry(entry, client, report);
        if (brochure == null) continue;
        if (!query.includeExpired && brochure.isExpiredAt(now)) continue;

        // Ohne aufgeloeste Region wuerde Lidl rund 40 Regionalvarianten
        // desselben Wochenprospekts liefern. Ein Nutzer sieht dann fast nur
        // Angebote, die bei ihm nicht gelten. Deshalb bleiben in diesem Fall
        // nur bundesweit gueltige Prospekte uebrig.
        if (region == null &&
            !query.includeOutOfArea &&
            brochure.coverage.needsLocation) {
          continue;
        }

        brochures.add(brochure);
        if (brochures.length >= query.limit) break;
      }
    }

    _lastReport = report;
    return brochures;
  }

  /// Ermittelt den Regionscode fuer einen Mandanten.
  ///
  /// Reihenfolge: ausdruecklich gesetzter Code, dann Aufloesung aus
  /// Koordinaten, dann keiner.
  ///
  /// Bewusst **kein** Rueckfall auf einen festen Standardwert. Ein solcher
  /// Standard war vorher eingebaut (`3000` fuer Kaufland) und lieferte allen
  /// Nutzern ausserhalb dieser einen Region stillschweigend die falschen
  /// Prospekte. Keine Region ist ehrlicher als eine falsche.
  Future<String?> _resolveRegion(
    SchwarzClient client,
    BrochureQuery query,
  ) async {
    final explicit = query.binding?.params['region_id'];
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final near = query.near;
    if (near == null) return null;

    return _regionForLocation(client, near);
  }

  Future<String?> _regionForLocation(SchwarzClient client, GeoPoint near) async {
    // Kaufland: die oeffentliche Filialliste von filiale.kaufland.de nennt
    // Objektnummern, und die sind zugleich der Regionscode. Kein Schluessel
    // noetig.
    if (client.retailerId == 'kaufland') {
      return _tolerate(() => _kauflandStores.regionFor(near), null);
    }

    // Lidl: der einzige bekannte Weg fuehrt ueber die Filial-API der
    // Schwarz-Gruppe unter live.api.schwarz, die einen Schluessel verlangt.
    // Ohne hinterlegten Schluessel bleibt es bei bundesweiten Prospekten. Das
    // Modul liest keinen Schluessel aus fremden Web-Bundles aus.
    if (client.retailerId == 'lidl' && canResolveLidlRegion) {
      return _tolerate(
        () => _lidlRegionFor(near),
        null,
      );
    }

    return null;
  }

  /// Regionsaufloesung fuer Lidl ueber die Filial-API der Schwarz-Gruppe.
  ///
  /// Noch nicht ausimplementiert, weil die Antwortstruktur ohne gueltigen
  /// Schluessel nicht ueberpruefbar war und geratene Feldnamen im Betrieb
  /// stillschweigend falsche Regionen liefern wuerden. Der Schluessel wird
  /// bereits korrekt aus der Konfiguration gelesen und durchgereicht, sobald
  /// die Struktur einmal an einer echten Antwort verifiziert ist, gehoert das
  /// Mapping hierher.
  Future<String?> _lidlRegionFor(GeoPoint near) async => null;

  @override
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  }) async {
    final split = SchwarzMapper.splitNativeId(nativeId);
    if (split == null) {
      throw NotFound(
        'Ungueltige Prospekt-ID "$nativeId". '
        'Erwartet: <haendler>${SchwarzMapper.nativeIdSeparator}<prospektId>',
        sourceId: id,
      );
    }

    final client = SchwarzApi.clientFor(split.$1);
    if (client == null) {
      throw NotFound(
        'Haendler "${split.$1}" wird von dieser Quelle nicht bedient. '
        'Verfuegbar: ${SchwarzApi.clients.map((c) => c.retailerId).join(', ')}',
        sourceId: id,
      );
    }

    final report = ParseReport();
    final region = params['region_id'];
    final json = await _api.flyer(client, split.$2, region: region);
    _lastReport = report;
    return _mapper.flyer(json, client, report);
  }

  /// Filialen, in denen ein Prospekt gilt.
  ///
  /// Bei Kaufland aufloesbar, weil der Regionscode die Objektnummer der
  /// Filiale ist. Bei Lidl nicht, dort sind es Vertriebsgebietscodes ohne
  /// oeffentlich zugaengliche Zuordnung zu Filialen.
  Future<List<Store>> storesForBrochure(Brochure brochure) async {
    if (brochure.retailerId != 'kaufland' || brochure.regionCodes.isEmpty) {
      return const [];
    }
    final all = await _tolerate(_kauflandStores.stores, const <KauflandStore>[]);
    final wanted = brochure.regionCodes.toSet();
    return all
        .where((store) => wanted.contains(store.regionCode))
        .map((store) => store.toStore())
        .toList();
  }

  @override
  Future<List<Offer>> searchOffers(OfferQuery query) async =>
      throw UnsupportedBySource(
        'Die Schwarz-API hat keinen Suchendpunkt. Die Suche im Prospektviewer '
        'laeuft rein clientseitig ueber bereits geladene Daten.',
        operation: 'searchOffers',
        sourceId: id,
      );

  @override
  Future<List<Store>> fetchStores(StoreQuery query) async {
    final clients = _clientsFor(query.binding);
    if (clients.length != 1 || clients.single.retailerId != 'kaufland') {
      throw UnsupportedBySource(
        'Filialdaten liegen ueber diese Quelle nur fuer Kaufland vor. Fuer '
        'Lidl fuehrt der einzige bekannte Weg ueber eine API mit Zugangsschutz.',
        operation: 'fetchStores',
        sourceId: id,
      );
    }

    final all = await _kauflandStores.stores();
    final near = query.near;

    var stores = all.map((store) => store.toStore()).toList();
    if (near != null) {
      stores = stores
          .where((store) =>
              store.location != null &&
              store.location!.distanceTo(near) <= query.radiusMeters)
          .toList()
        ..sort((a, b) => a.location!
            .distanceTo(near)
            .compareTo(b.location!.distanceTo(near)));
    }

    return stores.length > query.limit ? stores.sublist(0, query.limit) : stores;
  }

  @override
  void close() {}

  /// Welche Mandanten fuer eine Abfrage relevant sind.
  ///
  /// Das Binding traegt als `nativeId` die `client_locale`. Ohne Binding
  /// werden alle Mandanten abgefragt.
  List<SchwarzClient> _clientsFor(SourceBinding? binding) {
    if (binding == null) return SchwarzApi.clients;
    for (final client in SchwarzApi.clients) {
      if (client.clientLocale == binding.nativeId ||
          client.retailerId == binding.nativeId) {
        return [client];
      }
    }
    return const [];
  }

  Future<T> _tolerate<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } on ProspectException {
      return fallback;
    }
  }
}
