import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/models/brochure.dart';
import '../../core/models/offer.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/prospect_source.dart';
import '../../core/source/source_credentials.dart';
import '../tjek/tjek_mapper.dart' show ParseReport;
import 'marktguru_api.dart';
import 'marktguru_mapper.dart';

/// Adapter fuer Marktguru.
///
/// Die einzige angebundene Quelle, die REWE, EDEKA, dm und Rossmann fuehrt,
/// also genau die Haendler, die ueber Tjek und Schwarz nicht erreichbar sind.
///
/// Wird nur registriert, wenn Zugangsdaten vorliegen. Ohne sie antwortet die
/// API mit HTTP 401, und eine Quelle, die bei jedem Aufruf scheitert, ist
/// schlechter als eine, die gar nicht erst auftaucht.
class MarktguruSource implements ProspectSource {
  MarktguruSource(
    ApiClient client, {
    required String apiKey,
    required String clientKey,
    this.defaultZipCode = '10115',
    Uri? baseUrl,
    Uri? cdnUrl,
  })  : _api = MarktguruApi(
          client,
          apiKey: apiKey,
          clientKey: clientKey,
          baseUrl: baseUrl,
          cdnUrl: cdnUrl,
        ),
        _mapper = MarktguruMapper(
          MarktguruApi(
            client,
            apiKey: apiKey,
            clientKey: clientKey,
            baseUrl: baseUrl,
            cdnUrl: cdnUrl,
          ),
        );

  /// Erzeugt den Adapter, falls die noetigen Zugangsdaten vorliegen.
  ///
  /// Gibt null zurueck, wenn etwas fehlt. Welche Variablen fehlen, sagt
  /// [SourceCredentials.missingFor].
  static MarktguruSource? maybe(
    ApiClient client,
    SourceCredentials credentials, {
    String defaultZipCode = '10115',
  }) {
    if (!credentials.hasAll(MarktguruApi.requiredCredentials)) return null;
    return MarktguruSource(
      client,
      apiKey: credentials[CredentialKey.marktguruApiKey]!,
      clientKey: credentials[CredentialKey.marktguruClientKey]!,
      defaultZipCode: defaultZipCode,
    );
  }

  final MarktguruApi _api;
  final MarktguruMapper _mapper;

  /// Marktguru verlangt bei jeder Abfrage eine Postleitzahl und kennt keine
  /// Koordinaten. Ohne Ortsangabe wird dieser Wert genutzt.
  final String defaultZipCode;

  ParseReport get lastReport => _lastReport;
  ParseReport _lastReport = ParseReport();

  @override
  String get id => MarktguruApi.sourceId;

  @override
  String get displayName => 'Marktguru';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
        // Die API kennt ausschliesslich Postleitzahlen. Koordinaten liessen
        // sich nur ueber einen Geocoding-Dienst umrechnen, den dieses Modul
        // bewusst nicht mitbringt. Deshalb hier ehrlich false.
        supportsGeoSearch: false,
        supportsPostalCode: true,
        supportsOfferSearch: true,
        supportsStores: true,
        providesPrices: true,
        providesPdf: false,
      );

  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async {
    final report = ParseReport();
    final raw = await _api.searchRetailers();
    final byId = <String, Retailer>{};
    for (final entry in raw) {
      final retailer = _mapper.retailer(entry, report);
      if (retailer == null) continue;
      byId[retailer.id] = byId[retailer.id]?.mergedWith(retailer) ?? retailer;
    }
    _lastReport = report;
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async {
    final report = ParseReport();
    final raw = await _api.searchLeaflets(
      zipCode: _zipFor(query.postalCode),
      retailerId: query.binding?.nativeId,
      limit: query.limit,
    );

    final now = DateTime.now().toUtc();
    final brochures = <Brochure>[];
    for (final entry in raw) {
      // Die Treffer stecken je nach Endpunkt direkt oder unter "flight".
      final flight = entry['flight'];
      final source = flight is Map<String, Object?> ? flight : entry;

      final brochure = _mapper.brochure(source, report);
      if (brochure == null) continue;
      if (!query.includeExpired && brochure.isExpiredAt(now)) continue;

      // Alle Treffer gelten fuer die abgefragte Postleitzahl. Ohne Ortsangabe
      // gilt der Standardwert, und dessen Prospekte sind fuer andere Nutzer
      // bedeutungslos. Deshalb entfaellt die Liste dann, statt sie als
      // allgemeingueltig auszugeben.
      if (query.postalCode == null &&
          !query.includeOutOfArea &&
          brochure.coverage.needsLocation) {
        continue;
      }

      brochures.add(brochure);
    }
    _lastReport = report;
    return brochures;
  }

  @override
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  }) async {
    final report = ParseReport();
    final raw = await _api.leaflet(nativeId);
    if (raw == null) {
      throw NotFound(
        'Prospekt $nativeId existiert bei Marktguru nicht',
        sourceId: id,
      );
    }

    final base = _mapper.brochure(raw, report);
    if (base == null) {
      throw ResponseParseFailure(
        'Prospekt $nativeId konnte nicht gelesen werden',
        sourceId: id,
      );
    }

    // Angebote liegen bei Marktguru nicht im Prospekt, sie werden getrennt
    // abgefragt und ueber leafletFlightId zugeordnet.
    final offersRaw = await _tolerate(
      () => _api.searchOffers(
        zipCode: params['zipCode'] ?? defaultZipCode,
        limit: 200,
      ),
      const <Map<String, Object?>>[],
    );

    final offers = <Offer>[];
    for (final entry in offersRaw) {
      if (entry.intAtSafe('leafletFlightId')?.toString() != nativeId) continue;
      final offer = _mapper.offer(entry, report);
      if (offer != null) offers.add(offer);
    }

    _lastReport = report;
    return base.copyWith(offers: offers);
  }

  @override
  Future<List<Offer>> searchOffers(OfferQuery query) async {
    final report = ParseReport();
    final raw = await _api.searchOffers(
      zipCode: _zipFor(query.postalCode),
      query: query.query,
      retailerId: query.binding?.nativeId,
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
      zipCode: _zipFor(query.postalCode),
      retailerId: query.binding.nativeId,
      limit: query.limit,
    );
    final retailerId = query.binding.params['retailerId'] ?? query.binding.nativeId;
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

  /// Marktguru kennt nur Postleitzahlen, keine Koordinaten.
  ///
  /// Eine Umrechnung braeuchte einen Geocoding-Dienst, den dieses Modul
  /// bewusst nicht mitbringt. Wer ortsgenau sucht, gibt die Postleitzahl
  /// deshalb direkt mit. Ohne Angabe gilt [defaultZipCode], und die damit
  /// gefundenen Prospekte werden ohne `includeOutOfArea` ausgefiltert, weil
  /// sie fuer andere Orte bedeutungslos waeren.
  String _zipFor(String? postalCode) =>
      postalCode != null && postalCode.isNotEmpty ? postalCode : defaultZipCode;

  Future<T> _tolerate<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } on ProspectException {
      return fallback;
    }
  }
}

extension on Map<String, Object?> {
  int? intAtSafe(String key) {
    final value = this[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
