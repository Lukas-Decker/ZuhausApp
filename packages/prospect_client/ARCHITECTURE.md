# Prospect Client: Architektur (Phase 4-9)

## Leitentscheidung

Ein reines Dart-Package `prospect_client` ohne Flutter-Abhaengigkeit. Die Flutter-App bindet es
per `pubspec.yaml` ein und sieht ausschliesslich `ProspectRepository`. Woher die Daten kommen,
ist fuer die App unsichtbar.

Begruendung aus der Recherche: keine Quelle deckt alle Haendler ab, und Kaufland ist ueber zwei
Quellen mit unterschiedlicher Datentiefe erreichbar. Eine feste Zuordnung Haendler zu Quelle
waere damit von Anfang an falsch. Die Registry loest Haendler auf kanonische IDs auf und kann
mehrere Quellen pro Haendler zusammenfuehren.

## Schichten

```
                    Flutter App
                         |
                  ProspectRepository          <- einzige oeffentliche Schnittstelle
                         |
        +----------------+----------------+
        |                |                |
   SourceRegistry    CacheStore      ErrorMapper
        |
   ProspectSource (Interface)
        |
   +----+------------+
   |                 |
TjekSource     SchwarzSource      ... weitere Adapter
   |                 |
 TjekApi        SchwarzApi        <- reine HTTP-Aufrufe, DTOs
   |                 |
 TjekMapper     SchwarzMapper     <- DTO zu neutralem Modell
```

Regel: Der Mapper ist die einzige Stelle, an der quellenspezifische Feldnamen vorkommen.
Alles oberhalb kennt nur das neutrale Modell.

## Verzeichnisstruktur

```
prospect_client/
  bin/prospect_client.dart              CLI-Einstiegspunkt
  lib/
    prospect_client.dart                Barrel, oeffentliche API
    src/
      core/
        models/                         neutrales Datenmodell
        errors/                         Fehlerobjekte, Result-Typ
        cache/                          CacheStore + Implementierungen
        http/                           HTTP-Abstraktion, Retry, Rate Limit
        source/                         Adapter-Interface, Capabilities, Registry
        repository/                     ProspectRepository + Default-Implementierung
      sources/
        tjek/                           TjekSource, TjekApi, TjekMapper, DTOs
        schwarz/                        SchwarzSource, SchwarzApi, SchwarzMapper, DTOs
      cli/                              Kommandos
  test/
    fixtures/                           echte, eingefrorene API-Antworten
```

Ein neuer Haendler bedeutet: ein Verzeichnis unter `sources/`, eine Klasse die
`ProspectSource` implementiert, eine Zeile in der Registry. Nichts anderes wird angefasst.

## Datenmodell

Abgeleitet aus den real gemessenen Feldern, nicht aus dem Beispiel im Auftrag.

### Kanonische Haendler-Identitaet

```dart
class Retailer {
  final String id;              // "kaufland", "netto", stabil und quellenunabhaengig
  final String name;
  final String? website;
  final String? description;
  final ImageSet? logo;
  final String? colorHex;
  final String countryCode;
  final List<SourceBinding> bindings;   // welche Quelle kennt ihn unter welcher ID
}

class SourceBinding {
  final String sourceId;          // "tjek"
  final String nativeId;          // "L5IgL3"
  final Map<String, String> params;  // z.B. {"region_id": "3000"} fuer Kaufland/Schwarz
}
```

`bindings` ist der Grund, warum Kaufland ueber Tjek und Schwarz gleichzeitig funktioniert.

### Prospekt

```dart
class Brochure {
  final BrochureId id;             // sourceId + nativeId, global eindeutig
  final String retailerId;         // kanonisch
  final String title;
  final String? subtitle;          // Tjek nutzt label, Schwarz name + title
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? publishedAt;
  final int pageCount;
  final ImageSet? cover;
  final Uri? pdfUrl;
  final BrochureContentLevel contentLevel;
  final BrochureCoverage coverage;
  final List<String> regionCodes;
  final List<BrochurePage> pages;  // leer in der Listenansicht, gefuellt im Detail
  final List<Offer> offers;
  bool get isDetailLoaded => ...;
}

enum BrochureContentLevel { unknown, imagesOnly, productsWithoutPrices, productsWithPrices }
enum BrochureCoverage     { unknown, national, regional, storeBound }
```

Zwei Achsen, weil die Quellen zwei unabhaengige Dinge unterschiedlich tief liefern.

