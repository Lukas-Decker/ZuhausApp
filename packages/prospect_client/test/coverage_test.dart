import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/core/repository/default_prospect_repository.dart';
import 'package:prospect_client/src/sources/schwarz/kaufland_store_directory.dart';
import 'package:prospect_client/src/sources/tjek/tjek_mapper.dart';
import 'package:test/test.dart';

import 'support/fake_http_client.dart';
import 'support/fixtures.dart';

/// Tests zur Filialabhaengigkeit von Prospekten.
///
/// Der Anlass ist ein realer Fehler der ersten Fassung: sie lieferte fuer HIT
/// ueber 50 filialspezifische Wochenprospekte quer durch Deutschland in einer
/// Liste, fuer Lidl rund 40 Regionalvarianten, und fuer Kaufland immer die
/// Prospekte einer fest verdrahteten Region. Nutzer sahen damit ueberwiegend
/// Angebote, die in ihrer Filiale nicht galten.
void main() {
  group('Tjek: all_stores', () {
    const mapper = TjekMapper();
    late ParseReport report;

    setUp(() => report = ParseReport());

    test('erkennt bundesweite und filialgebundene Prospekte', () {
      final base = Fixtures.tjekCatalogs.first;

      expect(
        mapper.brochure({...base, 'all_stores': true}, report)!.coverage,
        BrochureCoverage.national,
      );
      expect(
        mapper.brochure({...base, 'all_stores': false}, report)!.coverage,
        BrochureCoverage.storeBound,
      );

      final without = {...base}..remove('all_stores');
      expect(
        mapper.brochure(without, report)!.coverage,
        BrochureCoverage.unknown,
      );
    });

    test('meldet nur filialgebundene Prospekte als ortsabhaengig', () {
      expect(BrochureCoverage.national.needsLocation, isFalse);
      expect(BrochureCoverage.unknown.needsLocation, isFalse);
      expect(BrochureCoverage.regional.needsLocation, isTrue);
      expect(BrochureCoverage.storeBound.needsLocation, isTrue);
    });

    test('uebernimmt eine store_id als Regionscode', () {
      final withStore = {...Fixtures.tjekCatalogs.first, 'store_id': 'abc123'};
      expect(mapper.brochure(withStore, report)!.regionCodes, ['abc123']);

      final withoutStore = {...Fixtures.tjekCatalogs.first}..remove('store_id');
      expect(mapper.brochure(withoutStore, report)!.regionCodes, isEmpty);
    });
  });

  group('KauflandStoreDirectory', () {
    KauflandStoreDirectory build() => KauflandStoreDirectory(
          ApiClient(
            cache: MemoryCacheStore(),
            httpClient: FakeHttpClient(
              (_, __) => FakeResponse(Fixtures.raw('kaufland_stores.json'), 200),
            ),
            minRequestInterval: Duration.zero,
          ),
        );

    test('liest die abgekuerzten Feldnamen der Quelle', () async {
      final stores = await build().stores();
      expect(stores, hasLength(3));

      final berlin = stores.firstWhere((s) => s.objectNumber == 'DE8920');
      expect(berlin.name, 'Kaufland Berlin-Mitte');
      expect(berlin.zipCode, '10178');
      expect(berlin.town, 'Berlin');
      expect(berlin.location.latitude, closeTo(52.52, 0.01));
    });

    test('leitet den Regionscode aus der Objektnummer ab', () async {
      // Der Kern der Aufloesung: die Objektnummer ohne Laenderpraefix ist
      // exakt der region_id der Prospekt-API. Verifiziert an der Prospekt-URL
      // leaflets.kaufland.com/de-DE/DE_de_KDZ1_8920_D33/ar/8920.
      final stores = await build().stores();
      final berlin = stores.firstWhere((s) => s.objectNumber == 'DE8920');
      expect(berlin.regionCode, '8920');
    });

    test('findet die naechstgelegene Filiale', () async {
      final directory = build();

      expect(
        (await directory.nearest(const GeoPoint(52.52, 13.405)))?.objectNumber,
        'DE8920',
      );
      expect(
        (await directory.nearest(const GeoPoint(48.14, 11.58)))?.objectNumber,
        'DE1633',
      );
      expect(await directory.regionFor(const GeoPoint(53.55, 9.99)), '1690');
    });

    test('liefert nichts, wenn keine Filiale in Reichweite ist', () async {
      // Verhindert, dass jemand weit ausserhalb Deutschlands die Prospekte
      // einer beliebigen Filiale zugeordnet bekommt.
      final directory = build();
      expect(
        await directory.nearest(const GeoPoint(38.72, -9.14)),
        isNull,
      );
    });

    test('laedt die Liste nur einmal', () async {
      final http = FakeHttpClient(
        (_, __) => FakeResponse(Fixtures.raw('kaufland_stores.json'), 200),
      );
      final directory = KauflandStoreDirectory(
        ApiClient(
          cache: MemoryCacheStore(),
          httpClient: http,
          minRequestInterval: Duration.zero,
        ),
      );

      await directory.stores();
      await directory.stores();
      await directory.regionFor(const GeoPoint(52.52, 13.405));

      expect(http.requestCount, 1,
          reason: 'Die Liste ist rund 500 KB gross und aendert sich selten');
    });
  });

  group('Schwarz: regions', () {
    test('erkennt die drei Typen der Quelle', () {
      // Beobachtete Werte: national (bundesweit), offer_region (Lidl,
      // Vertriebsgebiet), store (Kaufland, Code ist die Filialnummer).
      Brochure parse(Object? regions) => Brochure.fromJson({
            'id': 'schwarz:lidl.x',
            'title': 't',
            'contentLevel': 'unknown',
            'coverage': switch (regions) {
              'national' => 'national',
              'offer_region' => 'regional',
              'store' => 'storeBound',
              _ => 'unknown',
            },
          });

      expect(parse('national').coverage.needsLocation, isFalse);
      expect(parse('offer_region').coverage.needsLocation, isTrue);
      expect(parse('store').coverage.needsLocation, isTrue);
    });
  });

  group('Repository ohne Ortsangabe', () {
    test('warnt, dass die Liste auf bundesweite Prospekte gekuerzt ist',
        () async {
      final repo = DefaultProspectRepository(
        sources: [_CoverageSource()],
        cache: MemoryCacheStore(),
      );

      final withoutLocation = await repo.getBrochures(retailerId: 'hit');
      expect(withoutLocation.warnings, isNotEmpty);
      expect(withoutLocation.warnings.first, contains('bundesweit'));

      final withLocation = await repo.getBrochures(
        retailerId: 'hit',
        near: const GeoPoint(52.52, 13.405),
      );
      expect(withLocation.warnings, isEmpty);
    });

    test('reicht includeOutOfArea an die Quelle durch', () async {
      final source = _CoverageSource();
      final repo = DefaultProspectRepository(
        sources: [source],
        cache: MemoryCacheStore(),
      );

      await repo.getBrochures(retailerId: 'hit', includeOutOfArea: true);
      expect(source.lastQuery!.includeOutOfArea, isTrue);

      final result =
          await repo.getBrochures(retailerId: 'hit', includeOutOfArea: true);
      expect(result.warnings, isEmpty,
          reason: 'Wer bewusst alles anfordert, braucht keinen Hinweis');
    });

    test('liefert fuer bundesweite Prospekte keine Filialliste', () async {
      final repo = DefaultProspectRepository(
        sources: [_CoverageSource()],
        cache: MemoryCacheStore(),
      );

      final result = await repo.getBrochureStores(
        const Brochure(
          id: BrochureId('tjek', 'x'),
          retailerId: 'netto',
          title: 'Bundesweit',
          contentLevel: BrochureContentLevel.imagesOnly,
          coverage: BrochureCoverage.national,
        ),
      );

      expect(result.data, isEmpty);
      expect(result.warnings.single, contains('bundesweit'));
    });
  });
}

/// Quelle, die nur die Abfrage protokolliert.
class _CoverageSource implements ProspectSource {
  BrochureQuery? lastQuery;

  @override
  String get id => 'tjek';

  @override
  String get displayName => 'Fake';

  @override
  SourceCapabilities get capabilities =>
      const SourceCapabilities(supportsGeoSearch: true);

  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async => const [
        Retailer(
          id: 'hit',
          name: 'HIT',
          bindings: [SourceBinding(sourceId: 'tjek', nativeId: 'JBcWUF')],
        ),
      ];

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async {
    lastQuery = query;
    return const [];
  }

  @override
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  }) async =>
      throw const NotFound('x');

  @override
  Future<List<Offer>> searchOffers(OfferQuery query) async => const [];

  @override
  Future<List<Store>> fetchStores(StoreQuery query) async => const [];

  @override
  void close() {}
}
