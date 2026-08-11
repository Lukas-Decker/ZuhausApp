import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaufda_api/kaufda_api.dart';
import 'package:test/test.dart';

const _brochureId = '72a3b683-90ff-4d09-9815-6baebe0a1b1d';
const _location = GeoLocation(lat: 49.6378338, lng: 7.1113922, zip: '55767');

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Session mit einem Token, der weit in der Zukunft ablaeuft.
SessionProvider _session() {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      })))
      .replaceAll('=', '');
  return StaticSessionProvider.fromToken(
    'header.$payload.signature',
    visitId: 'test-visit',
  );
}

http.Response _json(String body) => http.Response(
      body,
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('KaufdaClient', () {
    test('baut die Prospektabfrage wie das Web-Frontend', () async {
      late http.Request seen;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          seen = request;
          return _json(_fixture('brochure.json'));
        }),
      );

      final brochure = await client.brochure(_brochureId);

      expect(seen.url.host, 'content-viewer-be.kaufda.de');
      expect(seen.url.path, '/v1/brochures/$_brochureId');
      expect(seen.url.queryParameters, {
        'partner': 'kaufda_web',
        'brochureKey': '',
        'lat': '49.6378338',
        'lng': '7.1113922',
        'brochureId': _brochureId,
      });
      expect(seen.headers['Bonial-Api-Consumer'], 'web-content-viewer-fe');
      expect(seen.headers['Cookie'], startsWith('sessionToken='));
      expect(seen.headers['Origin'], 'https://www.kaufda.de');
      expect(brochure.title, 'LIDL LOHNT SICH');
    });

    test('sendet Plattform-Header nur bei sidebar, related und lastPage',
        () async {
      final headers = <String, Map<String, String>>{};
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          headers[request.url.path] = request.headers;
          if (request.url.path.endsWith('/pages')) {
            return _json('{"contents": []}');
          }
          return _json(_fixture('sidebar.json'));
        }),
      );

      await client.pages(_brochureId);
      await client.sidebar(_brochureId);

      expect(headers['/v1/brochures/$_brochureId/pages'],
          isNot(contains('delivery_channel')));
      expect(headers['/v1/sidebar']?['delivery_channel'], 'dest.kaufda');
      expect(headers['/v1/sidebar']?['user_platform_os'], 'windows');
    });

    test('haengt die Platzierung an die Related-Abfrage', () async {
      late Uri seen;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          seen = request.url;
          return _json(_fixture('related.json'));
        }),
      );

      final related = await client.related(_brochureId);

      expect(seen.queryParameters['placement'], AdPlacement.nextBrochure);
      expect(related.publisherBrochures, isNotEmpty);
    });

    test('erneuert die Session einmal bei HTTP 401', () async {
      var calls = 0;
      var refreshes = 0;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _RecordingSessionProvider(
          _session(),
          onRefresh: () => refreshes++,
        ),
        httpClient: MockClient((request) async {
          calls++;
          if (calls == 1) return http.Response('nope', 401);
          return _json(_fixture('brochure.json'));
        }),
      );

      final brochure = await client.brochure(_brochureId);

      expect(calls, 2);
      expect(refreshes, 1);
      expect(brochure.id, _brochureId);
    });

    test('meldet einen Fehlerstatus als KaufdaHttpException', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async => http.Response('kaputt', 500)),
      );

      await expectLater(
        client.brochure(_brochureId),
        throwsA(isA<KaufdaHttpException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('nearestStore liefert null bei 404', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async => http.Response('', 404)),
      );

      expect(await client.nearestStore(_brochureId), isNull);
    });

    test('bundle sammelt alle Endpunkte ein', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/pages')) return _json(_fixture('pages.json'));
          if (path.endsWith('/nearestStore')) {
            return _json(_fixture('nearest_store.json'));
          }
          if (path.endsWith('/related')) return _json(_fixture('related.json'));
          if (path.endsWith('/sidebar')) return _json(_fixture('sidebar.json'));
          if (path.endsWith('/lastPage')) {
            return _json(_fixture('last_page.json'));
          }
          return _json(_fixture('brochure.json'));
        }),
      );

      final bundle = await client.bundle(_brochureId);

      expect(bundle.pages, hasLength(73));
      expect(bundle.offers.length, greaterThan(300));
      expect(bundle.nearestStore?.id, 'DE-34429');
      expect(bundle.sidebar.all, isNotEmpty);
    });

    test('search baut die Abfrage und liest die Metadaten', () async {
      late Uri seen;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          seen = request.url;
          return _json(_fixture('search_lidl.json'));
        }),
      );

      final result = await client.search(
        '  Lidl  ',
        limit: 12,
        offset: 24,
        sort: SearchSort.price,
      );

      expect(seen.path, '/api/search');
      expect(seen.queryParameters, {
        'lat': '49.6378338',
        'lng': '7.1113922',
        'query': 'Lidl',
        'limit': '12',
        'offset': '24',
        'sort': 'price',
      });

      expect(result.metadata.searchType, 'retailer');
      expect(result.metadata.isRetailerSearch, isTrue);
      expect(result.metadata.brochureCount, 12);
      expect(result.metadata.offerCount, greaterThan(100));
      expect(result.metadata.retailer?.id, 'DE-1013');
      expect(result.metadata.retailer?.value, 'Lidl');
      expect(result.metadata.sorts, contains(SearchSort.validityEnd));
      expect(result.metadata.publisherFacets, isNotEmpty);

      final brochure = result.brochureContents.first;
      expect(brochure.id, isNotEmpty);
      expect(brochure.publisher.name, isNotEmpty);
      expect(brochure.distance, isNotNull);
      expect(brochure.pageCount, greaterThan(0));

      final offer = result.offers.first;
      expect(offer.title, isNotEmpty);
      expect(offer.price?.mainPrice, isNotNull);
      expect(offer.price?.mainPriceFormatted, contains('€'));
      expect(offer.parent?.id, isNotEmpty);
      expect(offer.imageThumbnail, startsWith('https://'));
    });

    test('search laesst offset weg, wenn es 0 ist', () async {
      late Uri seen;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          seen = request.url;
          return _json(_fixture('search_lidl.json'));
        }),
      );

      await client.search('Lidl');

      expect(seen.queryParameters.containsKey('offset'), isFalse);
      expect(seen.queryParameters.containsKey('sort'), isFalse);
    });

    test('search weist einen leeren Begriff ab', () {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async => _json('{}')),
      );

      expect(() => client.search('   '), throwsArgumentError);
    });

    test('searchRetailer filtert auf den erkannten Haendler', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient(
          (_) async => _json(_fixture('search_lidl.json')),
        ),
      );

      final found = await client.searchRetailer('Lidl');

      expect(found.isRetailer, isTrue);
      expect(found.publisherId, 'DE-1013');
      expect(found.publisherName, 'Lidl');
      expect(found.brochures, isNotEmpty);
      // Die Suche mischt fremde Haendler bei, die hier rausfallen muessen.
      expect(
        found.brochures.every((e) => e.publisher.id == 'DE-1013'),
        isTrue,
      );
      expect(found.brochures.length, lessThan(found.result.brochures.length));
      expect(found.offers.every((e) => e.publisherId == 'DE-1013'), isTrue);
    });

    test('searchRetailer kann die Angebote weglassen', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient(
          (_) async => _json(_fixture('search_lidl.json')),
        ),
      );

      final found = await client.searchRetailer('Lidl', includeOffers: false);

      expect(found.offers, isEmpty);
      expect(found.brochures, isNotEmpty);
    });

    test('searchRetailer faellt auf den Facettennamen zurueck', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async {
          final json =
              jsonDecode(_fixture('search_lidl.json')) as Map<String, dynamic>;
          // Kein Haendler erkannt, aber die Facette kennt ihn noch.
          ((json['searchResults'] as Map<String, dynamic>)['metadata']
              as Map<String, dynamic>)['recognizedEntities'] = <dynamic>[];
          return _json(jsonEncode(json));
        }),
      );

      final found = await client.searchRetailer('netto marken');

      expect(found.publisherId, 'DE-1034');
      expect(found.publisherName, 'Netto Marken-Discount');
      expect(found.brochures.every((e) => e.publisher.id == 'DE-1034'), isTrue);
    });

    test('searchRetailer meldet, wenn kein Haendler erkannt wurde', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async {
          final json =
              jsonDecode(_fixture('search_lidl.json')) as Map<String, dynamic>;
          final metadata = (json['searchResults']
              as Map<String, dynamic>)['metadata'] as Map<String, dynamic>;
          metadata['recognizedEntities'] = <dynamic>[];
          metadata['filters'] = <dynamic>[];
          metadata['searchType'] = 'other';
          return _json(jsonEncode(json));
        }),
      );

      final found = await client.searchRetailer('Quatschladen123');

      expect(found.isRetailer, isFalse);
      expect(found.publisherId, isNull);
      // Ohne erkannten Haendler wird nicht gefiltert.
      expect(found.brochures.length, found.result.brochures.length);
    });

    test('shelf fragt den Umkreis-Endpunkt mit allen Parametern ab', () async {
      late Uri seen;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          seen = request.url;
          return _json(_fixture('shelf.json'));
        }),
      );

      final result = await client.shelf(
        size: 24,
        sectorIds: const [KaufdaSector.discounter, KaufdaSector.supermarkt],
      );

      expect(seen.host, 'www.kaufda.de');
      expect(seen.path, '/api/shelf');
      expect(seen.queryParameters, {
        'lat': '49.6378338',
        'lng': '7.1113922',
        'size': '24',
        'page': '0',
        'sectorIds': 'DE-22,DE-48',
      });

      expect(result.page.number, 0);
      expect(result.page.totalElements, 37);
      expect(result.page.totalPages, 2);
      expect(result.page.hasNext, isTrue);

      // Blog-Karussells liegen im selben Array, sind aber keine Prospekte.
      expect(result.items.length, lessThan(24));
      expect(result.brochures.every((e) => e.id.isNotEmpty), isTrue);

      final first = result.brochures.first;
      expect(first.publisher.name, isNotEmpty);
      expect(first.pageCount, greaterThan(0));
      expect(first.image, startsWith('https://'));
      expect(first.closestStore?.address, isNotEmpty);
      expect(result.items.first.placement, isNotNull);
    });

    test('shelfAll blaettert bis zur letzten Seite', () async {
      final pages = <String>[];
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          final page = request.url.queryParameters['page']!;
          pages.add(page);
          final json =
              jsonDecode(_fixture('shelf.json')) as Map<String, dynamic>;
          // Zweite Seite als letzte markieren.
          (json['page'] as Map<String, dynamic>)['number'] = int.parse(page);
          return _json(jsonEncode(json));
        }),
      );

      final all = await client.shelfAll(pageSize: 24, maxPages: 5);

      expect(pages, ['0', '1']);
      // Beide Seiten liefern dieselben Prospekte, das Ergebnis ist entdoppelt.
      expect(all.map((e) => e.id).toSet().length, all.length);
    });

    test('shelfAll bricht bei maxPages ab', () async {
      var calls = 0;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async {
          calls++;
          final json =
              jsonDecode(_fixture('shelf.json')) as Map<String, dynamic>;
          (json['page'] as Map<String, dynamic>)['totalPages'] = 99;
          return _json(jsonEncode(json));
        }),
      );

      await client.shelfAll(maxPages: 3);

      expect(calls, 3);
    });

    test('nearbyBrochures sammelt Prospekte aus allen drei Listen', () async {
      final paths = <String>[];
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/related')) {
            return _json(_fixture('related.json'));
          }
          if (request.url.path.endsWith('/lastPage')) {
            return _json(_fixture('last_page.json'));
          }
          return _json(_fixture('sidebar.json'));
        }),
      );

      final found =
          await client.nearbyBrochures(seedBrochureIds: [_brochureId]);

      // Drei Requests pro Einstieg, danach ohne Dubletten und sortiert.
      expect(paths, hasLength(3));
      expect(found.map((e) => e.id).toSet(), hasLength(found.length));
      expect(found.length, greaterThan(3));
      final publishers = found.map((e) => e.publisher.name).toList();
      expect(publishers, orderedEquals(publishers.toList()..sort()));
    });

    test('nearbyBrochures filtert nach Haendler', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async => _json(_fixture('sidebar.json'))),
      );

      final found = await client.nearbyBrochures(
        seedBrochureIds: [_brochureId],
        publisherId: 'DE-1013',
      );

      expect(found, isNotEmpty);
      expect(found.every((e) => e.publisher.id == 'DE-1013'), isTrue);
    });

    test('nearbyBrochures geht mit depth 2 in die Breite', () async {
      var calls = 0;
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async {
          calls++;
          return _json(_fixture('sidebar.json'));
        }),
      );

      await client.nearbyBrochures(
        seedBrochureIds: [_brochureId],
        depth: 2,
        seedsPerRound: 3,
      );

      // Runde 1: drei Requests, Runde 2: drei Einstiege mal drei Requests.
      expect(calls, 3 + 9);
    });

    test('nearbyBrochures ueberspringt tote Start-IDs', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((request) async {
          if (request.url.queryParameters['brochureId'] == 'tot') {
            return http.Response('', 404);
          }
          return _json(_fixture('sidebar.json'));
        }),
      );

      final found = await client.nearbyBrochures(
        seedBrochureIds: ['tot', _brochureId],
        seedsPerRound: 2,
      );

      expect(found, isNotEmpty);
    });

    test('nearbyBrochures meldet, wenn keine Start-ID lebt', () async {
      final client = KaufdaClient(
        location: _location,
        sessionProvider: _session(),
        httpClient: MockClient((_) async => http.Response('', 404)),
      );

      await expectLater(
        client.nearbyBrochures(seedBrochureIds: ['tot']),
        throwsA(isA<KaufdaException>()),
      );
    });

    test('verlangt einen Standort', () {
      final client = KaufdaClient(
        sessionProvider: _session(),
        httpClient: MockClient((_) async => _json('{}')),
      );

      expect(() => client.brochure(_brochureId), throwsArgumentError);
    });
  });
}

class _RecordingSessionProvider implements SessionProvider {
  _RecordingSessionProvider(this._inner, {required this.onRefresh});

  final SessionProvider _inner;
  final void Function() onRefresh;

  @override
  Future<KaufdaSession> session({bool forceRefresh = false}) {
    if (forceRefresh) onRefresh();
    return _inner.session(forceRefresh: forceRefresh);
  }
}