`contentLevel` beantwortet: wie strukturiert sind die Daten? `unknown` ist bewusst nicht
dasselbe wie `imagesOnly`. Die Uebersicht von Schwarz enthaelt keine Produkte, der
Kaufland-Wochenprospekt dahinter aber 422.

`coverage` beantwortet: wo gilt der Prospekt? Ohne diese Achse ist eine Prospektliste
irrefuehrend. HIT veroeffentlicht denselben Wochenprospekt in ueber 50 Filialvarianten, Lidl in
rund 40 Regionalvarianten. Untereinander angezeigt sieht ein Nutzer fast nur Angebote, die bei
ihm nicht gelten.

### Ortsbezug

Weil Prospekte ueberwiegend filialabhaengig sind, ist der Ort kein Zusatzfilter, sondern
bestimmt die Ergebnismenge:

| Aufruf | Ergebnis |
|---|---|
| ohne `near` | nur `coverage == national`, dazu ein Hinweis in `warnings` |
| mit `near` | Quellen filtern auf das Gebiet, filialgebundene Prospekte bleiben |
| `includeOutOfArea: true` | alle Varianten, fuer Analyse und Debugging |

Die Aufloesung Ort zu Region unterscheidet sich je Quelle:

- **Tjek** filtert serverseitig ueber `r_lat`/`r_lng`/`r_radius`. Die zugehoerigen Filialen
  liefert `/v2/catalogs/{id}/stores`.
- **Kaufland** braucht einen `region_id`, und dieser Code ist die Filialnummer. Das Modul loest
  ihn ueber die oeffentliche Filialliste von filiale.kaufland.de auf
  (`KauflandStoreDirectory`, naechstgelegene Filiale zu den Koordinaten).
- **Lidl** ist nicht aufloesbar. Der einzige bekannte Weg verlangt einen API-Key mit
  Zugangsschutz, deshalb bleibt es dort bei bundesweiten Prospekten, sofern der Aufrufer keinen
  Regionscode selbst setzt.

Kein Rueckfall auf einen festen Standardcode. Eine falsche Region ist schlechter als keine:
sie liefert stillschweigend die Prospekte einer fremden Filiale.

### Seite, Angebot, Preis

```dart
class BrochurePage {
  final int number;
  final ImageSet images;           // thumbnail / view / zoom, alle Quellen liefern drei Stufen
  final PageDimensions? dimensions;
  final String? altText;           // Schwarz liefert brauchbare Beschreibungen
  final List<Hotspot> hotspots;    // Position eines Angebots auf der Seite
}

class Hotspot {                    // Prozentkoordinaten, beide Quellen relativ
  final String? offerId;
  final double left, top, width, height;
}

class Offer {
  final String id;
  final String title;
  final String? description;
  final String? brand;
  final Price? price;              // null bei productsWithoutPrices
  final Quantity? quantity;
  final ImageSet? image;
  final int? pageNumber;
  final List<String> categories;
  final Uri? link;
  final String? externalProductId; // Kaufland-Artikelnummer, Lidl-productId
}

class Price {
  final double current;
  final double? previous;          // Tjek pre_price
  final String currency;
  final String? basePriceText;     // "(1 kg = 6.60)"
  double? get discountPercent => ...;
}

class Quantity {                   // aus Tjek quantity, SI-Umrechnung erhalten
  final String? unitSymbol;
  final double? sizeFrom, sizeTo;
  final String? siSymbol;
  final double? siFactor;
  final int? piecesFrom, piecesTo;
}

class ImageSet { final Uri? thumbnail, normal, large; }
```

`Store` mit `lat`/`lng`/`zip` nur dort, wo die Quelle es liefert (Tjek ja, Schwarz nur
Regionscodes).

## Adapter-Interface

```dart
abstract interface class ProspectSource {
  String get id;
  SourceCapabilities get capabilities;

  Future<List<Retailer>> fetchRetailers(RetailerQuery query);
  Future<List<Brochure>> fetchBrochures(BrochureQuery query);
  Future<Brochure> fetchBrochure(String nativeId, {Map<String, String> params});
  Future<List<Offer>> searchOffers(OfferQuery query);
  Future<List<Store>> fetchStores(StoreQuery query);
}

class SourceCapabilities {
  final bool supportsGeoSearch;      // Tjek ja, Schwarz nein
  final bool supportsOfferSearch;    // Tjek ja, Schwarz nein
  final bool supportsStores;         // Tjek ja, Schwarz nein
  final bool providesPrices;
  final bool providesPdf;
  final bool requiresRegion;         // Schwarz/Kaufland ja
}
```

