import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../cache/cache_store.dart';
import '../errors/prospect_exception.dart';
import 'cache_policy.dart';

/// Ergebnis eines Abrufs samt Herkunftsinformation.
class ApiResponse {
  ApiResponse({
    required this.body,
    required this.fromCache,
    required this.isStale,
  });

  final String body;

  /// True, wenn der Body aus dem Cache kam, also kein Body uebertragen wurde.
  /// Gilt auch fuer HTTP 304.
  final bool fromCache;

  /// True, wenn ein abgelaufener Cache-Eintrag geliefert wurde, weil das Netz
  /// nicht erreichbar war.
  final bool isStale;

  Object? decodeJson({String? sourceId}) {
    try {
      return jsonDecode(body);
    } on FormatException catch (e) {
      throw ResponseParseFailure(
        'Antwort ist kein gueltiges JSON: ${e.message}',
        sourceId: sourceId,
        cause: e,
        bodyPreview: body.length > 200 ? '${body.substring(0, 200)}...' : body,
      );
    }
  }
}

/// HTTP-Zugriff mit Cache, bedingten Requests, Retry und Drosselung.
///
/// Alle Adapter gehen hierueber. Dadurch gilt die komplette Fehler- und
/// Cache-Strategie einheitlich, und ein neuer Adapter erbt sie automatisch.
class ApiClient {
  ApiClient({
    required this.cache,
    http.Client? httpClient,
    this.policy = CachePolicy.defaults,
    this.timeout = const Duration(seconds: 20),
    this.maxRetries = 2,
    this.minRequestInterval = const Duration(milliseconds: 250),
    this.userAgent = 'prospect_client/0.1 (+https://github.com/local/prospect_client)',
  })  : _http = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  final CacheStore cache;
  final CachePolicy policy;
  final Duration timeout;

  /// Wiederholungen nur bei als wiederholbar markierten Fehlern.
  final int maxRetries;

  /// Mindestabstand zwischen zwei Requests derselben Instanz. Hoeflichkeit
  /// gegenueber den Quellen, und schuetzt vor unbeabsichtigten Lastspitzen.
  final Duration minRequestInterval;

  final String userAgent;

  final http.Client _http;
  final bool _ownsHttpClient;

  DateTime? _lastRequestAt;
  Future<void> _queue = Future.value();

  /// Ruft [url] ab und nutzt dabei den Cache gemaess [kind].
  ///
  /// Ablauf:
  /// 1. Frischer Cache-Eintrag vorhanden, dann ohne Request zurueckgeben.
  /// 2. Abgelaufen, aber mit ETag oder Last-Modified, dann bedingter Request.
  ///    Bei 304 wird nur der Zeitstempel erneuert.
  /// 3. Sonst normaler Request.
  /// 4. Schlaegt der Request fehl und ein abgelaufener Eintrag existiert, wird
  ///    dieser als `isStale` geliefert, statt zu scheitern. Das ist die
  ///    Offline-Faehigkeit.
  Future<ApiResponse> getJson(
    Uri url, {
    required CacheKind kind,
    String? sourceId,
    Map<String, String> headers = const {},
    bool forceRefresh = false,
  }) async {
    final key = url.toString();
    final ttl = policy.forKind(kind);
    final now = DateTime.now();

    CacheEntry? cached;
    try {
      cached = await cache.read(key);
    } on ProspectException {
      cached = null;
    }

    if (!forceRefresh && cached != null && cached.isFreshAt(now)) {
      return ApiResponse(body: cached.body, fromCache: true, isStale: false);
    }

    final requestHeaders = <String, String>{
      'accept': 'application/json',
      'user-agent': userAgent,
      ...headers,
    };
    if (cached != null && cached.canRevalidate) {
      final etag = cached.etag;
      final lastModified = cached.lastModified;
      if (etag != null) requestHeaders['if-none-match'] = etag;
      if (lastModified != null) {
        requestHeaders['if-modified-since'] = lastModified;
      }
    }

    try {
      final response = await _send(url, requestHeaders, sourceId);

      if (response.statusCode == 304 && cached != null) {
        final refreshed = cached.refreshed(DateTime.now(), ttl: ttl);
        await cache.write(key, refreshed);
        return ApiResponse(body: cached.body, fromCache: true, isStale: false);
      }

      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final storedAt = DateTime.now();
      await cache.write(
        key,
        CacheEntry(
          body: body,
          storedAt: storedAt,
          // TTL null heisst sofort veraltet, nicht unbegrenzt frisch. Genau so
          // wirkt CachePolicy.alwaysRevalidate: der Eintrag bleibt erhalten und
          // liefert weiter ETag und Last-Modified fuer bedingte Requests, gilt
          // aber nie als frisch.
          expiresAt: storedAt.add(ttl),
          etag: response.headers['etag'],
          lastModified: response.headers['last-modified'],
        ),
      );
      return ApiResponse(body: body, fromCache: false, isStale: false);
    } on ProspectException {
      // Netz weg, aber wir haben noch etwas Altes: das ist besser als nichts.
      if (cached != null) {
        return ApiResponse(body: cached.body, fromCache: true, isStale: true);
      }
      rethrow;
    }
  }

