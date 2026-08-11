import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP-Client fuer Tests: liefert vorgegebene Antworten und protokolliert die
/// Anfragen, damit Cache- und Retry-Verhalten ueberpruefbar sind.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);

  /// Antwortet mit einem festen Koerper auf jede Anfrage.
  factory FakeHttpClient.json(Object? body, {int status = 200}) =>
      FakeHttpClient((_, __) => FakeResponse(jsonEncode(body), status));

  /// Antwortet nacheinander mit den uebergebenen Antworten. Die letzte wird
  /// wiederholt, wenn mehr Anfragen kommen als Antworten vorliegen.
  factory FakeHttpClient.sequence(List<FakeResponse> responses) {
    var index = 0;
    return FakeHttpClient((_, __) {
      final response = responses[index.clamp(0, responses.length - 1)];
      index++;
      return response;
    });
  }

  final FakeResponse Function(Uri url, Map<String, String> headers) handler;

  /// Alle gestellten Anfragen, in Reihenfolge.
  final List<({Uri url, Map<String, String> headers})> requests = [];

  int get requestCount => requests.length;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add((url: request.url, headers: Map.of(request.headers)));
    final response = handler(request.url, request.headers);

    if (response.throwOnSend != null) throw response.throwOnSend!;

    final bytes = utf8.encode(response.body);
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      contentLength: bytes.length,
    );
  }
}

class FakeResponse {
  FakeResponse(
    this.body,
    this.statusCode, {
    this.headers = const {},
    this.throwOnSend,
  });

  factory FakeResponse.notModified({Map<String, String> headers = const {}}) =>
      FakeResponse('', 304, headers: headers);

  factory FakeResponse.failure(Object error) =>
      FakeResponse('', 0, throwOnSend: error);

  final String body;
  final int statusCode;
  final Map<String, String> headers;
  final Object? throwOnSend;
}
