import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/sources/marktguru/marktguru_api.dart';
import 'package:prospect_client/src/sources/marktguru/marktguru_mapper.dart';
import 'package:prospect_client/src/sources/tjek/tjek_mapper.dart' show ParseReport;
import 'package:test/test.dart';

import 'support/fake_http_client.dart';
import 'support/fixtures.dart';

void main() {
  final api = MarktguruApi(
    ApiClient(
      cache: MemoryCacheStore(),
      httpClient: FakeHttpClient.json(const []),
      minRequestInterval: Duration.zero,
    ),
    apiKey: 'test',
    clientKey: 'test',
  );
  final mapper = MarktguruMapper(api);
  late ParseReport report;

  List<Map<String, Object?>> offers() => Fixtures.list('marktguru_offer.json');
  List<Map<String, Object?>> flights() =>
      Fixtures.list('marktguru_leaflets.json')
          .map((e) => e['flight']! as Map<String, Object?>)
          .toList();

  setUp(() => report = ParseReport());

  group('Angebote', () {
    test('nimmt den Produktnamen als Titel, nicht die Beschreibung', () {
      // description ist bei Marktguru der Zusatztext ("je 60-g-Pckg."),
      // der Name steht in product.name.
      final offer = mapper.offer(offers().first, report)!;

      expect(offer.title, 'Grana Padano Gerieben');
      expect(offer.description, contains('60-g-Pckg'));
      expect(offer.brand, 'Giovanni Ferrari');
    });

    test('liest Preis, Streichpreis und Grundpreis', () {
      final withoutOld = mapper.offer(offers()[0], report)!;
      expect(withoutOld.price!.current, 1.79);
      expect(withoutOld.price!.previous, isNull);
      expect(withoutOld.price!.hasDiscount, isFalse);
      // referencePrice plus unit.shortName ergeben den Grundpreis.
      expect(withoutOld.price!.basePriceText, '1 kg = 29.83');

      final withOld = mapper.offer(offers()[1], report)!;
      expect(withOld.price!.previous, 1.29);
      expect(withOld.price!.discountPercent, 23.3);
    });

    test('uebernimmt Menge und Einheit', () {
      final offer = mapper.offer(offers().first, report)!;
      expect(offer.quantity!.unitSymbol, 'kg');
      expect(offer.quantity!.sizeFrom, 0.06);
      expect(offer.quantity!.piecesFrom, 1);
    });

    test('uebernimmt den eigenen Gueltigkeitszeitraum des Angebots', () {
      // Kann kuerzer sein als der des Prospekts, etwa bei Wochenendaktionen.
      final offer = mapper.offer(offers().first, report)!;
      expect(offer.validFrom, DateTime.utc(2026, 8, 9, 22));
      expect(offer.validUntil, DateTime.utc(2026, 8, 15, 21, 59));
    });

    test('setzt Bilder nur, wenn die Quelle welche meldet', () {
      final withImage = mapper.offer(offers()[0], report)!;
      expect(withImage.image.isEmpty, isFalse);
      expect(
        withImage.image.normal.toString(),
        contains('/api/v1/offers/24389293/images/default/0/medium.webp'),
      );

      // images.count ist 0, dann waere eine konstruierte URL ein toter Link.
      final withoutImage = mapper.offer(offers()[1], report)!;
      expect(withoutImage.image.isEmpty, isTrue);
    });

    test('uebernimmt Kategorien', () {
      expect(mapper.offer(offers().first, report)!.categories, ['Käse']);
    });

    test('ueberspringt ein Angebot ohne Produktnamen', () {
      expect(mapper.offer({'id': 1}, report), isNull);
      expect(report.skipped, 1);
    });

    test('faellt auf die Beschreibung zurueck, wenn product fehlt', () {
      final offer = mapper.offer({'id': 1, 'description': 'Irgendwas'}, report)!;
      expect(offer.title, 'Irgendwas');
    });
  });

  group('Prospekte', () {
    test('liest einen REWE-Prospekt aus der Suche', () {
      final brochure = mapper.brochure(flights().first, report)!;

      expect(brochure.id.sourceId, 'marktguru');
      expect(brochure.retailerId, 'rewe');
      expect(brochure.pageCount, 16);
      expect(brochure.validFrom, DateTime.utc(2026, 8, 9, 22));
      expect(brochure.contentLevel, BrochureContentLevel.productsWithPrices);
    });

    test('erzeugt Seiten aus mainLeafletId, nicht aus der Flight-ID', () {
      // Die Bilder haengen am Einzelheft. Wer hier die Flight-ID nimmt,
      // bekommt lauter tote Bild-URLs.
      final brochure = mapper.brochure(flights().first, report)!;

      expect(brochure.pages, hasLength(16));
      expect(brochure.pages.first.number, 1);
      expect(
        brochure.pages.first.images.large.toString(),
        contains('/api/v1/leaflets/5759348/images/pages/0/'),
      );
      // Seitennummer ist 1-basiert, der Index der Quelle 0-basiert.
      expect(
        brochure.pages[3].images.large.toString(),
        contains('/images/pages/3/'),
      );
    });

    test('erkennt einen Prospekt ohne Angebote als Bildprospekt', () {
      final dm = mapper.brochure(flights()[1], report)!;
      expect(dm.retailerId, 'dm');
      expect(dm.contentLevel, BrochureContentLevel.imagesOnly);
    });

    test('markiert Prospekte als regional', () {
      // Die Suche laeuft immer gegen eine Postleitzahl, die Treffer gelten
      // also fuer diesen Ort und nicht bundesweit.
      final brochure = mapper.brochure(flights().first, report)!;
      expect(brochure.coverage, BrochureCoverage.regional);
      expect(brochure.coverage.needsLocation, isTrue);
    });

    test('ueberspringt einen Prospekt ohne id', () {
      expect(mapper.brochure({'pageCount': 4}, report), isNull);
      expect(report.skipped, 1);
    });
  });

  group('Haendler', () {
    test('loest die Praefix-ID auf und bildet kanonisch ab', () {
      // Marktguru liefert "retailers/126802", gebraucht wird die Zahl.
      expect(MarktguruMapper.retailerNumber('retailers/126802'), '126802');
      expect(MarktguruMapper.retailerNumber('126802'), '126802');
      expect(MarktguruMapper.retailerNumber(null), isNull);

      final retailer = mapper.retailer(
        {'id': 'retailers/126802', 'name': 'REWE'},
        report,
      )!;
      expect(retailer.id, 'rewe');
      expect(retailer.bindings.single.nativeId, '126802');
      expect(
        retailer.logo.normal.toString(),
        contains('/api/v1/retailers/126802/images/logos/0/medium.webp'),
      );
    });

    test('deckt die Haendler ab, die den anderen Quellen fehlen', () {
      // Der eigentliche Grund fuer diesen Adapter.
      for (final entry in {
        'REWE': 'rewe',
        'EDEKA': 'edeka',
        'dm-drogerie markt': 'dm',
        'Rossmann': 'rossmann',
      }.entries) {
        final retailer = mapper.retailer(
          {'id': 'retailers/1', 'name': entry.key},
          report,
        )!;
        expect(retailer.id, entry.value, reason: 'fuer ${entry.key}');
      }
    });
  });
}
