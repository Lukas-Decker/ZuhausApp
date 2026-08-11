# prospect_client

Ruft digitale Prospekte deutscher Supermaerkte und Einzelhandelsketten ab und stellt sie ueber
ein quellenunabhaengiges Datenmodell bereit.

Reines Dart, keine Flutter-Abhaengigkeit. Dieselbe Logik laeuft in der CLI, im Test und in einer
Flutter-App.

## Abdeckung

Ermittelt und verifiziert am 2026-08-10, Details in [RESEARCH.md](../RESEARCH.md).

| Haendler | Quelle | Prospektseiten | Produkte | Preise | Filialen |
|---|---|---|---|---|---|
| Netto | Tjek | ja | ja | **ja** | ja |
| PENNY | Tjek | ja | ja | **ja** | ja |
| CITTI | Tjek | ja | ja | **ja** | ja |
| Kaufland | Tjek + Schwarz | ja | ja | **ja** (ueber Tjek) | ja |
| Lidl | Schwarz | ja | ja (Non-Food) | **ja** | nein |
| ALDI Nord | Tjek | ja | nein | nein | ja |
| ALDI SUED | Tjek | ja | nein | nein | ja |
| HIT, famila Nordost, famila Nordwest | Tjek | ja | nein | nein | ja |

Mit hinterlegten Marktguru-Zugangsdaten kommen die Haendler dazu, die ueber Tjek und Schwarz
nicht erreichbar sind, darunter **REWE, EDEKA, dm und Rossmann**. Siehe Abschnitt Zugangsdaten.

Prospekte sind bei den meisten dieser Haendler filialabhaengig. Ohne Ortsangabe liefert das
Modul deshalb nur bundesweit gueltige Prospekte, siehe den Abschnitt zur Filialabhaengigkeit.

Ortsangaben sind je Quelle verschieden: Tjek und Kaufland arbeiten mit Koordinaten (`near`),
Marktguru ausschliesslich mit Postleitzahlen (`postalCode`). Eine Umrechnung braeuchte einen
Geocoding-Dienst, den dieses Modul nicht mitbringt. Wer alle Quellen ausschoepfen will, gibt
beides an.

Nicht abgedeckt: REWE, EDEKA, dm, Rossmann, NORMA, Globus, tegut. Fuer diese Haendler gibt es
keine frei zugaengliche Schnittstelle. Ihre Websites sind bot-geschuetzt (HTTP 403), und die
Aggregatoren, die sie fuehren, untersagen den automatisierten Zugriff in ihrer `robots.txt` oder
verlangen einen API-Key. Beides wird von diesem Modul respektiert und nicht umgangen.

## Zugangsdaten

Kein Schluessel steht im Code oder im Repository. Werte kommen aus der Umgebung:

```bash
export MARKTGURU_API_KEY=...
```

```bash
export MARKTGURU_CLIENT_KEY=...
```

Oder aus der App, etwa aus einem sicheren Speicher:

```dart
final client = ProspectClient.create(
  credentials: const SourceCredentials.none().withValues({
    CredentialKey.marktguruApiKey: apiKey,
    CredentialKey.marktguruClientKey: clientKey,
  }),
);
```

Quellen ohne hinterlegte Zugangsdaten werden **nicht registriert**, statt bei jedem Aufruf mit
HTTP 401 zu scheitern. Welche fehlen und warum, zeigt `prospect_client sources` und
`ProspectClient.inactiveSources`.

| Variable | Wofuer | Ohne sie |
|---|---|---|
| `MARKTGURU_API_KEY`, `MARKTGURU_CLIENT_KEY` | Marktguru-Adapter | REWE, EDEKA, dm, Rossmann fehlen |
| `SCHWARZ_STORES_API_KEY` | Ortsaufloesung fuer Lidl | Lidl liefert nur bundesweite Prospekte |

Das Modul prueft nicht, ob ein hinterlegter Schluessel fuer die eigene Nutzung lizenziert ist.
Diese Beurteilung liegt bei dem, der ihn eintraegt. Aus einem fremden Web-Bundle ausgelesene
Schluessel liest das Modul von sich aus nirgends.

## Installation

```yaml
dependencies:
  prospect_client:
    path: ../prospect_client
```

## Nutzung in Dart oder Flutter

