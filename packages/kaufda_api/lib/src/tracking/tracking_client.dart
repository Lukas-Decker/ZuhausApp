import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions.dart';
import '../session.dart';
import '../util/iso_datetime.dart';
import 'tracking_context.dart';
import 'tracking_events.dart';

/// Ergebnis eines Batch-Uploads.
class BatchTrackingResult {
  const BatchTrackingResult({required this.eventCount, required this.results});

  factory BatchTrackingResult.fromJson(Map<String, dynamic> json) =>
      BatchTrackingResult(
        eventCount: json['nb_events'] as int? ?? 0,
        results:
            (json['events'] as List?)?.map((e) => '$e').toList() ?? const [],
      );

  final int eventCount;

  /// Pro Event ein Status, in der Praxis `OK`.
  final List<String> results;

  bool get allAccepted =>
      results.isNotEmpty && results.every((e) => e.toUpperCase() == 'OK');

  @override
  String toString() => 'BatchTrackingResult($eventCount, $results)';
}

/// Client fuer die Tracking-Schnittstelle `tk.kaufda.de/v3s`.
///
/// Der Endpunkt authentifiziert sich mit demselben Session-JWT wie die
/// Content-Viewer-API, hier aber als `Authorization: Bearer ...`.
///
/// ```dart
/// final tracking = TrackingClient(
///   sessionProvider: client.sessionProvider,
///   context: TrackingContext(geo: location),
/// );
/// await tracking.send(const WebPageViewEvent());
/// ```
class TrackingClient {
  TrackingClient({
    required SessionProvider sessionProvider,
    http.Client? httpClient,
    Uri? baseUri,
    this.context = const TrackingContext(),
    this.apiConsumer = 'web-user-sdk',
    this.origin = 'https://www.kaufda.de',
    this.userAgent,
    this.sendBrowserHeaders = true,
  })  : _sessionProvider = sessionProvider,
        _http = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        baseUri = baseUri ?? defaultBaseUri;

  /// Basis der Tracking-API.
  static final Uri defaultBaseUri = Uri.https('tk.kaufda.de', '/v3s/');

  final SessionProvider _sessionProvider;
  final http.Client _http;
  final bool _ownsHttpClient;

  final Uri baseUri;

  /// Statischer Teil aller Events.
  final TrackingContext context;

  /// Wert des Headers `Bonial-Api-Consumer`.
  final String apiConsumer;
  final String origin;
  final String? userAgent;

  /// Sendet `Origin` und `User-Agent`. In Flutter Web ohne Wirkung, weil der
  /// Browser diese Header selbst setzt.
  final bool sendBrowserHeaders;

  /// Sendet ein einzelnes Event an `POST /v3s/compound-event`.
  Future<void> send(TrackingEvent event) async {
    final session = await _sessionProvider.session();
    final uri = baseUri
        .resolve('compound-event')
        .replace(queryParameters: {'eventName': event.name});
    await _post(uri, event.toJson(context, session), session);
  }

  /// Sendet mehrere Events an `POST /v3s/batch-compound-event`.
  Future<BatchTrackingResult> sendBatch(List<TrackingEvent> events) async {
    if (events.isEmpty) {
      return const BatchTrackingResult(eventCount: 0, results: []);
    }
    final session = await _sessionProvider.session();
    final uri = baseUri.resolve('batch-compound-event');
    final body = <String, dynamic>{
      'events': [for (final event in events) event.toJson(context, session)],
      'batch_local_datetime': formatLocalIso8601(DateTime.now()),
    };
    final response = await _post(uri, body, session);
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      return BatchTrackingResult(eventCount: events.length, results: const []);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return BatchTrackingResult(
        eventCount: events.length,
        results: [trimmed],
      );
    }
    if (decoded is Map<String, dynamic>) {
      return BatchTrackingResult.fromJson(decoded);
    }
    return BatchTrackingResult(eventCount: events.length, results: [trimmed]);
  }

  Future<String> _post(
    Uri uri,
    Map<String, dynamic> body,
    KaufdaSession session,
  ) async {
    final http.Response response;
    try {
      response = await _http.post(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': session.authorizationHeader,
          'Bonial-Api-Consumer': apiConsumer,
          if (sendBrowserHeaders) ...{
            'Origin': origin,
            if (userAgent != null) 'User-Agent': userAgent!,
          },
        },
        body: jsonEncode(body),
      );
    } on http.ClientException catch (error) {
      throw KaufdaException(
          'Tracking an $uri fehlgeschlagen: ${error.message}');
    }
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw KaufdaHttpException(
        statusCode: response.statusCode,
        uri: uri,
        body: text,
      );
    }
    return text;
  }

  /// Gibt den intern erzeugten HTTP-Client frei.
  void close() {
    if (_ownsHttpClient) _http.close();
  }
}
