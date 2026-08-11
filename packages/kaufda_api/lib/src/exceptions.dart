/// Basisklasse aller Fehler dieses Clients.
class KaufdaException implements Exception {
  const KaufdaException(this.message);

  final String message;

  @override
  String toString() => 'KaufdaException: $message';
}

/// Die API hat mit einem Fehlerstatus geantwortet.
class KaufdaHttpException extends KaufdaException {
  const KaufdaHttpException({
    required this.statusCode,
    required this.uri,
    required this.body,
  }) : super('HTTP $statusCode');

  final int statusCode;
  final Uri uri;
  final String body;

  /// Token abgelaufen oder ungueltig.
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() {
    final snippet = body.length > 500 ? '${body.substring(0, 500)}...' : body;
    return 'KaufdaHttpException($statusCode, $uri)\n$snippet';
  }
}

/// Die Antwort war kein verwertbares JSON.
class KaufdaParseException extends KaufdaException {
  const KaufdaParseException(super.message, {required this.uri, this.body});

  final Uri uri;
  final String? body;

  @override
  String toString() => 'KaufdaParseException($uri): $message';
}

/// Der Session-Token konnte nicht beschafft oder erneuert werden.
class KaufdaSessionException extends KaufdaException {
  const KaufdaSessionException(super.message);

  @override
  String toString() => 'KaufdaSessionException: $message';
}