  Future<http.Response> _send(
    Uri url,
    Map<String, String> headers,
    String? sourceId,
  ) async {
    ProspectException? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        final backoff = _backoffFor(attempt, lastError);
        await Future<void>.delayed(backoff);
      }

      await _throttle();

      try {
        final response = await _http.get(url, headers: headers).timeout(timeout);
        final error = _errorForStatus(response, sourceId);
        if (error == null) return response;
        lastError = error;
        if (!error.isRetryable) throw error;
      } on TimeoutException {
        lastError = RequestTimeout(
          'Zeitueberschreitung nach ${timeout.inSeconds}s bei $url',
          timeout: timeout,
          sourceId: sourceId,
        );
      } on SocketException catch (e) {
        lastError = NetworkFailure(
          'Netzwerkfehler bei $url: ${e.message}',
          sourceId: sourceId,
          cause: e,
        );
      } on http.ClientException catch (e) {
        lastError = NetworkFailure(
          'HTTP-Fehler bei $url: ${e.message}',
          sourceId: sourceId,
          cause: e,
        );
      } on HandshakeException catch (e) {
        lastError = NetworkFailure(
          'TLS-Fehler bei $url: ${e.message}',
          sourceId: sourceId,
          cause: e,
        );
      }
    }

    throw lastError ??
        NetworkFailure('Unbekannter Fehler bei $url', sourceId: sourceId);
  }

  /// Exponentieller Backoff, aber ein `Retry-After` der Quelle hat Vorrang.
  Duration _backoffFor(int attempt, ProspectException? error) {
    if (error is RateLimited && error.retryAfter != null) {
      return error.retryAfter!;
    }
    return Duration(milliseconds: 300 * (1 << (attempt - 1)));
  }

  ProspectException? _errorForStatus(http.Response response, String? sourceId) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return null;
    if (status == 304) return null;

    return switch (status) {
      404 => NotFound('Nicht gefunden: ${response.request?.url}', sourceId: sourceId),
      401 || 403 => AccessDenied(
          'Zugriff verweigert (HTTP $status) auf ${response.request?.url}. '
          'Die Quelle schuetzt diese Ressource, das Modul umgeht das nicht.',
          statusCode: status,
          sourceId: sourceId,
        ),
      429 => RateLimited(
          'Rate Limit erreicht bei ${response.request?.url}',
          retryAfter: _retryAfter(response.headers['retry-after']),
          sourceId: sourceId,
        ),
      >= 500 => SourceUnavailable(
          'Quelle antwortet mit HTTP $status',
          statusCode: status,
          sourceId: sourceId,
        ),
      _ => SourceUnavailable(
          'Unerwarteter Status HTTP $status',
          statusCode: status,
          sourceId: sourceId,
        ),
    };
  }

  Duration? _retryAfter(String? header) {
    if (header == null) return null;
    final seconds = int.tryParse(header.trim());
    if (seconds != null) return Duration(seconds: seconds.clamp(0, 300));
    final date = HttpDate.parse(header);
    final delta = date.difference(DateTime.now());
    return delta.isNegative ? null : delta;
  }

  /// Serialisiert Requests und haelt [minRequestInterval] ein.
  Future<void> _throttle() {
    if (minRequestInterval == Duration.zero) return Future.value();
    final completer = Completer<void>();
    _queue = _queue.then((_) async {
      final last = _lastRequestAt;
      if (last != null) {
        final elapsed = DateTime.now().difference(last);
        if (elapsed < minRequestInterval) {
          await Future<void>.delayed(minRequestInterval - elapsed);
        }
      }
      _lastRequestAt = DateTime.now();
      completer.complete();
    });
    return completer.future;
  }

  void close() {
    if (_ownsHttpClient) _http.close();
  }
}
