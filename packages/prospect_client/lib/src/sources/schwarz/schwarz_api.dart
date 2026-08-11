import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/http/cache_policy.dart';
import '../../core/http/json_reader.dart';

/// Ein von der Schwarz-Gruppe betriebener Prospektauftritt.
///
/// Der Endpunkt unterscheidet Mandanten ueber `client_locale`. Kaufland ist
/// zusaetzlich regionalisiert: ohne `region_id` antwortet die Uebersicht mit
/// HTTP 400 und der Meldung, der nicht regionalisierte Endpunkt sei fuer
/// diesen Mandanten deaktiviert. Verifiziert am 2026-08-10.
class SchwarzClient {
  const SchwarzClient({
    required this.retailerId,
    required this.clientLocale,
    required this.displayName,
    this.fallbackRegion,
  });

  /// Kanonische Haendler-ID im neutralen Modell.
  final String retailerId;

  /// Mandantenkennung der API, z.B. `lidl/de-DE`.
  final String clientLocale;

  final String displayName;

  /// Notbehelf fuer Mandanten, deren Uebersicht ohne Region gar nicht
  /// antwortet.
  ///
  /// Kaufland ist so ein Fall, dort liefert der Abruf ohne `region_id`
  /// HTTP 400. Ohne irgendeinen Code gaebe es also nicht einmal die
  /// bundesweiten Prospekte.
  ///
  /// Wichtig: Dieser Wert ist **keine** Ortsangabe und darf nie so behandelt
  /// werden. Die damit abgerufenen filialgebundenen Prospekte gelten fuer eine
  /// beliebige fremde Filiale. Sie werden ueber [BrochureCoverage] erkannt und
  /// ohne Ortsbezug ausgefiltert. Genau dieser Unterschied fehlte in der
  /// ersten Fassung: dort galt `3000` als Standardregion, wodurch Nutzer
  /// stillschweigend die Prospekte einer Mannheimer Filiale sahen.
  final String? fallbackRegion;

  /// True, wenn die Uebersicht ohne Regionsangabe fehlschlaegt.
  bool get requiresRegion => fallbackRegion != null;
}

/// Rohzugriff auf die Prospekt-API der Schwarz-Gruppe.
///
/// Basis: `https://endpoints.leaflets.schwarz`, Version v4, ohne
/// Authentifizierung. Gefunden durch Netzwerkanalyse von lidl.de, siehe
/// RESEARCH.md Abschnitt 3.
class SchwarzApi {
  SchwarzApi(this._client, {Uri? baseUrl})
      : baseUrl = baseUrl ?? Uri.parse('https://endpoints.leaflets.schwarz');

  static const String sourceId = 'schwarz';

  /// Die unterstuetzten Mandanten. Ein weiterer Haendler der Gruppe braucht
  /// hier genau einen Eintrag, sonst nichts.
  static const List<SchwarzClient> clients = [
    SchwarzClient(
      retailerId: 'lidl',
      clientLocale: 'lidl/de-DE',
      displayName: 'Lidl',
    ),
    SchwarzClient(
      retailerId: 'kaufland',
      clientLocale: 'kaufland/de-DE',
      displayName: 'Kaufland',
      fallbackRegion: '3000',
    ),
  ];

  static SchwarzClient? clientFor(String retailerId) {
    for (final client in clients) {
      if (client.retailerId == retailerId) return client;
    }
    return null;
  }

  final ApiClient _client;
  final Uri baseUrl;

  /// Prospektuebersicht eines Mandanten, gruppiert in Kategorien und
  /// Unterkategorien. Gibt die flache Liste der Prospekte zurueck, weil die
  /// Gruppierung fuer das neutrale Modell keine Rolle spielt.
  Future<List<Map<String, Object?>>> overview(
    SchwarzClient client, {
    String? region,
  }) async {
    final regionCode = region ?? client.fallbackRegion;
    final uri = baseUrl.replace(
      path: '/v4/overview',
      queryParameters: {
        'client_locale': client.clientLocale,
        if (regionCode != null) 'region_id': regionCode,
      },
    );

    final json = await _getEnvelope(uri, CacheKind.brochureList);
    final flyers = <Map<String, Object?>>[];
    for (final category in json.objectsAt('categories')) {
      for (final subcategory in category.objectsAt('subcategories')) {
        for (final flyer in subcategory.objectsAt('flyers')) {
          flyers.add({
            ...flyer,
            // Kategorie mitfuehren, sie ist im Einzelabruf sonst nicht sichtbar.
            '_category': category.stringAt('name'),
            '_subcategory': subcategory.stringAt('name'),
          });
        }
      }
    }
    return flyers;
  }

  /// Vollstaendiger Prospekt.
  ///
  /// [identifier] ist entweder der Slug aus der URL oder die UUID aus der
  /// Uebersicht. Beide funktionieren am selben Parameter.
  Future<Map<String, Object?>> flyer(
    SchwarzClient client,
    String identifier, {
    String? region,
  }) async {
    final regionCode = region ?? client.fallbackRegion;
    final uri = baseUrl.replace(
      path: '/v4/flyer',
      queryParameters: {
        'flyer_identifier': identifier,
        'client_locale': client.clientLocale,
        if (regionCode != null) 'region_id': regionCode,
      },
    );

    final json = await _getEnvelope(uri, CacheKind.brochureDetail);
    final flyer = json.mapAt('flyer');
    if (flyer == null) {
      throw NotFound(
        'Prospekt "$identifier" existiert bei ${client.displayName} nicht',
        sourceId: sourceId,
      );
    }
    return flyer;
  }

  /// Liest die einheitliche Antworthuelle der API.
  ///
  /// Jede Antwort traegt `success`, `message` und `version`. Ein `success:
  /// false` kommt auch mit HTTP 200 vor, deshalb wird der Inhalt geprueft und
  /// nicht nur der Statuscode.
  Future<Map<String, Object?>> _getEnvelope(Uri uri, CacheKind kind) async {
    final response = await _client.getJson(uri, kind: kind, sourceId: sourceId);
    final decoded = response.decodeJson(sourceId: sourceId);

    if (decoded is! Map<String, Object?>) {
      throw ResponseParseFailure(
        'Erwartet wurde ein Objekt von $uri, erhalten: ${decoded.runtimeType}',
        sourceId: sourceId,
      );
    }

    if (decoded.boolAt('success') == false) {
      final message = decoded.stringAt('message') ?? 'ohne Meldung';
      // Die API meldet fehlende Regionalisierung als fachlichen Fehler.
      if (message.contains('regionalized')) {
        throw ConfigurationError(
          'Mandant benoetigt eine Region: $message',
        );
      }
      throw SourceUnavailable(
        'Schwarz-API meldet einen Fehler: $message',
        sourceId: sourceId,
      );
    }

    return decoded;
  }
}
