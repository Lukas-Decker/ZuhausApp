import 'package:http/http.dart' as http;
import 'package:kaufda_api/kaufda_api.dart' as kd;

import '../../core/errors/prospect_exception.dart';
import '../../core/models/brochure.dart';
import '../../core/models/geo.dart';
import '../../core/models/offer.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/prospect_source.dart';
import 'kaufda_mapper.dart';

/// Adapter fuer die kaufDA Content-Viewer-API (Bonial).
///
/// Wickelt das eigenstaendige Package `kaufda_api` in die Adapter-Architektur
/// ein. Anders als Tjek und Schwarz laeuft der HTTP-Verkehr nicht ueber den
/// gemeinsamen [ApiClient], weil kaufDA einen eigenen Session-Bootstrap
/// (JWT von www.kaufda.de) samt automatischer Erneuerung braucht, den der
/// [kd.KaufdaClient] bereits vollstaendig kapselt.
///
/// Die Quelle ist strikt ortsgebunden: jeder Endpunkt verlangt Koordinaten.
/// Ohne `near` in der Abfrage und ohne [defaultLocation] liefern die Abrufe
/// deshalb einen [UnsupportedBySource], keinen stillen Rueckfall auf einen
/// fremden Standort.
class KaufdaSource implements ProspectSource {
  KaufdaSource({
    kd.KaufdaClient? client,
    http.Client? httpClient,
    this.defaultLocation,
  })  : _client = client ?? kd.KaufdaClient(httpClient: httpClient),
        _ownsClient = client == null;

  final kd.KaufdaClient _client;
  final bool _ownsClient;

  /// Standardstandort fuer Abfragen ohne eigenes `near`.
  ///
  /// Bewusst veraenderbar: eine App setzt ihn nach, wenn der Nutzer seinen
  /// Standort wechselt, ohne die ganze Verdrahtung neu aufzubauen.
  GeoPoint? defaultLocation;

  @override
  String get id => KaufdaMapper.sourceId;

  @override
  String get displayName => 'kaufDA (Bonial)';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(
        supportsGeoSearch: true,
        supportsOfferSearch: true,
        providesPrices: true,
      );

  final KaufdaMapper _mapper = const KaufdaMapper();

  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async {
    final location = _location(query.near, 'fetchRetailers');
    final brochures = await _guard(
      () => _client.shelfAll(location: location, onlyValid: true),
    );

    // Haendler ergeben sich aus den Prospekten im Umkreis, einen eigenen
    // Haendler-Endpunkt hat die Quelle nicht. Dieselbe Kette kann mehrfach
    // auftauchen, deshalb wird ueber die kanonische ID zusammengefuehrt.
    final byId = <String, Retailer>{};
    for (final brochure in brochures) {
      final retailer = _mapper.retailer(brochure.publisher);
      if (retailer == null) continue;
      byId[retailer.id] = byId[retailer.id]?.mergedWith(retailer) ?? retailer;
    }
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async {
    final location = _location(query.near, 'fetchBrochures');
    final raw = await _guard(
      () => _client.shelfAll(
        location: location,
        onlyValid: !query.includeExpired,
      ),
    );

    final publisherId = query.binding?.nativeId;
    final brochures = <Brochure>[];
    for (final entry in raw) {
      if (publisherId != null && entry.publisher.id != publisherId) continue;
      final brochure = _mapper.brochureFromShelf(entry);
      if (brochure == null) continue;
      brochures.add(brochure);
      if (brochures.length >= query.limit) break;
    }
    return brochures;
  }

  @override
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  }) async {
    final location = _location(_pointFromParams(params), 'fetchBrochure');
    final results = await _guard(
      () => Future.wait<Object>([
        _client.brochure(nativeId, location: location),
        _client.pages(nativeId, location: location),
      ]),
    );
    return _mapper.brochureDetail(
      results[0] as kd.Brochure,
      (results[1] as List).cast<kd.BrochurePage>(),
    );
  }

  @override
  Future<List<Offer>> searchOffers(OfferQuery query) async {
    final location = _location(query.near, 'searchOffers');
    final result = await _guard(
      () => _client.search(query.query, location: location, limit: query.limit),
    );

    // Die Gueltigkeit steht nicht am Angebot, sondern am Prospekt-Treffer
    // derselben Antwort. Ueber die Prospekt-ID zusammengefuehrt.
    final validity = <String, kd.SearchBrochure>{
      for (final brochure in result.brochureContents) brochure.id: brochure,
    };

    // Der Endpunkt filtert selbst nicht nach Haendler, das passiert hier.
    final publisherId = query.binding?.nativeId;
    final offers = <Offer>[];
    for (final entry in result.offers) {
      if (publisherId != null && entry.publisherId != publisherId) continue;
      final parent = validity[entry.parent?.id];
      final offer = _mapper.searchOffer(
        entry,
        validFrom: parent?.validFrom,
        validUntil: parent?.validUntil,
      );
      if (offer != null) offers.add(offer);
    }
    return offers;
  }

  @override
  Future<List<Store>> fetchStores(StoreQuery query) {
    throw UnsupportedBySource(
      'kaufDA liefert keine Filiallisten je Haendler, nur die naechste '
      'Filiale zu einem Prospekt.',
      operation: 'fetchStores',
      sourceId: id,
    );
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }

  kd.GeoLocation _location(GeoPoint? near, String operation) {
    final point = near ?? defaultLocation;
    if (point == null) {
      throw UnsupportedBySource(
        'kaufDA braucht Koordinaten: jeder Endpunkt ist ortsgebunden. '
        'Entweder near uebergeben oder defaultLocation setzen.',
        operation: operation,
        sourceId: id,
      );
    }
    return kd.GeoLocation(lat: point.latitude, lng: point.longitude);
  }

  GeoPoint? _pointFromParams(Map<String, String> params) {
    final lat = double.tryParse(params['lat'] ?? '');
    final lng = double.tryParse(params['lng'] ?? '');
    if (lat == null || lng == null) return null;
    return GeoPoint(lat, lng);
  }

  /// Uebersetzt kaufDA-Fehler in die Fehlerfamilie des Moduls, damit oberhalb
  /// des Adapters keine quellenspezifischen Typen auftauchen.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on kd.KaufdaHttpException catch (error) {
      final status = error.statusCode;
      if (status == 404) {
        throw NotFound(error.message, sourceId: id);
      }
      if (status == 401 || status == 403) {
        throw AccessDenied(error.message, statusCode: status, sourceId: id);
      }
      if (status == 429) {
        throw RateLimited(error.message, sourceId: id);
      }
      throw SourceUnavailable(error.message, statusCode: status, sourceId: id);
    } on kd.KaufdaParseException catch (error) {
      throw ResponseParseFailure(error.message, sourceId: id, cause: error);
    } on kd.KaufdaSessionException catch (error) {
      throw SourceUnavailable(error.message, sourceId: id);
    } on kd.KaufdaException catch (error) {
      throw NetworkFailure(error.message, sourceId: id, cause: error);
    } on http.ClientException catch (error) {
      throw NetworkFailure(error.message, sourceId: id, cause: error);
    }
  }
}
