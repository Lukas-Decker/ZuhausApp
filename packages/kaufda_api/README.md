# kaufda_api

Dart-Client fuer die interne kaufDA Content-Viewer-API. Reines Dart ohne
`dart:io` in der Bibliothek, laeuft damit unveraendert in Flutter auf Android,
iOS, Desktop und (mit Einschraenkung, siehe unten) Web.

Die Endpunkte, Parameter und Header sind aus der mitgelieferten Aufzeichnung
`api_.har` abgeleitet.

## Was abgedeckt ist

| Aufruf | Endpunkt | Rueckgabe |
| --- | --- | --- |
| `client.brochure(id)` | `GET /v1/brochures/{id}` | `Brochure` |
| `client.pages(id)` | `GET /v1/brochures/{id}/pages` | `List<BrochurePage>` inklusive aller Angebote |
| `client.related(id)` | `GET /v1/brochures/related` | `BrochureCollections` |
| `client.sidebar(id)` | `GET /v1/sidebar` | `BrochureCollections` |
| `client.lastPage(id)` | `GET /v1/lastPage` | `BrochureCollections` |
| `client.nearestStore(id)` | `GET /v1/nearestStore` | `Store?` |
| `client.accountId()` | `GET https://www.kaufda.de/api/user/account/id` | `String` |
| `client.bundle(id)` | alle sechs parallel | `BrochureBundle` |
| `client.searchRetailer(name)` | `GET https://www.kaufda.de/api/search` | `RetailerSearch`, siehe [Nach Haendlername suchen](#nach-haendlername-suchen) |
| `client.search(begriff)` | dasselbe, ungefiltert | `SearchResult` |
| `client.shelf(...)` | `GET https://www.kaufda.de/api/shelf` | `ShelfPage`, siehe [Prospekte in der Naehe](#prospekte-in-der-naehe) |
| `client.shelfAll(...)` | dasselbe, alle Seiten | `List<ShelfBrochure>` |
| `client.nearbyBrochures(...)` | Empfehlungslisten | `List<BrochureSummary>`, aelterer Weg |

Dazu:

- **Session**: `WebSessionProvider` holt anonym einen JWT von
  `https://www.kaufda.de/sessionData`, cached ihn bis kurz vor Ablauf (rund 30
  Minuten) und erneuert ihn bei HTTP 401 automatisch einmal.
- **Tracking**: `TrackingClient` bildet `POST /v3s/compound-event` und
  `POST /v3s/batch-compound-event` auf `tk.kaufda.de` ab.
- **CLI**: `bin/kaufda.dart` fuer Dumps, CSV-Export und Bilddownload.

## Einbinden

In der `pubspec.yaml` der Flutter-App:

```yaml
dependencies:
  kaufda_api:
    path: ../kaufAPI
```

## Benutzung

```dart
import 'package:kaufda_api/kaufda_api.dart';

final client = KaufdaClient(
  location: const GeoLocation(lat: 49.6378338, lng: 7.1113922, zip: '55767'),
);

final brochure = await client.brochure('72a3b683-90ff-4d09-9815-6baebe0a1b1d');
final pages = await client.pages(brochure.id);

for (final page in pages) {
  for (final offer in page.offerContents) {
    final deal = offer.bestDeal;
    print('${offer.displayName}: ${deal?.min} ${deal?.currencyCode}');
  }
}

client.close();
```

Ein vollstaendiges Beispiel steht in [`example/example.dart`](example/example.dart):

```bash
dart run example/example.dart
```

### Nuetzliche Helfer

- `page.largestImage` / `page.imageBySize('768x1024')` liefern die Seitenbilder
  (verfuegbar sind `75x96`, `768x1024`, `1600x1600`, `2800x2800`).
- `offer.bestDeal`, `offer.salesPrice`, `offer.specialPrice` sortieren die
  Preisangaben vor, `offer.displayName` setzt Marke und Produktname zusammen.
- `offer.parentContent.area` ist die Trefferflaeche des Angebots auf der Seite,
  normalisiert auf 0..1 - passt direkt auf ein `Stack` mit `Positioned` ueber
  dem Seitenbild.
- `store.openingHours.forWeekday(DateTime.monday)` liefert die Zeitfenster
  eines Tages, `slot.displayValue` formatiert sie als `07:00 - 21:00`.
- Alle Modelle haben `toJson()`, lassen sich also cachen oder weiterreichen.

### Prospekte in der Naehe

`GET https://www.kaufda.de/api/shelf` ist der Endpunkt hinter der Seite
`www.kaufda.de/shelf`, also die vollstaendige Liste fuer einen Standort. Er
braucht nur `lat` und `lng`, kein Prospekt als Einstieg und nicht einmal einen
Session-Token:

```dart
final seite = await client.shelf(size: 24);
print('${seite.page.totalElements} Prospekte im Umkreis');

for (final prospekt in seite.brochures) {
  print('${prospekt.publisher.name}: ${prospekt.title} (${prospekt.id})');
  print('  naechste Filiale: ${prospekt.closestStore?.address}');
}

// Oder gleich alles, mit automatischer Paginierung:
final alle = await client.shelfAll(
  sectorIds: const [KaufdaSector.discounter, KaufdaSector.supermarkt],
  onlyValid: true,
);
```

Parameter: `page` zaehlt ab 0, `size` wird bis mindestens 100 respektiert,
`sectorIds` filtert nach Branchen und wirkt bei mehreren Werten wie ein Oder.
Die 19 bekannten Branchen stehen als Konstanten in `KaufdaSector`
(`KaufdaSector.names` liefert die Anzeigenamen).

Gemessen mit `shelfAll`:

| Standort | Prospekte | davon Discounter (DE-22) |
| --- | --- | --- |
| Bruecken (55767) | 36 | |
| Berlin Mitte | 90 | 22 |

`ShelfBrochure` bringt mehr mit als eine Prospektkachel aus den
Empfehlungslisten: Seitenzahl, Veroeffentlichungszeitraum und die
naechstgelegene Filiale liegen direkt bei. Die `id` geht unveraendert in
`client.brochure()` und `client.pages()`.

Zwei Details: im selben Array liegen auch Blog-Karussells, die der Client
herausfiltert (deshalb 36 Prospekte bei `totalElements: 37`). Und `shelfAll`
dedupliziert, weil die Sortierung zwischen zwei Requests leicht wandern kann.

### Nach Haendlername suchen

`GET https://www.kaufda.de/api/search` sucht standortbezogen nach Haendlern
und Produkten. Auch dieser Endpunkt braucht keinen Session-Token.

```dart
final lidl = await client.searchRetailer('Lidl', onlyValid: true);

print('${lidl.publisherName} (${lidl.publisherId})');
for (final prospekt in lidl.brochures) {
  print('${prospekt.title}, ${prospekt.distance?.toStringAsFixed(1)} km');
}
for (final angebot in lidl.offers) {
  print('${angebot.price?.mainPriceFormatted}  ${angebot.displayName}');
}
```

Wichtig: der Endpunkt filtert nicht selbst nach Haendler. Eine Suche nach
`Lidl` liefert auch Penny, Netto und das kaufDA Magazin mit. `searchRetailer`
nimmt deshalb den Haendler, den die API im Begriff erkannt hat
(`metadata.recognizedEntities` mit `type: RETAILER`) und filtert die Treffer
darauf. Wird kein Haendler erkannt, greift ein Namensvergleich ueber die
Facetten, damit auch `netto marken` funktioniert. Bleibt auch das ohne
Treffer, ist `isRetailer` false und es kommt ungefiltert zurueck.

Die Zahlen in `result.metadata` beziehen sich immer auf die gesamte Suche,
nicht auf den gefilterten Haendler.

Fuer die rohe Suche, etwa nach einem Produkt:

```dart
final treffer = await client.search('Kaffee', limit: 50, sort: SearchSort.price);
print(treffer.metadata.searchType);       // "product" statt "retailer"
print(treffer.metadata.offerCount);       // Gesamttrefferzahl
```

Parameter: `limit` gilt fuer Prospekte und Angebote gemeinsam und wird bis
mindestens 200 respektiert, `offset` blaettert weiter (ab `offset > 0` liefert
die API keine Prospekte mehr), `sort` kennt `relevance`, `price` und
`validityEnd`. Eine Filterung nach Haendler oder Preis kennt der Endpunkt
trotz der Facetten in den Metadaten nicht.

#### Aelterer Weg: nearbyBrochures

Bevor der Shelf-Endpunkt bekannt war, hat sich der Client ueber die drei
Empfehlungslisten gehangelt. Das bleibt nuetzlich, wenn du von einem
konkreten Prospekt aus dessen Umfeld sehen willst:

```dart
final umkreis = await client.nearbyBrochures(
  seedBrochureIds: [letzteBekannteId],
  onlyValid: true,
);
```

Der Aufruf braucht eine bekannte Prospekt-ID als Einstieg, `depth: 2` geht
eine Runde weiter. Fuer eine vollstaendige Liste ist `shelf` die bessere
Wahl: in Berlin fand der Crawl 75 Prospekte, der Shelf-Endpunkt 90.

### Eigener Token

Wenn ein Token aus dem Browser genutzt werden soll, statt anonym einen zu
holen:

```dart
final client = KaufdaClient(
  location: location,
  sessionProvider: StaticSessionProvider.fromToken(jwtAusDemBrowser),
);
```

### Fehlerbehandlung

Alle Fehler leiten sich von `KaufdaException` ab:
`KaufdaHttpException` (mit `statusCode`, `isUnauthorized`, `isNotFound`),
`KaufdaParseException` und `KaufdaSessionException`.

## Tracking

Der Tracking-Client bildet die Events aus der Aufzeichnung ab:
`web_page_view`, `brochure_engagement`, `brochure_view_update`,
`brochure_impression` und `offer_impression`. Alles andere geht ueber
`RawTrackingEvent`.

```dart
final tracking = TrackingClient(
  sessionProvider: client.sessionProvider,
  context: const TrackingContext(
    geo: GeoLocation(lat: 49.6378338, lng: 7.1113922, zip: '55767'),
    pageType: 'SHELF_PAGE',
    webPage: TrackingWebPage(url: 'https://www.kaufda.de/contentViewer/...'),
  ),
);

final engagementId = newUuidV4();
await tracking.sendBatch([
  const WebPageViewEvent(),
  BrochureViewUpdateEvent(
    engagement: BrochureEngagementDetails(
      engagementId: engagementId,
      brochureId: brochure.id,
      publisherId: brochure.publisher.id,
      interactionType: 'brochure_enter',
    ),
  ),
]);
```

Hinweis: Diese Aufrufe schreiben echte Events in die Analytics. Sie sind
bewusst nicht Teil der Smoke-Tests und sollten nur gesendet werden, wenn das
gewollt ist.

## CLI

```bash
dart run bin/kaufda.dart --help
```

Globale Optionen: `--lat`, `--lng`, `--zip`, `--city`, `--partner`,
`--brochure-key`, `--token`, `--compact`.

```bash
dart run bin/kaufda.dart brochure <id>
dart run bin/kaufda.dart pages <id> --summary
dart run bin/kaufda.dart offers <id>
dart run bin/kaufda.dart offers <id> --csv angebote.csv
dart run bin/kaufda.dart related <id>
dart run bin/kaufda.dart sidebar <id>
dart run bin/kaufda.dart lastpage <id>
dart run bin/kaufda.dart store <id>
dart run bin/kaufda.dart retailer Lidl --valid --offers
dart run bin/kaufda.dart search Kaffee --sort price --limit 20
dart run bin/kaufda.dart shelf --size 24
dart run bin/kaufda.dart shelf --all --sector DE-22 --sector DE-48 --valid
dart run bin/kaufda.dart shelf --sector list
dart run bin/kaufda.dart --lat 52.52 --lng 13.405 shelf --all --json
dart run bin/kaufda.dart nearby <id> --depth 2 --valid
dart run bin/kaufda.dart dump <id> -o dump
dart run bin/kaufda.dart download <id> --pages 1-5 --size 1600x1600 -o out
```

`dump` legt pro Prospekt ein Verzeichnis mit `brochure.json`, `pages.json`,
`offers.json`, `nearestStore.json`, `related.json`, `sidebar.json` und
`lastPage.json` an. `download` speichert die Seitenbilder als
`seite_001.jpg`, `seite_002.jpg` und so weiter.

## Zu beachten

- **Standort ist Pflicht.** Ohne `lat`/`lng` antwortet die API nicht sinnvoll;
  der Client wirft dann einen `ArgumentError`.
- **Zwei Hosts.** `shelf`, `search`, `sessionData` und `accountId` liegen auf
  `www.kaufda.de`, alles andere auf `content-viewer-be.kaufda.de`. Shelf und
  Suche kommen ohne Session-Token aus, der Client schickt ihn trotzdem mit.
- **Seitennummern** kommen von der API nullbasiert (`page.number == 0` ist die
  Titelseite). CLI und Dateinamen zaehlen ab 1.
- **Flutter Web**: die API setzt `access-control-allow-origin:
  https://www.kaufda.de`. Aus einer Web-App auf anderer Origin blockt der
  Browser die Antwort, ein Proxy ist dort noetig. Auf Android, iOS und Desktop
  gibt es das Problem nicht. `User-Agent`, `Origin` und `Referer` werden im
  Browser ohnehin verworfen, das laesst sich mit
  `sendBrowserHeaders: false` abschalten.
- **Rate Limits** sind nicht dokumentiert. `bundle()` feuert sechs Requests
  parallel, der Bilddownload standardmaessig vier.

## Entwicklung

```bash
dart pub get
dart analyze
dart test
```

Die Tests laufen komplett offline gegen die Fixtures in `test/fixtures/`, die
direkt aus `api_.har` stammen.
