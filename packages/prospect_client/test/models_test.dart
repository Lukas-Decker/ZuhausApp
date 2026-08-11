import 'package:prospect_client/prospect_client.dart';
import 'package:test/test.dart';

void main() {
  group('Price', () {
    test('berechnet den Rabatt aus Streichpreis', () {
      const price = Price(current: 0.75, previous: 0.95, currency: 'EUR');
      expect(price.hasDiscount, isTrue);
      expect(price.discountPercent, 21.1);
    });

    test('meldet keinen Rabatt ohne Streichpreis', () {
      const price = Price(current: 1.49, currency: 'EUR');
      expect(price.hasDiscount, isFalse);
      expect(price.discountPercent, isNull);
    });

    test('meldet keinen Rabatt, wenn der Streichpreis nicht hoeher ist', () {
      // Kommt in echten Daten vor, wenn eine Quelle den Streichpreis
      // faelschlich gleich dem aktuellen Preis setzt.
      const price = Price(current: 2.0, previous: 2.0, currency: 'EUR');
      expect(price.discountPercent, isNull);
    });

    test('ueberlebt eine Serialisierungsrunde', () {
      const price = Price(
        current: 0.99,
        previous: 1.29,
        currency: 'EUR',
        basePriceText: '(1 kg = 6.60)',
      );
      expect(Price.fromJson(price.toJson()), price);
    });
  });

  group('Quantity', () {
    test('rechnet Gramm ueber den SI-Faktor in Kilogramm um', () {
      const quantity = Quantity(
        unitSymbol: 'g',
        sizeFrom: 156,
        sizeTo: 156,
        siSymbol: 'kg',
        siFactor: 0.001,
      );
      expect(quantity.sizeInSiUnit, closeTo(0.156, 1e-9));
    });

    test('liefert null, wenn der Faktor fehlt', () {
      const quantity = Quantity(unitSymbol: 'Stueck', sizeFrom: 3);
      expect(quantity.sizeInSiUnit, isNull);
    });
  });

  group('ImageSet', () {
    test('waehlt die beste und die kleinste vorhandene Stufe', () {
      final images = ImageSet(
        thumbnail: Uri.parse('https://example.test/t.jpg'),
        large: Uri.parse('https://example.test/l.jpg'),
      );
      expect(images.best.toString(), 'https://example.test/l.jpg');
      expect(images.smallest.toString(), 'https://example.test/t.jpg');
    });

    test('erkennt den leeren Zustand', () {
      expect(ImageSet.empty.isEmpty, isTrue);
      expect(ImageSet.empty.best, isNull);
    });
  });

  group('GeoPoint', () {
    test('parst gueltige Koordinaten', () {
      final point = GeoPoint.tryParse('52.52, 13.405');
      expect(point?.latitude, 52.52);
      expect(point?.longitude, 13.405);
    });

    test('weist unsinnige Eingaben zurueck', () {
      expect(GeoPoint.tryParse('Berlin'), isNull);
      expect(GeoPoint.tryParse('52.52'), isNull);
      expect(GeoPoint.tryParse('91.0,13.4'), isNull);
      expect(GeoPoint.tryParse('52.5,181.0'), isNull);
    });

    test('berechnet die Distanz Berlin nach Hamburg', () {
      const berlin = GeoPoint(52.52, 13.405);
      const hamburg = GeoPoint(53.55, 9.99);
      // Luftlinie liegt bei rund 255 km.
      expect(berlin.distanceTo(hamburg) / 1000, closeTo(255, 5));
    });
  });

  group('BrochureId', () {
    test('trennt am ersten Doppelpunkt', () {
      final id = BrochureId.tryParse('schwarz:kaufland.019fa326-84d2');
      expect(id?.sourceId, 'schwarz');
      expect(id?.nativeId, 'kaufland.019fa326-84d2');
    });

    test('weist unvollstaendige IDs zurueck', () {
      expect(BrochureId.tryParse('tjek'), isNull);
      expect(BrochureId.tryParse(':abc'), isNull);
      expect(BrochureId.tryParse('tjek:'), isNull);
    });
  });

  group('BrochureContentLevel', () {
    test('unterscheidet ungeprueft von geprueft ohne Produkte', () {
      // Der Kern der Modellierung: "noch nicht geprueft" darf nicht als
      // "keine Produkte" durchgehen. Der Kaufland-Wochenprospekt hat 422
      // Produkte, die in der Uebersicht nur nicht mitkommen.
      expect(BrochureContentLevel.unknown.isDetermined, isFalse);
      expect(BrochureContentLevel.unknown.hasProducts, isFalse);
      expect(BrochureContentLevel.imagesOnly.isDetermined, isTrue);
      expect(BrochureContentLevel.imagesOnly.hasProducts, isFalse);
      expect(BrochureContentLevel.productsWithoutPrices.hasProducts, isTrue);
      expect(BrochureContentLevel.productsWithoutPrices.hasPrices, isFalse);
      expect(BrochureContentLevel.productsWithPrices.hasPrices, isTrue);
    });
  });

  group('Brochure', () {
    Brochure make({DateTime? from, DateTime? until}) => Brochure(
          id: const BrochureId('tjek', 'abc'),
          retailerId: 'netto',
          title: 'Test',
          contentLevel: BrochureContentLevel.imagesOnly,
          validFrom: from,
          validUntil: until,
        );

    test('erkennt abgelaufene Prospekte', () {
      final brochure = make(until: DateTime.utc(2020, 1, 1));
      expect(brochure.isExpiredAt(DateTime.utc(2026, 1, 1)), isTrue);
      expect(brochure.isActiveAt(DateTime.utc(2026, 1, 1)), isFalse);
    });

    test('erkennt noch nicht gestartete Prospekte', () {
      final brochure = make(
        from: DateTime.utc(2030, 1, 1),
        until: DateTime.utc(2030, 2, 1),
      );
      expect(brochure.isExpiredAt(DateTime.utc(2026, 1, 1)), isFalse);
      expect(brochure.isActiveAt(DateTime.utc(2026, 1, 1)), isFalse);
    });

    test('gilt ohne Enddatum nicht als abgelaufen', () {
      expect(make().isExpiredAt(DateTime.utc(2026, 1, 1)), isFalse);
    });

    test('ueberlebt eine Serialisierungsrunde mit Seiten und Angeboten', () {
      final original = Brochure(
        id: const BrochureId('schwarz', 'kaufland.abc'),
        retailerId: 'kaufland',
        title: 'Prospekt',
        contentLevel: BrochureContentLevel.productsWithoutPrices,
        validFrom: DateTime.utc(2026, 8, 5),
        validUntil: DateTime.utc(2026, 8, 11),
        pageCount: 2,
        coverage: BrochureCoverage.storeBound,
        regionCodes: const ['8920'],
        pages: const [
          BrochurePage(
            number: 1,
            hotspots: [
              Hotspot(left: 1.5, top: 2.5, width: 10, height: 20, offerId: 'x'),
            ],
          ),
        ],
        offers: const [Offer(id: 'x', title: 'Ware')],
      );

      final restored = Brochure.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.contentLevel, original.contentLevel);
      expect(restored.coverage, BrochureCoverage.storeBound);
      expect(restored.regionCodes, ['8920']);
      expect(restored.validUntil, original.validUntil);
      expect(restored.pages.single.hotspots.single.offerId, 'x');
      expect(restored.offers.single.title, 'Ware');
    });
  });

  group('Retailer', () {
    test('fuehrt Bindings mehrerer Quellen zusammen ohne Duplikate', () {
      // Der reale Fall: Kaufland kommt aus Tjek und aus Schwarz.
      const fromTjek = Retailer(
        id: 'kaufland',
        name: 'Kaufland',
        bindings: [SourceBinding(sourceId: 'tjek', nativeId: 'L5IgL3')],
      );
      const fromSchwarz = Retailer(
        id: 'kaufland',
        name: 'Kaufland',
        website: 'https://filiale.kaufland.de',
        bindings: [
          SourceBinding(
            sourceId: 'schwarz',
            nativeId: 'kaufland/de-DE',
            params: {'region_id': '3000'},
          ),
        ],
      );

      final merged = fromTjek.mergedWith(fromSchwarz).mergedWith(fromSchwarz);
      expect(merged.bindings, hasLength(2));
      expect(merged.website, 'https://filiale.kaufland.de');
      expect(merged.bindingFor('tjek')?.nativeId, 'L5IgL3');
      expect(merged.bindingFor('schwarz')?.params['region_id'], '3000');
      expect(merged.bindingFor('bonial'), isNull);
    });
  });

  group('RetailerRegistry', () {
    test('bildet Schreibvarianten auf dieselbe kanonische ID ab', () {
      expect(RetailerRegistry.canonicalId('ALDI Süd'), 'aldi-sued');
      expect(RetailerRegistry.canonicalId('ALDI Sued'), 'aldi-sued');
      expect(RetailerRegistry.canonicalId('aldi süd'), 'aldi-sued');
      expect(RetailerRegistry.canonicalId('Familia Northeast'), 'famila-nordost');
      expect(RetailerRegistry.canonicalId('Netto'), 'netto');
    });

    test('vergibt unbekannten Haendlern einen stabilen Slug', () {
      final id = RetailerRegistry.canonicalId('Müller Markt & Co.');
      expect(id, 'mueller-markt-co');
      expect(RetailerRegistry.canonicalId('Müller Markt & Co.'), id);
      expect(RetailerRegistry.isKnown(id), isFalse);
    });

    test('vereinheitlicht den Anzeigenamen ueber Quellen hinweg', () {
      expect(RetailerRegistry.displayName('penny', 'Penny'), 'PENNY');
      expect(RetailerRegistry.displayName('unbekannt', 'Fallback'), 'Fallback');
    });
  });

  group('Store', () {
    test('setzt die Adresse ohne leere Bestandteile zusammen', () {
      const store = Store(
        id: '1',
        retailerId: 'netto',
        street: 'Koppenstraße 93',
        zipCode: '10243',
        city: 'Berlin',
      );
      expect(store.address, 'Koppenstraße 93, 10243 Berlin');

      const partial = Store(id: '2', retailerId: 'netto', city: 'Berlin');
      expect(partial.address, 'Berlin');
    });
  });
}