`SourceCapabilities` verhindert, dass das Repository einen Adapter etwas fragt, was er nicht
kann. Nicht unterstuetzte Faehigkeiten fuehren zu einem leeren Teilergebnis mit Hinweis, nicht
zu einer Exception.

## Caching

`CacheStore` als Interface, Standardimplementierung dateibasiert mit JSON.

```dart
abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, CacheEntry entry);
  Future<void> evict(String key);
  Future<void> clear({bool expiredOnly});
}

class CacheEntry {
  final String body;
  final DateTime storedAt;
  final DateTime? expiresAt;
  final String? etag;              // fuer If-None-Match
  final String? lastModified;      // fuer If-Modified-Since
}
```

Ablauf jedes Netzwerkzugriffs:

1. Cache lesen. Frisch, also innerhalb der TTL, dann direkt zurueckgeben, kein Request.
2. Abgelaufen, aber `etag` oder `lastModified` vorhanden, dann bedingter Request. Bei 304 wird
   nur der Zeitstempel erneuert, der Body bleibt.
3. Kein Cache oder 200, dann speichern.
4. Request schlaegt fehl und ein abgelaufener Eintrag existiert, dann wird dieser mit
   `isStale: true` zurueckgegeben statt zu scheitern. Das ist die Offline-Faehigkeit.

TTLs orientieren sich an der realen Aenderungsfrequenz: Haendlerliste 7 Tage, Prospektlisten
6 Stunden, Prospektdetails 24 Stunden, Filialen 30 Tage.

## Fehlerbehandlung

Sealed class, damit der Aufrufer mit `switch` vollstaendig abdecken kann und der Compiler das
prueft.

```dart
sealed class ProspectException implements Exception {}

final class NetworkException      extends ProspectException {}  // kein Netz, DNS
final class TimeoutException      extends ProspectException {}
final class RateLimitException    extends ProspectException {}  // 429, mit retryAfter
final class SourceUnavailableException extends ProspectException {}  // 5xx
final class NotFoundException     extends ProspectException {}  // 404
final class AccessDeniedException extends ProspectException {}  // 401/403, wird nicht umgangen
final class ParseException        extends ProspectException {}  // unbekannte Struktur
final class UnsupportedOperationException extends ProspectException {}
```

Zwei Prinzipien:

1. **Keine Exception erreicht die UI.** Das Repository liefert `SourceResult<T>` mit
   `data`, `errors` je Quelle und `isPartial`. Faellt Tjek aus, liefert Schwarz trotzdem.
2. **Teilweise fehlende Daten sind kein Fehler.** Ein Angebot ohne Preis, eine Seite ohne Bild,
   ein Prospekt ohne PDF sind gueltige Zustaende des Modells, keine Ausnahmen. Der Parser
   ueberspringt kaputte Einzeleintraege und zaehlt sie in `ParseReport`, statt den ganzen
   Response zu verwerfen.

## Standalone CLI

```
prospect_client retailers [--source tjek] [--near 52.52,13.405]
prospect_client brochures <retailerId> [--near ...] [--include-expired]
prospect_client brochure <brochureId> [--pages] [--offers]
prospect_client search <query> [--near ...]
prospect_client stores <retailerId> --near 52.52,13.405
prospect_client update [--retailer ...]        Cache warmlaufen lassen
prospect_client debug <sourceId> [--raw]       Rohantwort, Capabilities, Timing
prospect_client cache (stats|clear)
```

`--json` bei jedem Kommando fuer maschinenlesbare Ausgabe.

## Flutter-Integration

Die App sieht ausschliesslich:

```dart
final repo = ProspectRepository.create(
  cacheDirectory: (await getApplicationSupportDirectory()).path,
);

final retailers = await repo.getRetailers();
final result    = await repo.getBrochures(retailerId: 'netto');
if (result.isPartial) { /* Hinweis anzeigen, Daten trotzdem nutzen */ }
final detail    = await repo.getBrochure(result.data.first.id);
```

Keine Flutter-Imports im Package. Der einzige plattformabhaengige Punkt ist das Cache-Verzeichnis,
das von aussen hereingereicht wird. Damit laeuft dieselbe Logik in der CLI, im Test und in der App.
