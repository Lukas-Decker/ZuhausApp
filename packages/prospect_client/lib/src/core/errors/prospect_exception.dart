/// Basis aller Fehler des Moduls.
///
/// Sealed, damit Aufrufer mit `switch` vollstaendig abdecken koennen und der
/// Compiler fehlende Faelle meldet. Ausserhalb des Moduls soll dieser Typ
/// normalerweise gar nicht geworfen werden: das Repository sammelt Fehler in
/// [SourceResult.errors], statt sie bis zur UI durchzureichen.
sealed class ProspectException implements Exception {
  const ProspectException(this.message, {this.sourceId, this.cause});

  final String message;

  /// Adapter, in dem der Fehler auftrat. Null bei quellenuebergreifenden Fehlern.
  final String? sourceId;

  /// Urspruenglicher Fehler, falls dieser eingepackt wurde.
  final Object? cause;

  /// Ob ein erneuter Versuch sinnvoll sein kann.
  bool get isRetryable => switch (this) {
        NetworkFailure() => true,
        RequestTimeout() => true,
        RateLimited() => true,
        SourceUnavailable() => true,
        NotFound() => false,
        AccessDenied() => false,
        ResponseParseFailure() => false,
        UnsupportedBySource() => false,
        ConfigurationError() => false,
      };

  /// Kurzform fuer Logs und CLI-Ausgabe.
  String get code => switch (this) {
        NetworkFailure() => 'network',
        RequestTimeout() => 'timeout',
        RateLimited() => 'rate_limit',
        SourceUnavailable() => 'source_unavailable',
        NotFound() => 'not_found',
        AccessDenied() => 'access_denied',
        ResponseParseFailure() => 'parse_error',
        UnsupportedBySource() => 'unsupported',
        ConfigurationError() => 'config_error',
      };

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        if (sourceId != null) 'sourceId': sourceId,
        'retryable': isRetryable,
      };

  @override
  String toString() =>
      '[$code]${sourceId != null ? ' ($sourceId)' : ''} $message';
}

/// Kein Netz, DNS-Fehler, TLS-Fehler, Verbindung abgebrochen.
final class NetworkFailure extends ProspectException {
  const NetworkFailure(super.message, {super.sourceId, super.cause});
}

/// Zeitueberschreitung beim Request.
final class RequestTimeout extends ProspectException {
  const RequestTimeout(super.message, {required this.timeout, super.sourceId});

  final Duration timeout;
}

/// HTTP 429. [retryAfter] stammt aus dem gleichnamigen Header, falls gesetzt.
final class RateLimited extends ProspectException {
  const RateLimited(super.message, {this.retryAfter, super.sourceId});

  final Duration? retryAfter;

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        if (retryAfter != null) 'retryAfterSeconds': retryAfter!.inSeconds,
      };
}

/// HTTP 5xx oder sonstige Stoerung auf Anbieterseite.
final class SourceUnavailable extends ProspectException {
  const SourceUnavailable(super.message, {this.statusCode, super.sourceId});

  final int? statusCode;
}

/// HTTP 404, oder die angeforderte Ressource existiert in der Quelle nicht.
/// Wird auch fuer abgelaufene und entfernte Prospekte verwendet.
final class NotFound extends ProspectException {
  const NotFound(super.message, {super.sourceId});
}

/// HTTP 401 oder 403.
///
/// Das Modul versucht bewusst nicht, solche Sperren zu umgehen. Der Fehler
/// wird gemeldet und die betroffene Quelle uebersprungen.
final class AccessDenied extends ProspectException {
  const AccessDenied(super.message, {this.statusCode, super.sourceId});

  final int? statusCode;
}

/// Die Antwort war kein gueltiges JSON oder hatte eine unerwartete Struktur.
///
/// Der haeufigste Fall bei inoffiziellen APIs. Einzelne kaputte Eintraege
/// fuehren nicht hierher, die werden vom Mapper uebersprungen und gezaehlt.
/// Dieser Fehler entsteht nur, wenn die gesamte Antwort unbrauchbar ist.
final class ResponseParseFailure extends ProspectException {
  const ResponseParseFailure(
    super.message, {
    super.sourceId,
    super.cause,
    this.bodyPreview,
  });

  /// Erste Zeichen der Antwort, gekuerzt. Hilft beim Debuggen, wenn eine
  /// Quelle unangekuendigt ihr Format aendert.
  final String? bodyPreview;
}

/// Die Quelle unterstuetzt die angefragte Operation nicht.
///
/// Beispiel: Umkreissuche bei Schwarz, das nur Regionscodes kennt. Das ist ein
/// erwarteter Zustand, kein Defekt, und fuehrt zu einem leeren Teilergebnis.
final class UnsupportedBySource extends ProspectException {
  const UnsupportedBySource(super.message, {required this.operation, super.sourceId});

  final String operation;
}

/// Fehlkonfiguration des Moduls selbst, z.B. unbekannte Quellen-ID oder ein
/// nicht beschreibbares Cache-Verzeichnis.
final class ConfigurationError extends ProspectException {
  const ConfigurationError(super.message, {super.cause});
}
