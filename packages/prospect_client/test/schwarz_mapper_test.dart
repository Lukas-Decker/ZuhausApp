import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/sources/schwarz/schwarz_api.dart';
import 'package:prospect_client/src/sources/schwarz/schwarz_mapper.dart';
import 'package:prospect_client/src/sources/tjek/tjek_mapper.dart' show ParseReport;
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  const mapper = SchwarzMapper();
  final kaufland = SchwarzApi.clientFor('kaufland')!;
  final lidl = SchwarzApi.clientFor('lidl')!;
  late ParseReport report;

  Map<String, Object?> flyerJson() =>
      Fixtures.schwarzFlyerKaufland['flyer']! as Map<String, Object?>;

  setUp(() => report = ParseReport());

  group('Uebersicht', () {
    List<Map<String, Object?>> lidlFlyers() {
      final categories =
          Fixtures.schwarzOverviewLidl['categories']! as List<Object?>;
      final first = categories.first! as Map<String, Object?>;
      final sub = (first['subcategories']! as List<Object?>).first
          as Map<String, Object?>;
      return (sub['flyers']! as List<Object?>).cast<Map<String, Object?>>();
    }

    test('liest einen echten Lidl-Listeneintrag', () {
      final brochure =
          mapper.overviewEntry(lidlFlyers().first, lidl, report)!;

      expect(brochure.id.sourceId, 'schwarz');
      expect(brochure.retailerId, 'lidl');
      expect(brochure.title, isNotEmpty);
      expect(brochure.pdfUrl, isNotNull);
      expect(brochure.cover.isEmpty, isFalse);
      expect(brochure.validFrom, isNotNull);
      expect(brochure.validUntil, isNotNull);
    });

    test('setzt den Inhaltsgrad in der Liste auf unknown', () {
      // Zentral fuer die Ehrlichkeit des Modells: die Uebersicht enthaelt
      // keine Produkte, das heisst aber nicht, dass der Prospekt keine hat.
      // Der Kaufland-Wochenprospekt hat 422.
      final brochure =
          mapper.overviewEntry(lidlFlyers().first, lidl, report)!;
      expect(brochure.contentLevel, BrochureContentLevel.unknown);
      expect(brochure.contentLevel.isDetermined, isFalse);
    });

    test('kodiert den Mandanten in die native ID', () {
      final brochure =
          mapper.overviewEntry(lidlFlyers().first, lidl, report)!;
      expect(brochure.id.nativeId, startsWith('lidl.'));

      final split = SchwarzMapper.splitNativeId(brochure.id.nativeId)!;
      expect(split.$1, 'lidl');
      expect(split.$2, isNotEmpty);
    });

    test('weist unvollstaendige native IDs zurueck', () {
      expect(SchwarzMapper.splitNativeId('lidl'), isNull);
      expect(SchwarzMapper.splitNativeId('.abc'), isNull);
      expect(SchwarzMapper.splitNativeId('lidl.'), isNull);
    });

    test('liest die Reichweite aus dem regions-Feld', () {
      // Das Feld ist mal ein Objekt, mal ein Array. Beide Formen kommen in
      // echten Antworten vor und muessen dieselbe Aussage ergeben.
      Brochure parse(Object? regions) => mapper.overviewEntry(
            {'id': 'x', 'regions': regions},
            lidl,
            report,
          )!;

      expect(
        parse({'type': 'national', 'code': '0'}).coverage,
        BrochureCoverage.national,
      );
      expect(
        parse({'type': 'store', 'code': '8920'}).coverage,
        BrochureCoverage.storeBound,
      );
      expect(
        parse([
          {'type': 'offer_region', 'code': '31'},
          {'type': 'offer_region', 'code': '4'},
        ]).coverage,
        BrochureCoverage.regional,
      );
      expect(parse(null).coverage, BrochureCoverage.unknown);
    });

    test('sammelt Regionscodes und laesst den nationalen Code 0 aus', () {
      final regional = mapper.overviewEntry(
        {
          'id': 'x',
          'regions': [
            {'type': 'offer_region', 'code': '31'},
            {'type': 'offer_region', 'code': '4'},
          ],
        },
        lidl,
        report,
      )!;
      expect(regional.regionCodes, ['31', '4']);
      expect(regional.primaryRegionCode, '31');

      final national = mapper.overviewEntry(
        {
          'id': 'y',
          'regions': {'type': 'national', 'code': '0'},
        },
        lidl,
        report,
      )!;
      expect(national.regionCodes, isEmpty);
      expect(national.coverage.needsLocation, isFalse);
    });
  });

  group('Prospektdetail', () {
    test('liest den echten Kaufland-Wochenprospekt', () {
      final brochure = mapper.flyer(flyerJson(), kaufland, report);

      expect(brochure.retailerId, 'kaufland');
      expect(brochure.pages, isNotEmpty);
      expect(brochure.pdfUrl, isNotNull);
      expect(brochure.validFrom, isNotNull);
      expect(brochure.validUntil, isNotNull);
    });

    test('erkennt Produkte ohne Preise als eigenen Inhaltsgrad', () {
      // Der gemessene Kaufland-Fall: 422 Produkte, alle ohne Preisfeld.
      // Weder "nur Bilder" noch "mit Preisen" waere hier richtig.
      final brochure = mapper.flyer(flyerJson(), kaufland, report);

      expect(brochure.offers, isNotEmpty);
      expect(brochure.offers.every((o) => !o.hasPrice), isTrue);
      expect(brochure.contentLevel, BrochureContentLevel.productsWithoutPrices);
      expect(brochure.contentLevel.hasProducts, isTrue);
      expect(brochure.contentLevel.hasPrices, isFalse);
    });

    test('erkennt Produkte mit Preisen', () {
      final withPrice = {
        ...flyerJson(),
        'products': {
          'hotspot-1': {
            'productId': '100387899',
            'title': 'PARKSIDE Kompressor',
            'brand': 'PARKSIDE',
            'price': '29.99',
            'currencyText': 'EUR',
          },
        },
      };
      final brochure = mapper.flyer(withPrice, lidl, report);

      expect(brochure.contentLevel, BrochureContentLevel.productsWithPrices);
      expect(brochure.offers.single.price!.current, 29.99);
      expect(brochure.offers.single.brand, 'PARKSIDE');
    });

    test('erkennt einen Prospekt ganz ohne Produkte als Bildprospekt', () {
      final noProducts = {...flyerJson()}..remove('products');
      final brochure = mapper.flyer(noProducts, kaufland, report);

      expect(brochure.offers, isEmpty);
      expect(brochure.contentLevel, BrochureContentLevel.imagesOnly);
    });

    test('liest die drei Bildaufloesungen jeder Seite', () {
      final brochure = mapper.flyer(flyerJson(), kaufland, report);
      final page = brochure.pages.first;

      expect(page.number, 1);
      expect(page.images.thumbnail, isNotNull);
      expect(page.images.normal, isNotNull);
      expect(page.images.large, isNotNull);
      expect(page.dimensions, isNotNull);
      expect(page.dimensions!.aspectRatio, greaterThan(0));
    });

    test('uebernimmt altText als Grundlage fuer Accessibility-Labels', () {
      final brochure = mapper.flyer(flyerJson(), kaufland, report);
      final withAlt = brochure.pages.where((p) => p.altText != null);
      expect(withAlt, isNotEmpty);
      expect(withAlt.first.altText, isNotEmpty);
    });

    test('uebernimmt Hotspot-Koordinaten unveraendert als Prozentwerte', () {
      // Anders als Tjek liefert Schwarz bereits Prozentwerte, hier darf
      // nicht zusaetzlich skaliert werden.
      final brochure = mapper.flyer(flyerJson(), kaufland, report);
      final hotspots = brochure.pages.expand((p) => p.hotspots);
      expect(hotspots, isNotEmpty);

      for (final hotspot in hotspots) {
        expect(hotspot.left, inInclusiveRange(0, 100));
        expect(hotspot.top, inInclusiveRange(0, 100));
        expect(hotspot.width, inInclusiveRange(0, 100));
      }
    });

    test('verknuepft Produkt-Hotspots ueber die Produkt-ID', () {
      final brochure = mapper.flyer(flyerJson(), kaufland, report);
      final linked = brochure.pages
          .expand((p) => p.hotspots)
          .where((h) => h.offerId != null);

      expect(linked, isNotEmpty,
          reason: 'Produkt-Hotspots muessen auf Angebote zeigen');

      final offerIds = brochure.offers.map((o) => o.id).toSet();
      for (final hotspot in linked) {
        expect(offerIds, contains(hotspot.offerId));
      }
    });

    test('behaelt bei Nicht-Produkt-Hotspots den Link', () {
      final brochure = mapper.flyer(flyerJson(), kaufland, report);
      final links = brochure.pages
          .expand((p) => p.hotspots)
          .where((h) => h.offerId == null && h.link != null);
      expect(links, isNotEmpty);
    });
  });

  group('Produkte', () {
    test('loest HTML-Entities in Beschreibungen auf', () {
      final withEntities = {
        ...flyerJson(),
        'products': {
          'h1': {
            'productId': '1',
            'title': 'Test',
            'description': 'Robustes Geh&auml;use mit gro&szlig;em Griff',
          },
        },
      };
      final offer = mapper.flyer(withEntities, lidl, report).offers.single;
      expect(offer.description, 'Robustes Gehause mit grossem Griff');
    });

    test('kuerzt den Kategoriepfad um das nichtssagende erste Segment', () {
      final withCategory = {
        ...flyerJson(),
        'products': {
          'h1': {
            'productId': '1',
            'title': 'Test',
            'categoryPrimary': 'Kategorien/Baumarkt/Werkstatt/Kompressoren',
          },
        },
      };
      final offer = mapper.flyer(withCategory, lidl, report).offers.single;
      expect(offer.categories, ['Baumarkt', 'Werkstatt', 'Kompressoren']);
    });

    test('behaelt die Artikelnummer des Haendlers', () {
      final brochure = mapper.flyer(flyerJson(), kaufland, report);
      expect(brochure.offers.first.externalProductId, isNotEmpty);
      expect(brochure.offers.first.id, brochure.offers.first.externalProductId);
    });

    test('ueberspringt ein Produkt ohne productId', () {
      final broken = {
        ...flyerJson(),
        'products': {
          'h1': {'title': 'Ohne ID'},
        },
      };
      final brochure = mapper.flyer(broken, kaufland, report);
      expect(brochure.offers, isEmpty);
      expect(report.skipped, 1);
    });
  });

  group('Datumsformate', () {
    test('liest beide von der Quelle genutzten Formate', () {
      // Die Uebersicht nutzt ISO, der Detailabruf US-Notation.
      final iso = mapper.overviewEntry(
        {'id': 'a', 'startDate': '2026-08-08', 'endDate': '2026-08-15'},
        lidl,
        report,
      )!;
      expect(iso.validFrom, DateTime.utc(2026, 8, 8));
      expect(iso.validUntil, DateTime.utc(2026, 8, 15));

      final us = mapper.overviewEntry(
        {
          'id': 'b',
          'startDate': '08/09/2026 00:00:00',
          'endDate': '08/14/2026 23:59:59',
        },
        lidl,
        report,
      )!;
      expect(us.validFrom, DateTime.utc(2026, 8, 9));
      expect(us.validUntil, DateTime.utc(2026, 8, 14, 23, 59, 59));
    });

    test('liefert null statt zu werfen bei unbekanntem Format', () {
      final brochure = mapper.overviewEntry(
        {'id': 'c', 'startDate': 'irgendwann'},
        lidl,
        report,
      )!;
      expect(brochure.validFrom, isNull);
    });
  });

  group('Mandanten', () {
    test('kennt Lidl und Kaufland mit passender Regionspflicht', () {
      expect(SchwarzApi.clientFor('lidl')!.requiresRegion, isFalse);
      expect(SchwarzApi.clientFor('kaufland')!.requiresRegion, isTrue);
      expect(SchwarzApi.clientFor('kaufland')!.fallbackRegion, '3000');
      expect(SchwarzApi.clientFor('rewe'), isNull);
    });

    test('hinterlegt keinen Regionscode im Binding', () {
      // Ein Code im Binding gaelte als ausdrueckliche Ortswahl und wuerde die
      // Aufloesung aus Koordinaten verhindern. Genau dieser fest verdrahtete
      // Wert lieferte vorher allen Nutzern die Prospekte einer fremden Filiale.
      final retailer = mapper.retailer(kaufland);
      expect(retailer.id, 'kaufland');
      expect(retailer.bindings.single.params, isEmpty);

      expect(mapper.retailer(lidl).bindings.single.params, isEmpty);
    });
  });
}
