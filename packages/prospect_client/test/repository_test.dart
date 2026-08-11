import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/core/repository/default_prospect_repository.dart';
import 'package:test/test.dart';

/// Adapter-Attrappe: liefert vorgegebene Daten oder wirft einen vorgegebenen
/// Fehler. Damit laesst sich das Zusammenfuehren mehrerer Quellen und das
/// Verhalten bei Teilausfaellen pruefen, ohne Netzwerk.
class FakeSource implements ProspectSource {
  FakeSource({
    required this.id,
    this.retailers = const [],
    this.brochures = const [],
    this.offers = const [],
    this.stores = const [],
    this.capabilities = const SourceCapabilities(
      supportsGeoSearch: true,
      supportsOfferSearch: true,
      supportsStores: true,
      providesPrices: true,
    ),
    this.failWith,
  });

  @override
  final String id;

  @override
  String get displayName => 'Fake $id';

  @override
  final SourceCapabilities capabilities;

  final List<Retailer> retailers;
  final List<Brochure> brochures;
  final List<Offer> offers;
  final List<Store> stores;
  final ProspectException? failWith;

  int brochureCalls = 0;
  int offerCalls = 0;
  BrochureQuery? lastBrochureQuery;

  void _guard() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async {
    _guard();
    return retailers;
  }

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async {
    brochureCalls++;
    lastBrochureQuery = query;
    _guard();
    return brochures;
  }

  @override
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  }) async {
    _guard();
    return brochures.firstWhere(
      (b) => b.id.nativeId == nativeId,
      orElse: () => throw NotFound('$nativeId nicht gefunden', sourceId: id),
    );
  }

  @override
  Future<List<Offer>> searchOffers(OfferQuery query) async {
    offerCalls++;
    _guard();
    return offers;
  }

  @override
  Future<List<Store>> fetchStores(StoreQuery query) async {
    _guard();
    return stores;
  }

  @override
  void close() {}
}

Retailer retailer(String id, String sourceId, {Map<String, String>? params}) =>
    Retailer(
      id: id,
      name: id,
      bindings: [
        SourceBinding(
          sourceId: sourceId,
          nativeId: '$id-native',
          params: params ?? const {},
        ),
      ],
    );

Brochure brochure(
  String sourceId,
  String nativeId,
  String retailerId, {
  DateTime? validFrom,
}) =>
    Brochure(
      id: BrochureId(sourceId, nativeId),
      retailerId: retailerId,
      title: nativeId,
      contentLevel: BrochureContentLevel.unknown,
      validFrom: validFrom,
      validUntil: DateTime.now().toUtc().add(const Duration(days: 7)),
    );

ProspectRepository build(List<ProspectSource> sources) =>
    DefaultProspectRepository(sources: sources, cache: MemoryCacheStore());