```dart
import 'package:prospect_client/prospect_client.dart';

final client = ProspectClient.create(cacheDirectory: cacheDir);
final repo = client.repository;

// Haendler
final retailers = await repo.getRetailers();

// Prospekte eines Haendlers, ohne Seiten und Angebote
final list = await repo.getBrochures(retailerId: 'netto');
if (list.isPartial) {
  // Mindestens eine Quelle war nicht erreichbar, die uebrigen Daten sind gueltig.
  for (final error in list.errors) print(error);
}

// Vollstaendiger Prospekt
final detail = await repo.getBrochure(list.data.first.id);
for (final offer in detail.offers) {
  print('${offer.title}: ${offer.price?.current}');
}

client.close();
```

In Flutter kommt das Cache-Verzeichnis von aussen, damit das Package selbst nichts ueber
Flutter wissen muss:

```dart
final dir = await getApplicationSupportDirectory();
final client = ProspectClient.create(cacheDirectory: dir.path);
```

Ein vollstaendiges Beispiel mit Ladezustaenden und Fehlerbehandlung liegt in
[example/flutter_integration.dart](example/flutter_integration.dart).

## Wichtig: Prospekte sind ueberwiegend filialabhaengig

Das ist keine Randnotiz, sondern bestimmt, ob die App brauchbare Daten zeigt. Gemessene Lage:

| Haendler | Verteilung |
|---|---|
| HIT | pro Filiale ein eigener Wochenprospekt, ueber 50 Varianten gleichzeitig |
| Lidl | rund 40 Regionalvarianten je Woche, dazu einige bundesweite |
| Kaufland | je Filiale, der Regionscode **ist** die Filialnummer |
| famila Nordost, PENNY | ueberwiegend filialgebunden |
| Netto, ALDI Nord, ALDI Sued | tatsaechlich bundesweit |

`Brochure.coverage` sagt, was gilt:

| Wert | Bedeutung |
|---|---|
| `national` | gilt bundesweit |
| `regional` | gilt in einem Vertriebsgebiet |
| `storeBound` | gilt nur in bestimmten Filialen |
| `unknown` | Quelle sagt nichts dazu |

**Ohne `near` liefert `getBrochures` nur bundesweit gueltige Prospekte**, zusammen mit einem
Hinweis in `SourceResult.warnings`. Sonst bekaeme ein Nutzer in Berlin den HIT-Prospekt aus
Hann. Muenden angezeigt. `includeOutOfArea: true` hebt die Filterung auf, etwa fuer Analysen.

```dart
// Empfohlen: mit Ort.
final result = await repo.getBrochures(
  retailerId: 'kaufland',
  near: GeoPoint(52.52, 13.405),
);

// Welche Filialen gelten fuer diesen Prospekt?
final stores = await repo.getBrochureStores(result.data.first);
```

Fuer Kaufland loest das Modul den Ort selbst auf: die oeffentliche Filialliste von
filiale.kaufland.de nennt Objektnummern mit Koordinaten, und die Objektnummer ist der
`region_id` der Prospekt-API. Berlin-Mitte ist `DE8920`, also Region `8920`.

**Fuer Lidl geht das nicht.** Der einzige bekannte Weg von Koordinaten zum Vertriebsgebiet
fuehrt ueber `live.api.schwarz`, das einen im oeffentlichen JS-Bundle hartkodierten `x-apikey`
verlangt und ohne ihn mit HTTP 401 antwortet. Diesen Schluessel auszulesen waere das Umgehen
einer Zugangskontrolle, deshalb bleibt Lidl bei bundesweiten Prospekten. Wer einen Regionscode
kennt, kann ihn ueber `SourceBinding.params['region_id']` selbst setzen.

## Wichtig fuer die UI: BrochureContentLevel

Die Quellen liefern unterschiedlich tiefe Daten. Ein einzelnes Flag waere zu grob, deshalb gibt
es vier Stufen:

| Stufe | Bedeutung | Was die App anbieten kann |
|---|---|---|
| `unknown` | Noch nicht geprueft, Detailabruf noetig | Prospekt oeffnen |
| `imagesOnly` | Nur Seitenbilder | Seitenviewer |
| `productsWithoutPrices` | Produkte und Positionen, keine Preise | Viewer mit antippbaren Produkten |
| `productsWithPrices` | Vollstaendige Angebote | Angebotsliste, Preisvergleich, Suche |

