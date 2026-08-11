import 'dart:convert';
import 'dart:io';

import 'package:kaufda_api/kaufda_api.dart';
import 'package:test/test.dart';

Map<String, dynamic> _fixture(String name) => jsonDecode(
      File('test/fixtures/$name').readAsStringSync(),
    ) as Map<String, dynamic>;

/// Baut einen JWT, dessen `exp`-Claim auf [expiry] steht.
String _jwtWithExpiry(DateTime expiry) {
  final payload = base64Url
      .encode(utf8.encode(
        jsonEncode({'exp': expiry.millisecondsSinceEpoch ~/ 1000}),
      ))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

void main() {
  group('Brochure', () {
    test('liest die Metadaten aus der API-Antwort', () {
      final json = _fixture('brochure.json');
      final brochure =
          Brochure.fromJson(json['content'] as Map<String, dynamic>);

      expect(brochure.id, '72a3b683-90ff-4d09-9815-6baebe0a1b1d');
      expect(brochure.legacyId, 2501214196);
      expect(brochure.title, 'LIDL LOHNT SICH');
      expect(brochure.type, 'static_brochure');
      expect(brochure.pageCount, 73);
      expect(brochure.preview, isFalse);
      expect(brochure.nearestStoreEnabled, isTrue);
      expect(brochure.publisher.id, 'DE-1013');
      expect(brochure.publisher.name, 'Lidl');
      expect(brochure.publisher.logo('128x128')?.url, contains('128x128'));
      expect(brochure.badges.single.name, 'new');
      expect(brochure.headerImage, isNotNull);
      expect(brochure.validFrom, DateTime.parse('2026-08-09T22:00:00.000Z'));
      expect(brochure.validUntil, DateTime.parse('2026-08-15T21:00:00.000Z'));
    });

    test('ueberlebt ein leeres Objekt', () {
      final brochure = Brochure.fromJson(const {});
      expect(brochure.id, isEmpty);
      expect(brochure.pageCount, 0);
      expect(brochure.badges, isEmpty);
    });
  });

  group('Seiten und Angebote', () {
    late List<BrochurePage> pages;

    setUpAll(() {
      final json = _fixture('pages.json');
      pages = (json['contents'] as List)
          .cast<Map<String, dynamic>>()
          .map(BrochurePage.fromJson)
          .toList();
    });

    test('liest alle Seiten', () {
      expect(pages, hasLength(73));
      expect(pages.first.number, 0);
      expect(pages.first.images, hasLength(4));
      expect(pages.first.imageBySize('768x1024'), isNotNull);
      expect(pages.first.largestImage?.size, '2800x2800');
    });

    test('liest Hotspots einer Seite', () {
      final withLinks = pages.firstWhere((p) => p.linkOuts.isNotEmpty);
      final link = withLinks.linkOuts.first;
      expect(link.id, isNotEmpty);
      expect(link.url, startsWith('https://'));
      expect(link.position, isNotNull);
      expect(link.position!.x, inInclusiveRange(0, 1));
    });

    test('liest ein Angebot inklusive Preisen', () {
      final offer = pages.first.offerContents.first;

      expect(offer.id, 'eb1789b6-74cb-4961-b2e1-0d1f19d58224');
      expect(offer.type, 'offer');
      expect(offer.displayName, 'Volvic Tee/Touch');
      expect(
          offer.product?.categoryPaths.first.name, 'Lebensmittel und Getränke');
      expect(offer.deals, hasLength(2));
      expect(offer.specialPrice?.min, 0.99);
      expect(offer.specialPrice?.conditions.single.label, 'Mit Lidl Plus');
      expect(offer.salesPrice?.min, 1.89);
      expect(offer.bestDeal?.type, 'SPECIAL_PRICE');
      expect(offer.parentContent?.pageNumber, 0);
      expect(offer.parentContent?.area?.topLeft.x, closeTo(0.3288, 0.001));
      expect(offer.validFrom, isNotNull);
    });

    test('findet Angebote mit Shop-Link', () {
      final linked = [
        for (final page in pages)
          for (final offer in page.offerContents)
            if (offer.linkOuts.isNotEmpty) offer,
      ];
      expect(linked, isNotEmpty);
      expect(linked.first.linkOuts.first.url, startsWith('https://'));
    });

    test('serialisiert verlustfrei genug fuer einen Roundtrip', () {
      final offer = pages.first.offerContents.first;
      final roundtrip = Offer.fromJson(offer.toJson());
      expect(roundtrip.id, offer.id);
      expect(roundtrip.displayName, offer.displayName);
      expect(roundtrip.deals.length, offer.deals.length);
      expect(roundtrip.bestDeal?.min, offer.bestDeal?.min);
    });
  });

  group('Sammlungen', () {
    test('sidebar liefert alle drei Listen', () {
      final collections =
          BrochureCollections.fromJson(_fixture('sidebar.json'));
      expect(collections.publisherBrochures, hasLength(2));
      expect(collections.sectorBrochures, hasLength(3));
      expect(collections.popularBrochures, isNotEmpty);
      expect(collections.all.length, greaterThan(5));

      final first = collections.publisherBrochures.first;
      expect(first.placement, 'ad_placement__brochure_bar');
      expect(first.content.id, '427287e3-7c93-4b8c-8e66-1d7a49b1785e');
      expect(first.content.legacyId, 2501220189);
      expect(first.content.publisher.name, 'Lidl');
      expect(first.content.badges.single.name, 'valid_soon');
    });

    test('related nutzt die angefragte Platzierung', () {
      final collections =
          BrochureCollections.fromJson(_fixture('related.json'));
      expect(
        collections.all.first.placement,
        AdPlacement.nextBrochure,
      );
    });

    test('lastPage liefert Kacheln fuer die Schlussseite', () {
      final collections =
          BrochureCollections.fromJson(_fixture('last_page.json'));
      expect(
        collections.all.first.placement,
        AdPlacement.lastPageDisplay,
      );
      expect(collections.isEmpty, isFalse);
    });
  });

  group('Store', () {
    test('liest Filiale mit Oeffnungszeiten', () {
      final store = Store.fromJson(_fixture('nearest_store.json'));

      expect(store.id, 'DE-34429');
      expect(store.name, 'Lidl');
      expect(store.address, 'Wasserschieder Straße 44, 55765 Birkenfeld');
      expect(store.distance, closeTo(4.93, 0.01));
      expect(store.isOpen, isFalse);
      expect(store.contactDetails?.emailAddress, 'kontakt@lidl.de');
      expect(store.contactDetails?.telephoneNumbers, ['03022005500']);
      expect(store.openingHours?.regular, hasLength(6));
      expect(store.openingHours?.forWeekday(2).single.displayValue,
          '07:00 - 21:00');
      expect(store.timeZone, 'Europe/Berlin');
    });
  });

  group('Session', () {
    test('liest Token und Ablaufzeit aus sessionData', () {
      final session = KaufdaSession.fromJson(_fixture('session_data.json'));

      expect(session.visitId, 'd5b6f05c-588d-45ab-a8b2-868589c128a9');
      expect(session.userIdent, session.visitId);
      expect(session.optedOut, isTrue);
      expect(session.cookieHeader, startsWith('sessionToken=eyJ'));
      expect(session.authorizationHeader, startsWith('Bearer eyJ'));
      expect(
        session.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1786399386 * 1000, isUtc: true),
      );
    });

    test('erkennt abgelaufene und gueltige Tokens', () {
      KaufdaSession sessionExpiringIn(Duration offset) => KaufdaSession(
            token: _jwtWithExpiry(DateTime.now().add(offset)),
            visitId: 'v',
            userIdent: 'v',
          );

      expect(sessionExpiringIn(const Duration(hours: -1)).isExpired(), isTrue);
      expect(sessionExpiringIn(const Duration(hours: 1)).isExpired(), isFalse);
      // Innerhalb der Karenzzeit gilt der Token bereits als abgelaufen.
      expect(
          sessionExpiringIn(const Duration(seconds: 30)).isExpired(), isTrue);
    });

    test('meldet fehlenden Token', () {
      expect(
        () => KaufdaSession.fromJson(const {'visitId': 'x'}),
        throwsA(isA<KaufdaSessionException>()),
      );
    });
  });
}
