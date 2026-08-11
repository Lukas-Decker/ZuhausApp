import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/sources/tjek/tjek_mapper.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  const mapper = TjekMapper();
  late ParseReport report;

  setUp(() => report = ParseReport());

  group('Prospekte', () {
    test('liest einen echten Netto-Katalog vollstaendig', () {
      final brochure = mapper.brochure(Fixtures.tjekCatalogs.first, report)!;

      expect(brochure.id.sourceId, 'tjek');
      expect(brochure.retailerId, 'netto');
      expect(brochure.title, contains('Netto'));
      expect(brochure.pageCount, greaterThan(0));
      expect(brochure.validFrom, isNotNull);
      expect(brochure.validUntil, isNotNull);
      expect(brochure.validFrom!.isBefore(brochure.validUntil!), isTrue);
      expect(report.hasIssues, isFalse);
    });

    test('leitet den Inhaltsgrad aus offer_count ab', () {
      // Der gemessene Unterschied: Netto liefert hunderte Angebote, ALDI
      // konsistent null. Bei Tjek ist offer_count damit ein verlaesslicher
      // Indikator und kein Zufall.
      final withOffers = mapper.brochure(
        {...Fixtures.tjekCatalogs.first, 'offer_count': 272},
        report,
      )!;
      expect(withOffers.contentLevel, BrochureContentLevel.productsWithPrices);

      final withoutOffers = mapper.brochure(
        {...Fixtures.tjekCatalogs.first, 'offer_count': 0},
        report,
      )!;
      expect(withoutOffers.contentLevel, BrochureContentLevel.imagesOnly);
    });

    test('ueberspringt einen Katalog ohne id und vermerkt das', () {
      final broken = {...Fixtures.tjekCatalogs.first}..remove('id');
      expect(mapper.brochure(broken, report), isNull);
      expect(report.skipped, 1);
      expect(report.summary, contains('ohne id'));
    });
  });

  group('Angebote', () {
    test('liest Preis, Streichpreis und Menge aus echten Daten', () {
      final offer = mapper.offer(Fixtures.tjekOffers.first, report)!;

      expect(offer.title, isNotEmpty);
      expect(offer.price, isNotNull);
      expect(offer.price!.currency, 'EUR');
      expect(offer.price!.current, greaterThan(0));
      expect(offer.image.isEmpty, isFalse);
      expect(offer.image.thumbnail, isNotNull);
      expect(offer.image.large, isNotNull);
    });

    test('vertraegt pre_price: null', () {
      // Kommt in den echten Daten haeufig vor und darf nicht als 0 landen,
      // sonst zeigt die App einen Rabatt von 100 Prozent an.
      final offer = mapper.offer({
        'id': 'x',
        'heading': 'Ware',
        'pricing': {'price': 1.49, 'pre_price': null, 'currency': 'EUR'},
      }, report)!;

      expect(offer.price!.previous, isNull);
      expect(offer.price!.hasDiscount, isFalse);
      expect(offer.price!.discountPercent, isNull);
    });

    test('liefert ein Angebot ohne pricing-Block ohne Preis statt null', () {
      final offer = mapper.offer({'id': 'x', 'heading': 'Ware'}, report)!;
      expect(offer.price, isNull);
      expect(offer.hasPrice, isFalse);
      expect(report.hasIssues, isFalse, reason: 'Das ist kein Fehlerfall');
    });

    test('uebernimmt die SI-Normalisierung der Menge', () {
      final offer = mapper.offer(Fixtures.tjekOffers.first, report)!;
      final quantity = offer.quantity;
      if (quantity?.siFactor != null) {
        expect(quantity!.sizeInSiUnit, isNotNull);
        expect(quantity.siSymbol, isNotNull);
      }
    });

    test('ueberspringt ein Angebot ohne heading', () {
      expect(mapper.offer({'id': 'x'}, report), isNull);
      expect(report.skipped, 1);
    });
  });

  group('Seiten und Hotspots', () {
    test('nummeriert Seiten nach ihrer Position im Array', () {
      // Die API liefert kein Seitennummernfeld, nur die Reihenfolge.
      final pages = mapper.pages(Fixtures.tjekPages, const {});
      expect(pages, hasLength(Fixtures.tjekPages.length));
      expect(pages.first.number, 1);
      expect(pages.last.number, pages.length);
      expect(pages.first.images.thumbnail, isNotNull);
      expect(pages.first.images.normal, isNotNull);
      expect(pages.first.images.large, isNotNull);
    });

    test('rechnet Polygone in Prozentrechtecke um', () {
      final byPage = mapper.hotspotsByPage(Fixtures.tjekHotspots);
      expect(byPage, isNotEmpty);

      final hotspot = byPage.values.first.first;
      expect(hotspot.left, inInclusiveRange(0, 100));
      expect(hotspot.top, inInclusiveRange(0, 100));
      expect(hotspot.width, greaterThan(0));
      expect(hotspot.height, greaterThan(0));
      expect(hotspot.left + hotspot.width, lessThanOrEqualTo(100.001));
      expect(hotspot.offerId, isNotNull);
    });

    test('bildet die Bounding Box eines bekannten Polygons exakt ab', () {
      // Werte aus tjek_hotspots.json, Seite 1.
      final byPage = mapper.hotspotsByPage([
        {
          'id': 'h1',
          'heading': 'Test',
          'locations': {
            '1': [
              [0.346, 0.3105882032],
              [0.346, 0.776470508],
              [0.668, 0.776470508],
              [0.668, 0.3105882032],
            ],
          },
        },
      ]);

      final hotspot = byPage[1]!.single;
      expect(hotspot.left, closeTo(34.6, 0.01));
      expect(hotspot.top, closeTo(31.06, 0.01));
      expect(hotspot.width, closeTo(32.2, 0.01));
      expect(hotspot.height, closeTo(46.59, 0.01));
    });

    test('verknuepft Hotspots mit den passenden Seiten', () {
      final byPage = mapper.hotspotsByPage(Fixtures.tjekHotspots);
      final pages = mapper.pages(Fixtures.tjekPages, byPage);
      for (final page in pages) {
        for (final hotspot in page.hotspots) {
          expect(hotspot.offerId, isNotNull);
        }
      }
    });

    test('ignoriert kaputte Koordinaten statt zu werfen', () {
      final byPage = mapper.hotspotsByPage([
        {
          'id': 'h1',
          'locations': {
            '1': [
              ['keine', 'zahl'],
            ],
            'nicht-numerisch': [
              [0.1, 0.1],
            ],
          },
        },
      ]);
      expect(byPage, isEmpty);
    });
  });

  group('Haendler', () {
    test('bildet einen Katalog-Dealer auf die kanonische ID ab', () {
      final dealer =
          Fixtures.tjekOffers.first['dealer']! as Map<String, Object?>;
      final retailer = mapper.retailer(dealer, report)!;

      expect(retailer.id, 'netto');
      expect(retailer.name, 'Netto');
      expect(retailer.countryCode, 'DE');
      expect(retailer.bindings.single.sourceId, 'tjek');
      expect(retailer.bindings.single.nativeId, '90f2VL');
      expect(retailer.logo.isEmpty, isFalse);
    });
  });

  group('Filialen', () {
    test('liest Adresse und Koordinaten', () {
      final store = mapper.store(Fixtures.tjekStores.first, 'netto', report)!;
      expect(store.retailerId, 'netto');
      expect(store.address, isNotEmpty);
      if (store.location != null) {
        expect(store.location!.latitude, inInclusiveRange(-90, 90));
        expect(store.location!.longitude, inInclusiveRange(-180, 180));
      }
    });

    test('akzeptiert eine Filiale ohne Koordinaten', () {
      final store = mapper.store(
        {'id': 's1', 'city': 'Berlin'},
        'netto',
        report,
      )!;
      expect(store.location, isNull);
      expect(store.address, 'Berlin');
    });
  });
}