`unknown` ist bewusst nicht dasselbe wie `imagesOnly`. Der Kaufland-Wochenprospekt enthaelt 422
Produkte, die in der Uebersicht der Quelle schlicht nicht mitkommen. Wer beides gleichsetzt,
zeigt Nutzern "keine Angebote" fuer einen Prospekt voller Angebote.

## Fehlerbehandlung

Keine Exception erreicht die UI. Abfragen liefern `SourceResult<T>`:

```dart
final result = await repo.getBrochures(retailerId: 'kaufland');

result.data       // immer nutzbar, auch bei Teilausfall
result.isPartial  // mindestens eine Quelle ausgefallen
result.errors     // welche, mit Code und ob ein Retry sinnvoll ist
result.isStale    // Daten kamen aus abgelaufenem Cache, weil das Netz fehlte
```

Faellt Tjek aus, liefert Schwarz weiter. Fehlt das Netz komplett, kommen die zuletzt
gespeicherten Daten mit `isStale: true`.

Nur `getBrochure` wirft, weil es genau eine Quelle betrifft und es kein sinnvolles Teilergebnis
gibt.

## Caching

Dateibasiert, ein JSON pro Antwort, ohne native Abhaengigkeit.

1. Frischer Eintrag innerhalb der TTL, dann kein Request.
2. Abgelaufen mit ETag oder Last-Modified, dann bedingter Request. Bei 304 bleibt der Koerper.
3. Request scheitert und ein alter Eintrag existiert, dann wird dieser mit `isStale: true`
   geliefert statt zu scheitern.

Standard-TTLs: Haendler 7 Tage, Prospektlisten 6 Stunden, Prospektdetails 24 Stunden, Filialen
30 Tage, Suche 1 Stunde. Anpassbar ueber `CachePolicy`.

## CLI

```bash
dart run bin/prospect_client.dart retailers
```

```bash
dart run bin/prospect_client.dart brochures netto --near 52.52,13.405
```

```bash
dart run bin/prospect_client.dart brochure tjek:3sBnfFlz --pages --offers
```

```bash
dart run bin/prospect_client.dart search milch --near 52.52,13.405
```

```bash
dart run bin/prospect_client.dart debug tjek --json
```

Weitere Kommandos: `stores`, `update`, `cache stats|clear`, `sources`. `--json` gibt es bei
jedem Kommando.

## Einen Haendler ergaenzen

Gehoert der Haendler zur Schwarz-Gruppe, reicht ein Eintrag in `SchwarzApi.clients`.

Sonst:

1. Verzeichnis unter `lib/src/sources/<name>/` anlegen
2. `<Name>Api` fuer die HTTP-Aufrufe, `<Name>Mapper` fuer die Uebersetzung ins neutrale Modell
3. `<Name>Source implements ProspectSource`, mit ehrlichen `SourceCapabilities`
4. In `ProspectClient.create` registrieren
5. Echte API-Antwort als Fixture unter `test/fixtures/` ablegen und Mapper-Tests schreiben

Am Repository, am Cache, an der Fehlerbehandlung und an der CLI wird nichts geaendert. Neue
Namensvarianten eines bereits bekannten Haendlers gehoeren in `RetailerRegistry`, damit er nicht
doppelt in der App erscheint.

## Tests

```bash
dart test
```

Die Mapper werden gegen eingefrorene, echte API-Antworten in `test/fixtures/` geprueft, nicht
gegen handgeschriebene Beispiele. Eigenheiten wie `pre_price: null`, HTML-Entities in
Beschreibungen oder Polygone statt Rechtecken faende man sonst nicht selbst aus, und genau daran
scheitert das Mapping im Betrieb.

## Rechtlicher Rahmen

Beide Quellen antworten ohne Authentifizierung. Das Modul umgeht keine Zugangskontrollen,
Captchas oder Bot-Erkennung. Trifft es auf HTTP 401 oder 403, meldet es das als `AccessDenied`
und ueberspringt die Quelle.

Es handelt sich um inoffizielle Schnittstellen ohne Nutzungszusage. Fuer einen produktiven
Einsatz mit Nutzerreichweite sollte eine vertragliche Grundlage geschaffen werden, etwa ueber
den Bonial-Partnervertrag, der zusaetzlich REWE, EDEKA, dm und Rossmann abdecken wuerde. Das
Modul hat dafuer bereits die passende Stelle: ein weiterer Adapter, sonst nichts.
