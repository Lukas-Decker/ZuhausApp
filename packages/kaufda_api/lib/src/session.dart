import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'exceptions.dart';

/// Anonyme Session von `GET https://www.kaufda.de/sessionData`.
///
/// Der Token ist ein JWT mit rund 30 Minuten Laufzeit. Er wird von der
/// Content-Viewer-API als Cookie `sessionToken` und vom Tracking als
/// `Authorization: Bearer ...` erwartet.
@immutable
class KaufdaSession {
  KaufdaSession({
    required this.token,
    required this.visitId,
    required this.userIdent,
    this.optedOut = true,
    this.generated = false,
  }) : expiresAt = _expiryFromJwt(token);

  factory KaufdaSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const KaufdaSessionException(
        'sessionData lieferte keinen Token zurueck',
      );
    }
    final visitId = json['visitId'] as String? ?? '';
    return KaufdaSession(
      token: token,
      visitId: visitId,
      userIdent: json['userIdent'] as String? ?? visitId,
      optedOut: json['optedOut'] as bool? ?? true,
      generated: json['generated'] as bool? ?? false,
    );
  }

  /// Roher JWT.
  final String token;

  /// Session-UUID, im Tracking als `session_id` und `web_id` verwendet.
  final String visitId;

  /// Nutzer-UUID, identisch mit [visitId], solange niemand eingeloggt ist.
  final String userIdent;

  /// `true`, wenn kein Tracking-Consent erteilt wurde.
  final bool optedOut;
  final bool generated;

  /// Ablaufzeitpunkt aus dem `exp`-Claim, falls lesbar.
  final DateTime? expiresAt;

  /// Wert fuer den `Cookie`-Header der Content-Viewer-API.
  String get cookieHeader => 'sessionToken=$token';

  /// Wert fuer den `Authorization`-Header des Tracking-Endpunkts.
  String get authorizationHeader => 'Bearer $token';

  /// `true`, wenn der Token innerhalb von [leeway] ablaeuft.
  bool isExpired({Duration leeway = const Duration(seconds: 60)}) {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().toUtc().add(leeway).isAfter(exp);
  }

  static DateTime? _expiryFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map<String, dynamic>) return null;
      final exp = payload['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() =>
      'KaufdaSession($visitId, laeuft ab: ${expiresAt?.toIso8601String()})';
}

/// Liefert dem Client eine gueltige Session.
abstract class SessionProvider {
  /// Aktuelle Session, bei Bedarf frisch geholt.
  Future<KaufdaSession> session({bool forceRefresh = false});
}

/// Holt die Session anonym ueber `https://www.kaufda.de/sessionData`.
///
/// Die Session wird zwischengespeichert und erst kurz vor Ablauf des JWT
/// erneuert. Parallele Aufrufe teilen sich denselben Request.
class WebSessionProvider implements SessionProvider {
  WebSessionProvider({
    http.Client? httpClient,
    Uri? sessionUri,
    this.optOut = true,
    Map<String, String> headers = const {},
  })  : _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null,
        _sessionUri = sessionUri ?? Uri.https('www.kaufda.de', '/sessionData'),
        _headers = headers;

  final http.Client _http;
  final bool _ownsClient;
  final Uri _sessionUri;
  final Map<String, String> _headers;

  /// Wird als `optOut`-Parameter mitgeschickt. `true` entspricht abgelehntem
  /// Tracking-Consent, so wie es das Frontend ohne Zustimmung sendet.
  final bool optOut;

  KaufdaSession? _cached;
  Future<KaufdaSession>? _inFlight;

  @override
  Future<KaufdaSession> session({bool forceRefresh = false}) {
    final cached = _cached;
    if (!forceRefresh && cached != null && !cached.isExpired()) {
      return Future.value(cached);
    }
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<KaufdaSession> _fetch() async {
    final uri = _sessionUri.replace(queryParameters: {
      'optOut': '$optOut',
      'cb': '${DateTime.now().millisecondsSinceEpoch}',
    });
    final http.Response response;
    try {
      response = await _http.get(uri, headers: {
        'Accept': '*/*',
        ..._headers,
      });
    } on Object catch (error) {
      throw KaufdaSessionException('sessionData nicht erreichbar: $error');
    }
    if (response.statusCode != 200) {
      throw KaufdaSessionException(
        'sessionData antwortete mit HTTP ${response.statusCode}',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw KaufdaSessionException('sessionData lieferte kein JSON: $error');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const KaufdaSessionException(
        'sessionData lieferte ein unerwartetes Format',
      );
    }
    return _cached = KaufdaSession.fromJson(decoded);
  }

  /// Schliesst den intern erzeugten HTTP-Client.
  void close() {
    if (_ownsClient) _http.close();
  }
}

/// Nutzt einen bereits vorhandenen Token, z. B. aus dem Browser kopiert.
class StaticSessionProvider implements SessionProvider {
  StaticSessionProvider(this._session);

  /// Baut die Session aus einem rohen JWT.
  factory StaticSessionProvider.fromToken(
    String token, {
    String visitId = '',
    String? userIdent,
  }) =>
      StaticSessionProvider(
        KaufdaSession(
          token: token,
          visitId: visitId,
          userIdent: userIdent ?? visitId,
        ),
      );

  final KaufdaSession _session;

  @override
  Future<KaufdaSession> session({bool forceRefresh = false}) async {
    if (_session.isExpired()) {
      throw const KaufdaSessionException(
        'Der fest hinterlegte Token ist abgelaufen',
      );
    }
    return _session;
  }
}
