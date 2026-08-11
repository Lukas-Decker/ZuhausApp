import '../../core/errors/prospect_exception.dart';
import '../../core/http/api_client.dart';
import '../../core/http/cache_policy.dart';
import '../../core/http/json_reader.dart';
import '../../core/models/geo.dart';
import '../../core/models/store.dart';

/// Loest Koordinaten auf eine Kaufland-Filialnummer auf.
///
/// Hintergrund: die Prospekt-API der Schwarz-Gruppe verlangt fuer Kaufland
/// einen `region_id`, und dieser Code **ist** die Filialnummer. Die API
/// bestaetigt das selbst, sie beantwortet `region_id=8920` mit
/// `"self": "...&store_id=8920"`. Ein fest verdrahteter Standardwert liefert
/// deshalb allen Nutzern ausserhalb dieser einen Filiale die falschen
/// Prospekte.
///
/// Quelle ist die oeffentliche Filialliste von filiale.kaufland.de. Sie
/// braucht keine Authentifizierung und ist in deren robots.txt nicht gesperrt.
///
/// Bewusst nicht genutzt wird die Filial-API der Schwarz-Gruppe unter
/// `live.api.schwarz`. Sie verlangt einen `x-apikey`, der im oeffentlichen
/// JS-Bundle von lidl.de hartkodiert ist, und antwortet ohne ihn mit HTTP 401.
/// Diesen Schluessel auszulesen und weiterzuverwenden waere das Umgehen einer
/// Zugangskontrolle. Aus demselben Grund ist Marktguru nicht angebunden.
class KauflandStoreDirectory {
  KauflandStoreDirectory(this._client, {Uri? sourceUrl})
      : sourceUrl = sourceUrl ??
            Uri.parse('https://filiale.kaufland.de/.klstorefinder.json');

  final ApiClient _client;
  final Uri sourceUrl;

  /// Einmal geladen und fuer die Lebensdauer der Instanz behalten. Die Liste
  /// ist rund 500 KB gross, das Neuparsen bei jeder Abfrage waere Verschwendung.
  List<KauflandStore>? _stores;

  /// Alle Filialen. Beim ersten Aufruf wird die Liste geladen.
  Future<List<KauflandStore>> stores() async {
    final cached = _stores;
    if (cached != null) return cached;

    final response = await _client.getJson(
      sourceUrl,
      // Filialen aendern sich selten, die lange TTL ist angemessen.
      kind: CacheKind.stores,
      sourceId: 'schwarz',
    );
    final decoded = response.decodeJson(sourceId: 'schwarz');
    if (decoded is! List) {
      throw ResponseParseFailure(
        'Kaufland-Filialliste hat ein unerwartetes Format: '
        '${decoded.runtimeType}',
        sourceId: 'schwarz',
      );
    }

    final parsed = <KauflandStore>[];
    for (final entry in decoded.whereType<Map<String, Object?>>()) {
      final store = KauflandStore.fromJson(entry);
      if (store != null) parsed.add(store);
    }

    _stores = parsed;
    return parsed;
  }

  /// Naechstgelegene Filiale zu [point], oder null wenn keine gefunden wurde.
  ///
  /// [maxDistanceMeters] verhindert, dass jemand in Portugal die naechste
  /// deutsche Filiale zugeordnet bekommt und dadurch Prospekte sieht, die fuer
  /// ihn bedeutungslos sind.
  Future<KauflandStore?> nearest(
    GeoPoint point, {
    int maxDistanceMeters = 100000,
  }) async {
    final all = await stores();
    KauflandStore? best;
    var bestDistance = double.infinity;

    for (final store in all) {
      final distance = store.location.distanceTo(point);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = store;
      }
    }

    return bestDistance <= maxDistanceMeters ? best : null;
  }

  /// Regionscode fuer eine Position, oder null wenn keine Filiale in
  /// Reichweite liegt.
  Future<String?> regionFor(GeoPoint point) async =>
      (await nearest(point))?.regionCode;
}

/// Eine Kaufland-Filiale aus der oeffentlichen Filialliste.
class KauflandStore {
  const KauflandStore({
    required this.objectNumber,
    required this.name,
    required this.location,
    this.street,
    this.zipCode,
    this.town,
  });

  /// Objektnummer inklusive Laenderpraefix, z.B. `DE8920`.
  final String objectNumber;

  final String name;
  final GeoPoint location;
  final String? street;
  final String? zipCode;
  final String? town;

  /// Objektnummer ohne Laenderpraefix. Genau dieser Wert geht als `region_id`
  /// an die Prospekt-API.
  String get regionCode => objectNumber.replaceFirst(RegExp(r'^[A-Z]{2}'), '');

  Store toStore() => Store(
        id: objectNumber,
        retailerId: 'kaufland',
        name: name,
        street: street,
        zipCode: zipCode,
        city: town,
        location: location,
      );

  /// Die Feldnamen der Quelle sind stark abgekuerzt: `n` Objektnummer,
  /// `cn` Name, `sn` Strasse, `pc` PLZ, `t` Ort.
  static KauflandStore? fromJson(Map<String, Object?> json) {
    final number = json.stringAt('n');
    final lat = json.doubleAt('lat');
    final lng = json.doubleAt('lng');
    if (number == null || lat == null || lng == null) return null;

    return KauflandStore(
      objectNumber: number,
      name: json.stringAt('cn') ?? number,
      location: GeoPoint(lat, lng),
      street: json.stringAt('sn'),
      zipCode: json.stringAt('pc'),
      town: json.stringAt('t'),
    );
  }

  @override
  String toString() => 'KauflandStore($objectNumber, $name)';
}
