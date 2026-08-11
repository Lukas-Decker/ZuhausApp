import '../../sources/schwarz/schwarz_source.dart';
import '../../sources/tjek/tjek_source.dart';
import '../cache/cache_store.dart';
import '../errors/prospect_exception.dart';
import '../errors/source_result.dart';
import '../http/api_client.dart';
import '../models/brochure.dart';
import '../models/geo.dart';
import '../models/offer.dart';
import '../models/retailer.dart';
import '../models/store.dart';
import '../source/prospect_source.dart';
import 'prospect_repository.dart';

/// Standardimplementierung: fragt alle registrierten Adapter, fuehrt deren
/// Ergebnisse zusammen und sammelt Fehler ein.
class DefaultProspectRepository
    with MultiSourceCollector
    implements ProspectRepository {
  DefaultProspectRepository({
    required List<ProspectSource> sources,
    required CacheStore cache,
    ApiClient? client,
  })  : _sources = List.unmodifiable(sources),
        _cache = cache,
        _client = client;

  final List<ProspectSource> _sources;
  final CacheStore _cache;
  final ApiClient? _client;

  /// Zwischenspeicher der aufgeloesten Haendler, damit `getBrochures` fuer
  /// einen Haendler nicht bei jedem Aufruf erneut alle Quellen nach ihren
  /// Haendlerlisten fragen muss.
  final Map<String, Retailer> _retailerIndex = {};
  bool _indexLoaded = false;

  @override
  List<ProspectSource> get sources => _sources;

  @override
  Future<SourceResult<List<Retailer>>> getRetailers({
    GeoPoint? near,
    int radiusMeters = 50000,
  }) async {
    final query = RetailerQuery(near: near, radiusMeters: radiusMeters);
    final result = await collect<Retailer>(
      _sources,
      (source) => source.fetchRetailers(query),
    );

    // Derselbe Haendler kann aus mehreren Quellen kommen. Kaufland ist der
    // reale Fall: einmal ueber Tjek, einmal ueber Schwarz. Beide Bindings
    // gehoeren an denselben Retailer, sonst steht er zweimal in der App.
    final merged = <String, Retailer>{};
    for (final retailer in result.data) {
      merged[retailer.id] =
          merged[retailer.id]?.mergedWith(retailer) ?? retailer;
    }

    _retailerIndex.addAll(merged);
    _indexLoaded = true;

    final list = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SourceResult(
      data: list,
      errors: result.errors,
      warnings: result.warnings,
      isStale: result.isStale,
    );
  }

  @override
  Future<Retailer?> getRetailer(String retailerId, {GeoPoint? near}) async {
    final cached = _retailerIndex[retailerId];
    if (cached != null) return cached;
    if (!_indexLoaded || near != null) {
      await getRetailers(near: near);
    }
    return _retailerIndex[retailerId];
  }

  @override
  Future<SourceResult<List<Brochure>>> getBrochures({
    String? retailerId,
    GeoPoint? near,
    String? postalCode,
    int radiusMeters = 50000,
    bool includeExpired = false,
    bool includeOutOfArea = false,
    int limit = 100,
  }) async {
    final retailer = retailerId == null
        ? null
        : await getRetailer(retailerId, near: near);

    if (retailerId != null && retailer == null) {
      return SourceResult(
        data: const [],
        errors: [NotFound('Haendler "$retailerId" ist keiner Quelle bekannt')],
      );
    }

    final result = await collect<Brochure>(
      _sources,
      (source) => source.fetchBrochures(
        BrochureQuery(
          binding: retailer?.bindingFor(source.id),
          near: near,
          postalCode: postalCode,
          radiusMeters: radiusMeters,
          includeExpired: includeExpired,
          includeOutOfArea: includeOutOfArea,
          limit: limit,
        ),
      ),
      // Wenn nach einem Haendler gefragt wurde, nur die Quellen fragen, die
      // ihn ueberhaupt kennen. Sonst liefert eine Quelle ungefiltert alles.
      filter: retailer == null
          ? null
          : (source) => retailer.bindingFor(source.id) != null,
      sort: _byValidityDescending,
    );

    // Ohne Ort ist die Liste bewusst unvollstaendig. Das muss sichtbar sein,
    // sonst haelt die App eine gefilterte Liste fuer die ganze Wahrheit.
    if (near == null && postalCode == null && !includeOutOfArea) {
      return SourceResult(
        data: result.data,
        errors: result.errors,
        isStale: result.isStale,
        warnings: [
          ...result.warnings,
          'Ohne Ortsangabe werden nur bundesweit gueltige Prospekte geliefert. '
              'Filialgebundene und regionale Prospekte brauchen Koordinaten (near) '
              'oder eine Postleitzahl (postalCode).',
        ],
      );
    }

    return result;
  }

  @override
  Future<SourceResult<List<Store>>> getBrochureStores(Brochure brochure) async {
    if (brochure.coverage == BrochureCoverage.national) {
      return const SourceResult(
        data: [],
        warnings: ['Prospekt gilt bundesweit, eine Filialliste sagt nichts aus'],
      );
    }

    final source = _sourceById(brochure.sourceId);
    return switch (source) {
      final TjekSource s => _guarded(() => s.storesForBrochure(brochure)),
      final SchwarzSource s => _guarded(() => s.storesForBrochure(brochure)),
      _ => SourceResult(
          data: const [],
          errors: [
            ConfigurationError(
              'Quelle "${brochure.sourceId}" liefert keine Filialzuordnung',
            ),
          ],
        ),
    };
  }

  Future<SourceResult<List<Store>>> _guarded(
    Future<List<Store>> Function() action,
  ) async {
    try {
      return SourceResult.ok(await action());
    } on ProspectException catch (e) {
      return SourceResult(data: const [], errors: [e]);
    }
  }

  @override
  Future<Brochure> getBrochure(BrochureId id) async {
    final source = _sourceById(id.sourceId);
    if (source == null) {
      throw ConfigurationError(
        'Quelle "${id.sourceId}" ist nicht registriert. '
        'Verfuegbar: ${_sources.map((s) => s.id).join(', ')}',
      );
    }

    // Regionsabhaengige Quellen brauchen den Parameter aus dem Binding.
    final params = <String, String>{};
    if (source.capabilities.requiresRegion) {
      for (final retailer in _retailerIndex.values) {
        final binding = retailer.bindingFor(source.id);
        if (binding != null && binding.params.isNotEmpty) {
          params.addAll(binding.params);
          break;
        }
      }
    }

    return source.fetchBrochure(id.nativeId, params: params);
  }

  @override
  Future<SourceResult<List<Offer>>> searchOffers(
    String query, {
    String? retailerId,
    GeoPoint? near,
    String? postalCode,
    int radiusMeters = 50000,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return const SourceResult(data: [], warnings: ['Leere Suchanfrage']);
    }

    if (near == null && postalCode == null) {
      return const SourceResult(
        data: [],
        warnings: [
          'Die Angebotssuche braucht einen Ort. Ohne Koordinaten (near) oder '
              'Postleitzahl (postalCode) laesst sich nicht bestimmen, welche '
              'Angebote ueberhaupt gelten.',
        ],
      );
    }

    final retailer =
        retailerId == null ? null : await getRetailer(retailerId, near: near);

    return collect<Offer>(
      _sources,
      (source) => source.searchOffers(
        OfferQuery(
          query: query,
          binding: retailer?.bindingFor(source.id),
          near: near,
          postalCode: postalCode,
          radiusMeters: radiusMeters,
          limit: limit,
        ),
      ),
      filter: (source) =>
          source.capabilities.supportsOfferSearch &&
          (retailer == null || retailer.bindingFor(source.id) != null),
    );
  }

  @override
  Future<SourceResult<List<Store>>> getStores(
    String retailerId, {
    GeoPoint? near,
    String? postalCode,
    int radiusMeters = 50000,
  }) async {
    final retailer = await getRetailer(retailerId, near: near);
    if (retailer == null) {
      return SourceResult(
        data: const [],
        errors: [NotFound('Haendler "$retailerId" ist keiner Quelle bekannt')],
      );
    }

    return collect<Store>(
      _sources,
      (source) => source.fetchStores(
        StoreQuery(
          binding: SourceBinding(
            sourceId: source.id,
            nativeId: retailer.bindingFor(source.id)!.nativeId,
            params: {'retailerId': retailer.id},
          ),
          near: near,
          radiusMeters: radiusMeters,
        ),
      ),
      filter: (source) =>
          source.capabilities.supportsStores &&
          retailer.bindingFor(source.id) != null,
    );
  }

  @override
  Future<void> clearCache({bool expiredOnly = false}) =>
      _cache.clear(expiredOnly: expiredOnly);

  @override
  void close() {
    for (final source in _sources) {
      source.close();
    }
    _client?.close();
  }

  ProspectSource? _sourceById(String id) {
    for (final source in _sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  /// Neueste zuerst. Prospekte ohne Datum ans Ende, damit sie eine sonst
  /// saubere Liste nicht anfuehren.
  static int _byValidityDescending(Brochure a, Brochure b) {
    final aDate = a.validFrom ?? a.publishedAt;
    final bDate = b.validFrom ?? b.publishedAt;
    if (aDate == null && bDate == null) return a.title.compareTo(b.title);
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}