void main() {
  group('Haendler zusammenfuehren', () {
    test('vereint denselben Haendler aus zwei Quellen zu einem Eintrag', () async {
      // Der reale Kaufland-Fall.
      final repo = build([
        FakeSource(id: 'tjek', retailers: [retailer('kaufland', 'tjek')]),
        FakeSource(
          id: 'schwarz',
          retailers: [
            retailer('kaufland', 'schwarz', params: {'region_id': '3000'}),
          ],
        ),
      ]);

      final result = await repo.getRetailers();

      expect(result.data, hasLength(1));
      expect(result.data.single.bindings, hasLength(2));
      expect(result.data.single.bindingFor('tjek'), isNotNull);
      expect(
        result.data.single.bindingFor('schwarz')!.params['region_id'],
        '3000',
      );
      expect(result.isPartial, isFalse);
    });

    test('sortiert Haendler alphabetisch ohne Ruecksicht auf Gross-Klein', () async {
      final repo = build([
        FakeSource(id: 'a', retailers: [
          const Retailer(id: 'zeta', name: 'zeta'),
          const Retailer(id: 'alpha', name: 'ALPHA'),
          const Retailer(id: 'mitte', name: 'Mitte'),
        ]),
      ]);
      final result = await repo.getRetailers();
      expect(result.data.map((r) => r.id), ['alpha', 'mitte', 'zeta']);
    });
  });

  group('Teilausfaelle', () {
    test('liefert Daten der intakten Quelle und meldet die kaputte', () async {
      // Die Kernzusage: faellt eine Quelle aus, liefert die andere trotzdem.
      final repo = build([
        FakeSource(
          id: 'tjek',
          retailers: [retailer('netto', 'tjek')],
          brochures: [brochure('tjek', 'a', 'netto')],
        ),
        FakeSource(
          id: 'schwarz',
          retailers: [retailer('lidl', 'schwarz')],
          failWith: const SourceUnavailable('down', sourceId: 'schwarz'),
        ),
      ]);

      final result = await repo.getRetailers();

      expect(result.data, hasLength(1));
      expect(result.data.single.id, 'netto');
      expect(result.isPartial, isTrue);
      expect(result.errors.single, isA<SourceUnavailable>());
      expect(result.errors.single.sourceId, 'schwarz');
      expect(result.isTotalFailure, isFalse);
    });

    test('meldet einen Totalausfall als solchen, ohne zu werfen', () async {
      final repo = build([
        FakeSource(id: 'a', failWith: const NetworkFailure('kein Netz')),
        FakeSource(id: 'b', failWith: const NetworkFailure('kein Netz')),
      ]);

      final result = await repo.getRetailers();

      expect(result.data, isEmpty);
      expect(result.isTotalFailure, isTrue);
      expect(result.errors, hasLength(2));
    });

    test('faengt auch unerwartete Fehler eines Adapters ab', () async {
      // Ein Defekt im Adapter darf nicht als roher Fehler bei der App landen.
      final repo = build([_ThrowingSource()]);
      final result = await repo.getRetailers();

      expect(result.isTotalFailure, isTrue);
      expect(result.errors.single, isA<ProspectException>());
      expect(result.errors.single.message, contains('Unerwarteter Fehler'));
    });
  });

  group('Quellenauswahl', () {
    test('fragt nur Quellen, die den Haendler kennen', () async {
      final knows = FakeSource(
        id: 'tjek',
        retailers: [retailer('netto', 'tjek')],
        brochures: [brochure('tjek', 'a', 'netto')],
      );
      final knowsNot = FakeSource(
        id: 'schwarz',
        retailers: [retailer('lidl', 'schwarz')],
      );
      final repo = build([knows, knowsNot]);

      await repo.getBrochures(retailerId: 'netto');

      expect(knows.brochureCalls, 1);
      expect(knowsNot.brochureCalls, 0,
          reason: 'Sonst liefert die Quelle ungefiltert alles');
    });

    test('reicht das passende Binding an den Adapter durch', () async {
      final source = FakeSource(
        id: 'schwarz',
        retailers: [
          retailer('kaufland', 'schwarz', params: {'region_id': '3000'}),
        ],
      );
      final repo = build([source]);

      await repo.getBrochures(retailerId: 'kaufland');

      expect(source.lastBrochureQuery!.binding!.nativeId, 'kaufland-native');
      expect(
        source.lastBrochureQuery!.binding!.params['region_id'],
        '3000',
      );
    });

    test('ueberspringt Quellen ohne Suchunterstuetzung', () async {
      final searchable = FakeSource(
        id: 'tjek',
        offers: const [Offer(id: 'o1', title: 'Milch')],
      );
      final notSearchable = FakeSource(
        id: 'schwarz',
        capabilities: const SourceCapabilities(supportsOfferSearch: false),
      );
      final repo = build([searchable, notSearchable]);

      final result = await repo.searchOffers(
        'milch',
        near: const GeoPoint(52.52, 13.405),
      );

      expect(result.data, hasLength(1));
      expect(searchable.offerCalls, 1);
      expect(notSearchable.offerCalls, 0);
      expect(result.isPartial, isFalse,
          reason: 'Eine Quelle ohne Suche ist kein Fehler');
    });

    test('meldet einen Hinweis, wenn keine Quelle die Abfrage kann', () async {
      final repo = build([
        FakeSource(
          id: 'schwarz',
          capabilities: const SourceCapabilities(supportsOfferSearch: false),
        ),
      ]);

      final result = await repo.searchOffers(
        'milch',
        near: const GeoPoint(52.52, 13.405),
      );

      expect(result.data, isEmpty);
      expect(result.errors, isEmpty);
      expect(result.warnings, isNotEmpty);
    });

    test('sucht nicht ohne Ortsangabe', () async {
      // Tjek durchsucht ohne Geobezug alle Laender und liefert ueberwiegend
      // daenische Treffer mit Preisen in DKK. Das ist schlimmer als kein
      // Ergebnis, weil es plausibel aussieht.
      final source = FakeSource(
        id: 'tjek',
        offers: const [Offer(id: 'o1', title: 'Milch')],
      );
      final repo = build([source]);

      final result = await repo.searchOffers('milch');

      expect(result.data, isEmpty);
      expect(source.offerCalls, 0);
      expect(result.warnings.single, contains('braucht einen Ort'));
    });
  });

  group('Prospekte', () {
    test('sortiert neueste zuerst, undatierte ans Ende', () async {
      final repo = build([
        FakeSource(
          id: 'tjek',
          retailers: [retailer('netto', 'tjek')],
          brochures: [
            brochure('tjek', 'alt', 'netto', validFrom: DateTime.utc(2026, 1, 1)),
            brochure('tjek', 'ohne', 'netto'),
            brochure('tjek', 'neu', 'netto', validFrom: DateTime.utc(2026, 8, 1)),
          ],
        ),
      ]);

      final result = await repo.getBrochures(retailerId: 'netto');

      expect(
        result.data.map((b) => b.id.nativeId),
        ['neu', 'alt', 'ohne'],
      );
    });

    test('meldet unbekannte Haendler als NotFound im Ergebnis', () async {
      final repo = build([FakeSource(id: 'tjek')]);
      final result = await repo.getBrochures(retailerId: 'gibtsnicht');

      expect(result.data, isEmpty);
      expect(result.errors.single, isA<NotFound>());
    });

    test('wirft bei einer nicht registrierten Quelle einen Konfigurationsfehler',
        () async {
      final repo = build([FakeSource(id: 'tjek')]);
      await expectLater(
        repo.getBrochure(const BrochureId('bonial', 'x')),
        throwsA(isA<ConfigurationError>()),
      );
    });

    test('holt den Detailprospekt bei der passenden Quelle', () async {
      final repo = build([
        FakeSource(id: 'tjek', brochures: [brochure('tjek', 'abc', 'netto')]),
        FakeSource(id: 'schwarz'),
      ]);

      final detail = await repo.getBrochure(const BrochureId('tjek', 'abc'));
      expect(detail.title, 'abc');
    });
  });

  group('Suche', () {
    test('gibt bei leerer Anfrage nichts zurueck ohne Quellen zu belasten',
        () async {
      final source = FakeSource(id: 'tjek');
      final repo = build([source]);

      final result = await repo.searchOffers('   ');

      expect(result.data, isEmpty);
      expect(source.offerCalls, 0);
      expect(result.warnings, isNotEmpty);
    });
  });
}

/// Adapter, der einen Fehler wirft, der nicht aus der Modul-Hierarchie stammt.
class _ThrowingSource implements ProspectSource {
  @override
  String get id => 'kaputt';

  @override
  String get displayName => 'Kaputt';

  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

  @override
  Future<List<Retailer>> fetchRetailers(RetailerQuery query) async =>
      throw StateError('Programmierfehler im Adapter');

  @override
  Future<List<Brochure>> fetchBrochures(BrochureQuery query) async => const [];

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
