import 'dart:io';

import 'package:prospect_client/prospect_client.dart';
import 'package:test/test.dart';

import 'support/fake_http_client.dart';

void main() {
  final url = Uri.parse('https://squid-api.tjek.com/v2/dealers?limit=1');

  ApiClient build(
    FakeHttpClient http, {
    CacheStore? cache,
    CachePolicy policy = CachePolicy.defaults,
    int maxRetries = 0,
  }) =>
      ApiClient(
        cache: cache ?? MemoryCacheStore(),
        httpClient: http,
        policy: policy,
        maxRetries: maxRetries,
        // Drosselung aus, sonst warten die Tests unnoetig.
        minRequestInterval: Duration.zero,
      );

  group('Caching', () {
    test('beantwortet den zweiten Aufruf ohne Netzwerkzugriff', () async {
      final http = FakeHttpClient.json([
        {'id': 'a'}
      ]);
      final client = build(http);

      final first = await client.getJson(url, kind: CacheKind.retailers);
      final second = await client.getJson(url, kind: CacheKind.retailers);

      expect(first.fromCache, isFalse);
      expect(second.fromCache, isTrue);
      expect(http.requestCount, 1, reason: 'Der Cache muss den Request sparen');
    });

    test('sendet bei abgelaufenem Eintrag If-None-Match', () async {
      final http = FakeHttpClient.sequence([
        FakeResponse('[{"id":"a"}]', 200, headers: {'etag': 'W/"v1"'}),
        FakeResponse.notModified(),
      ]);
      // TTL null: nichts gilt als frisch, ETags werden aber weiter genutzt.
      final client = build(http, policy: CachePolicy.alwaysRevalidate);

      await client.getJson(url, kind: CacheKind.retailers);
      final second = await client.getJson(url, kind: CacheKind.retailers);

      expect(http.requestCount, 2);
      expect(http.requests[1].headers['if-none-match'], 'W/"v1"');
      expect(second.fromCache, isTrue);
      expect(second.isStale, isFalse);
      expect(second.body, '[{"id":"a"}]',
          reason: 'Bei 304 muss der alte Koerper erhalten bleiben');
    });

    test('sendet If-Modified-Since, wenn kein ETag vorliegt', () async {
      const lastModified = 'Mon, 10 Aug 2026 10:00:00 GMT';
      final http = FakeHttpClient.sequence([
        FakeResponse('[]', 200, headers: {'last-modified': lastModified}),
        FakeResponse.notModified(),
      ]);
      final client = build(http, policy: CachePolicy.alwaysRevalidate);

      await client.getJson(url, kind: CacheKind.retailers);
      await client.getJson(url, kind: CacheKind.retailers);

      expect(http.requests[1].headers['if-modified-since'], lastModified);
    });

    test('umgeht den Cache bei forceRefresh', () async {
      final http = FakeHttpClient.json([]);
      final client = build(http);

      await client.getJson(url, kind: CacheKind.retailers);
      await client.getJson(url, kind: CacheKind.retailers, forceRefresh: true);

      expect(http.requestCount, 2);
    });
  });

  group('Offline-Verhalten', () {
    test('liefert abgelaufene Daten, wenn das Netz ausfaellt', () async {
      final cache = MemoryCacheStore();
      final good = FakeHttpClient.json([
        {'id': 'a'}
      ]);
      await build(good, cache: cache, policy: CachePolicy.alwaysRevalidate)
          .getJson(url, kind: CacheKind.retailers);

      final broken = FakeHttpClient(
        (_, __) => FakeResponse.failure(
          const SocketException('Netzwerk nicht erreichbar'),
        ),
      );
      final response =
          await build(broken, cache: cache, policy: CachePolicy.alwaysRevalidate)
              .getJson(url, kind: CacheKind.retailers);

      expect(response.isStale, isTrue);
      expect(response.fromCache, isTrue);
      expect(response.body, '[{"id":"a"}]');
    });

    test('wirft, wenn weder Netz noch Cache verfuegbar sind', () async {
      final broken = FakeHttpClient(
        (_, __) => FakeResponse.failure(const SocketException('kein Netz')),
      );
      await expectLater(
        build(broken).getJson(url, kind: CacheKind.retailers),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  group('Fehlerabbildung', () {
    Future<void> expectError(int status, Matcher matcher) async {
      final http = FakeHttpClient((_, __) => FakeResponse('', status));
      await expectLater(
        build(http).getJson(url, kind: CacheKind.retailers),
        throwsA(matcher),
      );
    }

    test('404 wird zu NotFound', () => expectError(404, isA<NotFound>()));

    test('403 wird zu AccessDenied', () async {
      // Wichtig: das Modul umgeht solche Sperren nicht, es meldet sie.
      await expectError(403, isA<AccessDenied>());
    });

    test('401 wird zu AccessDenied', () => expectError(401, isA<AccessDenied>()));

    test('500 wird zu SourceUnavailable',
        () => expectError(500, isA<SourceUnavailable>()));

    test('429 wird zu RateLimited mit Retry-After', () async {
      final http = FakeHttpClient(
        (_, __) => FakeResponse('', 429, headers: {'retry-after': '7'}),
      );
      await expectLater(
        build(http).getJson(url, kind: CacheKind.retailers),
        throwsA(
          isA<RateLimited>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 7),
          ),
        ),
      );
    });

    test('ungueltiges JSON wird zu ResponseParseFailure', () async {
      final http = FakeHttpClient((_, __) => FakeResponse('kein json', 200));
      final response =
          await build(http).getJson(url, kind: CacheKind.retailers);
      expect(
        () => response.decodeJson(sourceId: 'tjek'),
        throwsA(isA<ResponseParseFailure>()),
      );
    });
  });

  group('Retry', () {
    test('wiederholt wiederholbare Fehler und liefert dann aus', () async {
      final http = FakeHttpClient.sequence([
        FakeResponse('', 503),
        FakeResponse('[]', 200),
      ]);
      final client = build(http, maxRetries: 2);

      final response = await client.getJson(url, kind: CacheKind.retailers);
      expect(response.body, '[]');
      expect(http.requestCount, 2);
    });

    test('wiederholt nicht wiederholbare Fehler nicht', () async {
      final http = FakeHttpClient((_, __) => FakeResponse('', 404));
      await expectLater(
        build(http, maxRetries: 3).getJson(url, kind: CacheKind.retailers),
        throwsA(isA<NotFound>()),
      );
      expect(http.requestCount, 1, reason: '404 wird sich nicht bessern');
    });
  });

  group('Fehlerklassifikation', () {
    test('markiert wiederholbare und endgueltige Fehler korrekt', () {
      expect(const NetworkFailure('x').isRetryable, isTrue);
      expect(const RateLimited('x').isRetryable, isTrue);
      expect(const SourceUnavailable('x').isRetryable, isTrue);
      expect(const NotFound('x').isRetryable, isFalse);
      expect(const AccessDenied('x').isRetryable, isFalse);
      expect(const ResponseParseFailure('x').isRetryable, isFalse);
    });

    test('serialisiert Fehler mit Code und Quelle', () {
      const error = AccessDenied('gesperrt', statusCode: 403, sourceId: 'tjek');
      expect(error.toJson(), {
        'code': 'access_denied',
        'message': 'gesperrt',
        'sourceId': 'tjek',
        'retryable': false,
      });
    });
  });
}
