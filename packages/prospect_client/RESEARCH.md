# Prospekt-Modul: Quellenrecherche (Phase 1-3)

Stand: 2026-08-10. Alle Angaben wurden durch eigene HTTP-Probes und Browser-Netzwerkanalyse
verifiziert, nicht nur aus Dokumentation uebernommen.

Methodik: unauthentifizierte GET-Requests gegen Kandidaten-Endpunkte, Auswertung der
`__NEXT_DATA__`-Payloads bzw. `performance.getEntriesByType('resource')` in einem echten Browser,
Pruefung von `robots.txt`. Es wurden keine Captchas, Rate Limits, Signaturen oder
Authentifizierungen umgangen.

---

## 1. Ergebnis der Suche nach offiziellen APIs

Es existiert **keine offizielle, oeffentlich dokumentierte und frei nutzbare API** eines der
genannten Haendler fuer Prospektdaten. Konkret geprueft:

| Gesucht | Ergebnis |
|---|---|
| Offizielle Haendler-APIs (REWE, EDEKA, dm, ...) | Nicht vorhanden. Interne Endpunkte sind bot-geschuetzt (siehe 4.). |
| Partner-/Affiliate-API Bonial | Existiert als B2B-Vertriebsprodukt, kein Self-Service-Portal, keine oeffentliche Doku. Zugang nur ueber Vertragsabschluss. |
| Offerista / Marktjagd API | `api.marktjagd.de` und `api.offerista.com` loesen nicht mehr auf (NXDOMAIN). Historische offene API ist abgeschaltet. |
| Open-Data-Feeds | Keine. |
| GraphQL-Endpunkte | Bei keinem der Kandidaten gefunden. |

Es gibt jedoch zwei **frei erreichbare, unauthentifizierte REST-APIs**, die faktisch als
oeffentliche Schnittstelle funktionieren: Tjek und Schwarz Leaflets. Beide sind unten dokumentiert.

---

## 2. Quelle A: Tjek (squid-api)

**Anbieter:** Tjek A/S (frueher ShopGun / eTilbudsavis), Daenemark. Betreibt Prospekt-Plattformen
in DK/NO/SE/DE und liefert die Pageflip-Technologie fuer Haendler.

**Basis-URL:** `https://squid-api.tjek.com`
**Auth:** keine. Alle unten genannten Endpunkte antworten ohne API-Key, Token oder Signatur.
**Format:** JSON, `Content-Type: application/json; charset=utf-8`
**robots.txt:** vorhanden? Nein (404), keine Crawl-Restriktion deklariert.

### Verifizierte Endpunkte

| Endpunkt | Parameter | Liefert |
|---|---|---|
| `GET /v2/dealers` | `limit`, `offset` (max. ca. 300 Eintraege ohne Filter) | Haendlerliste: `id`, `name`, `website`, `description`, `logo`, `color`, `country`, `markets` |
| `GET /v2/dealers/{id}` | - | Einzelner Haendler |
| `GET /v2/catalogs` | `dealer_id`, `r_lat`, `r_lng`, `r_radius` (Meter), `limit`, `offset` | Prospekte: `id`, `label`, `run_from`, `run_till`, `publish`, `page_count`, `offer_count`, `branding`, `dealer_id`, `store_id`, `dimensions`, `images`, `pages`, `pdf_url`, `category_ids`, `all_stores` |
| `GET /v2/catalogs/{id}/pages` | - | Pro Seite: `thumb`, `view`, `zoom` (drei Aufloesungen) |
| `GET /v2/catalogs/{id}/hotspots` | - | Verknuepfung Angebot zu Seitenkoordinaten |
| `GET /v2/offers` | `r_lat`, `r_lng`, `r_radius`, `limit`, `offset` | Angebote, siehe Struktur unten |
| `GET /v2/offers/search` | zusaetzlich `query` | Volltextsuche ueber Angebote |
| `GET /v2/stores` | `dealer_id`, `limit` | Filialen: `street`, `city`, `zip_code`, `latitude`, `longitude`, `country`, `dealer_id` |

**Wichtig:** Der Filter heisst `dealer_id` (Singular). Die haeufig zitierte Array-Variante
`dealer_ids[]` wird stillschweigend ignoriert und liefert ungefilterte Ergebnisse. Das ist eine
echte Fehlerquelle, die im Adapter abgefangen werden muss.

### Struktur eines Angebots (real, gekuerzt)

```json
{
  "id": "dBBzfCXpmejJHRmGHUjXn",
  "ern": "ern:offer:dBBzfCXpmejJHRmGHUjXn",
  "heading": "frija H-Milch 3,5 % Fett*",
  "description": "1 Liter statt 0.95 Netto EIGEN MARKE - 21 %",
  "catalog_page": 1,
  "pricing":  { "price": 0.75, "pre_price": 0.95, "currency": "EUR" },
  "quantity": { "unit": { "symbol": "l", "si": { "symbol": "l", "factor": 1 } },
                "size": { "from": 1, "to": 1 },
                "pieces": { "from": 1, "to": 1 } },
  "images":   { "thumb": "...", "view": "...", "zoom": "..." }
}
```

Das ist das mit Abstand sauberste Preismodell aller geprueften Quellen: normalisierter
Zahlenpreis, Altpreis, Waehrung, Mengeneinheit mit SI-Umrechnungsfaktor.

### Deutsche Abdeckung (gemessen)

Scan ueber 20 geografische Punkte in Deutschland, Radius 80 km:

| Haendler | `dealer_id` | Prospekte | Angebote mit Preis |
|---|---|---|---|
| Netto | `90f2VL` | 14 | ca. 3900 |
| CITTI | `3czmZx` | 8 | ca. 1070 |
| Kaufland | `L5IgL3` | 3 | ca. 860 |
| Penny | `NI83Ob` | 3 | ca. 770 |
| ALDI Sued | `vP0uRj` | 36 | 0 (nur Seitenbilder) |
| ALDI Nord | `jw3HRk` | 28 | 0 (nur Seitenbilder) |
| Hit | `JBcWUF` | 13 | 0 (nur Seitenbilder) |
| famila Nordost | `5-8Pt7` | 10 | 0 (nur Seitenbilder) |
| famila Nordwest | `ZbfgfZ` | 9 | 0 (nur Seitenbilder) |
| Grenzhandel (fakta, Fleggaard, Bordershop, Poetzsch, Koebmandsgaarden) | div. | 10 | ca. 1600 |

**Nicht abgedeckt:** REWE (Dealer-Eintrag `VkDi4C` existiert, aber 0 aktive Prospekte), EDEKA,
Lidl, dm, Rossmann, NORMA, Globus, tegut.

**Bewertung:** Beste Datenqualitaet, aber nur etwa die Haelfte der Zielhaendler, und bei ALDI /
Hit / famila nur Bilder ohne Produktdaten.

---

## 3. Quelle B: Schwarz Leaflets API (Lidl + Kaufland)

**Anbieter:** Schwarz Gruppe, erstanbieterig fuer Lidl und Kaufland.
**Basis-URL:** `https://endpoints.leaflets.schwarz`
**Auth:** keine.
**Gefunden ueber:** Netzwerkanalyse von `lidl.de/l/prospekte/...` im Browser.

### Verifizierte Endpunkte

| Endpunkt | Parameter | Liefert |
|---|---|---|
| `GET /v4/overview` | `client_locale` (z.B. `lidl/de-DE`) | Kategorien, Unterkategorien, Prospektliste |
| `GET /v4/flyer` | `flyer_identifier`, `region_id`, `region_code`, `client_locale` | Vollstaendiger Prospekt |
| `GET /v4/translations` | `domain_url`, `client_locale` | UI-Uebersetzungen (fuer uns irrelevant) |

`GET /v4/overview?client_locale=lidl/de-DE` liefert aktuell 50 Prospekte in 4 Kategorien.
Fuer `kaufland/de-DE` antwortet der Endpunkt mit HTTP 400:
`"The non-regionalized endpoint has been disabled for this client."`
Kaufland erzwingt also eine Region. Die steckt in der Prospekt-URL
(`leaflets.kaufland.com/de-DE/DE_de_KDZ1_3000_D32/ar/3000`, Region `3000`) und der
Einzelprospekt-Abruf funktioniert damit einwandfrei.

Achtung: Dass Lidl die Uebersicht auch ohne `region_id` beantwortet, heisst **nicht**, dass
Lidl national verteilt. Beide Mandanten sind regionalisiert, Lidl erzwingt den Parameter nur
nicht. Siehe Abschnitt 3bb.

### Struktur eines Prospekts (real, gekuerzt)

Antwortgroesse fuer einen Lidl-Wochenprospekt: ca. 400 KB, 73 Seiten, 162 Produkt-Hotspots.

```
flyer:
  id, name, title, locale, clientLocale, countryCode, category, subcategory
  startDate, endDate, offerStartDate, offerEndDate, isActive, status
  pdfUrl, hiResPdfUrl, fileSize, hiResFileSize
  teasers { teaser_666x475, teaser_2020x1440, teaser_w1010 }
  thumbnailUrl, flyerUrlAbsolute, regions[]
  pages[]:
    id, number, width, height, type, altText, keyWords
    image, zoom, thumbnail        # drei Aufloesungen
    links[]: url, title, icon, top, left, width, height   # relative Prozentkoordinaten
  products{}:                      # Map: hotspotId -> Produkt
    productId, title, brand, price, currencyText, currencySymbol
    description, image, url, canonicalUrl
    categoryPrimary, categoryPrimaryPath, wonCategoryPrimary
  relatedFlyers[]: id, slug, name, title, url, startDate, endDate,
                   thumbnailUrl, pdfUrl, regionCodes, stores
```

Besonderheiten:
- `pdfUrl` liefert das komplette Prospekt-PDF ohne Auth (Beispiel: 52 MB).
- `altText` ist eine brauchbare, offenbar generierte Bildbeschreibung pro Seite.
- `relatedFlyers` macht die Quelle **selbstentdeckend**: aus einem Prospekt findet man die
  naechsten, ohne die Website zu parsen.
- Bildauslieferung ueber `imgproxy.leaflets.schwarz` mit **signierten URLs**
  (HMAC-Prefix + base64-kodierter S3-Pfad). Bild-URLs koennen also nicht selbst konstruiert
  werden, sie muessen aus der API uebernommen werden. Das ist bewusst kein Hindernis, das
  umgangen werden darf oder muss, die API liefert sie ja mit.

**Einschraenkung:** `products` enthaelt nur Artikel mit Onlineshop-Verknuepfung (bei Lidl
ueberwiegend Non-Food wie PARKSIDE). Die Lebensmittel-Wochenangebote stehen ausschliesslich im
Seitenbild und im `keyWords`-Feld, nicht als strukturierte Preisdaten.

---

### 3b. Nachtrag: Lassen sich Produkte doch aus den Online-Prospekten ziehen?

Gezielte Nachpruefung, ob es fuer die Bild-Prospekte einen zweiten Weg zu strukturierten
Produktdaten gibt (AJAX, REST oder sonstige API).

**Tjek / ALDI Sued (`dealer_id=vP0uRj`): nein, definitiv nicht.**

| Test | Ergebnis |
|---|---|
| `GET /v2/catalogs/8ryfem3B/hotspots` | `[]` |
| `GET /v2/offers?dealer_id=vP0uRj` | `[]` |
| `incito_publication_id` im Katalog | leer |
| `types` | `paged` (reines Seitenformat, kein strukturiertes Incito) |
| `pdf_url` | leer |

Die Daten existieren bei Tjek schlicht nicht. ALDI liefert dort nur Seitenbilder.

**Schwarz / Lidl: strukturierte Produkte ja, Lebensmittel nein.**

Alle 162 Produkte des Wochenprospekts haben einen Preis, aber die Kategorieverteilung ist
eindeutig:

```
36  Wohnen & Einrichten     11  Gesundheit & Pflege     8  Tierwelt
29  Mode                    11  Spirituosen             7  Kinderwelt
28  Haushalt & Kueche       10  Weinwelt
14  Baumarkt                 8  Sport & Freizeit
```

Treffer in Lebensmittelkategorien: **0**. Die Produkt-Map deckt ausschliesslich Artikel mit
Onlineshop-Verknuepfung ab. Die Suche im Prospektviewer ist rein clientseitig ueber die bereits
geladenen `keyWords` und loest keinen zusaetzlichen Request aus (per fetch- und XHR-Hook im
Browser verifiziert: nach dem Laden feuert kein weiterer API-Call).

**Schwarz / Kaufland: deutlich besser als erwartet.**

Der Kaufland-Wochenprospekt enthaelt **422 Produkte inklusive Lebensmitteln**
(K-PURLAND Schweinerueckensteak, GERAMONT Weichkaese, TOFFIFEE, DANONE Actimel XXL).
Die Felder sind allerdings reduziert auf `productId`, `title`, `image`, alle drei zu 100 Prozent
befuellt, **ohne Preis**.

Zusaetzlich traegt jeder Produkt-Hotspot in `pages[].links[]` einen `displayType: "product"` mit
Detail-URL und exakter Position auf der Seite:

```
https://filiale-fc.kaufland.de/angebote/detail.storeName=DE3000.articleId=00014395.advertisingWeek=32.iframe.html
```

Diese Detail-URL liefert **HTTP 403 "Not allowed"**, sowohl per HTTP-Client als auch im echten
Browser. Das passt zu den Flags im Prospekt selbst (`showProductDetails: false`,
`showProductLinks: false`): Kaufland hat das Feature deaktiviert. Das ist eine bewusst gesetzte
Sperre und wurde nicht umgangen.

**Fazit des Nachtrags:** Preise fuer Lebensmittel sind ueber Lidl und Kaufland auf legitimem Weg
nicht zu bekommen. Was zu bekommen ist, und was das Modell abbilden muss:

| Haendler | Quelle | Produktname | Bild | Preis | Seitenposition |
|---|---|---|---|---|---|
| Netto, Penny, Kaufland, CITTI | Tjek | ja | ja | **ja** | ja (Hotspots) |
| Kaufland | Schwarz | ja (422) | ja | nein | **ja** (Prozentkoordinaten) |
| Lidl | Schwarz | ja (162, Non-Food) | ja | **ja** | ja |
| ALDI Nord/Sued, Hit, famila | Tjek | nein | nein | nein | nein |

Bemerkenswert: Kaufland ist ueber **beide** Quellen erreichbar. Tjek liefert dort Preise,
Schwarz liefert mehr Produkte und die Seitenpositionen. Das ist ein starkes Argument dafuer,
dass das Datenmodell mehrere Quellen pro Haendler zulassen muss statt einer festen 1:1-Zuordnung.

### 3bb. Korrektur: Prospekte sind ueberwiegend filialabhaengig

Nachtraeglich geprueft und dabei einen Fehler in der urspruenglichen Fassung dieses Dokuments
gefunden. Dort stand, Lidl liefere seine Prospekte national. **Das ist falsch.**

**Lidl ist regionalisiert.** Die Uebersicht meldet `isRegionalized: true`. Von den 42 Eintraegen
in "Unsere Aktionsprospekte" traegt genau einer `regions: [{type: national, code: "0"}]`, alle
uebrigen tragen Listen von `offer_region`-Codes:

```
Prospekt A: national, code 0
Prospekt B: offer_region 31, 4, 647, 9
Prospekt C: offer_region 19, 20, 32
Prospekt D: offer_region 12, 16, 36, 5, 6
```

Es sind also nicht 42 verschiedene Prospekte, sondern im Wesentlichen ein Wochenprospekt in
etwa 40 Regionalvarianten. `GET /v4/overview?client_locale=lidl/de-DE&region_id=31` reduziert
die Trefferzahl von 50 auf 10. Der Parameter wirkt, er wurde nur nicht genutzt.

**Kaufland ist ebenfalls regionalisiert, und die Regionen unterscheiden sich real:**

| `region_id` | Prospekte |
|---|---|
| 1000 | 1 |
| 2000 | 5 |
| 3000 | 6 |
| 3500 | 5 |
| 4000 | 1 |
| 5000 | 1 |

Die Prospekt-IDs je Region sind bis auf einen gemeinsamen Eintrag verschieden.

**Tjek: 9 von 22 Katalogen im Umkreis deutscher Grossstaedte sind filialgebunden**
(`all_stores: false`). Am deutlichsten bei HIT: pro Stadt ein eigener Katalog.

```
dealer_id=JBcWUF (HIT), r_radius=30000
  Berlin   -> 1wunFcDz
  Koeln    -> fFEgRsl0
  Muenchen -> gv4cq8Ku
  Hamburg  -> (keiner)
```

Ohne Geofilter liefert derselbe Aufruf **50 filialspezifische Prospekte** am Stueck:
"HIT Prospekt KW 33/2026 Hann. Muenden", "... Bonn-Bad Godesberg", "... Muenster" und so weiter.

Aufschluesselung nach Haendler (Umkreis von fuenf Grossstaedten, 80 km):

| Haendler | Kataloge | davon filialgebunden |
|---|---|---|
| HIT | 4 | 4 |
| famila Nordost | 3 | 3 |
| famila Nordwest | 3 | 1 |
| PENNY | 1 | 1 |
| ALDI Nord, ALDI Sued, CITTI, Netto | 12 | 0 |

Netto und ALDI verteilen tatsaechlich national, HIT und famila strikt filialweise.

**Nutzbare Gegenstuecke:**

- Tjek: `GET /v2/catalogs/{id}/stores` liefert die zugehoerigen Filialen mit Adresse und
  Koordinaten. Fuer den Berliner HIT-Prospekt genau drei Filialen. Auch fuer nationale
  Prospekte nutzbar, dort kommen alle Filialen im Umkreis.
- Tjek: `all_stores` unterscheidet national von filialgebunden.
- Schwarz: `region_id` filtert korrekt, sowohl bei Kaufland als auch bei Lidl.

**Nicht vorhanden:** Ein Endpunkt, der einen Ort oder eine PLZ auf einen Schwarz-Regionscode
abbildet. `/v4/regions`, `/v4/stores` und `/v4/region?zip=` antworten alle mit HTTP 404. Auf
lidl.de uebernimmt das ein separates Frontend (`storesearch-frontend`), ueber das der Nutzer
seine Filiale waehlt. Die Zuordnung Ort zu Regionscode muss also entweder vom Nutzer kommen
oder aus einer eigenen Quelle stammen.

### 3c. Endgueltige Endpunkt-Definition Schwarz

Die Quelle ist vollstaendig selbstbeschreibend, es muessen keine URLs konstruiert werden:

1. `GET /v4/overview?client_locale={brand}/de-DE` fuer Lidl (national)
2. `GET /v4/overview?client_locale=kaufland/de-DE&region_id={code}` fuer Kaufland
   (`region_id` ohne Wert liefert HTTP 400, intern wird daraus `store_id`; getestet: 1000, 2000,
   3000, 3500 liefern alle unterschiedliche Prospektmengen)
3. Jeder Listeneintrag enthaelt `flyerJson` mit der fertigen Detail-URL, dazu `pdfUrl`,
   `hiResPdfUrl`, `thumbnailUrl`, `teasers`, `startDate`, `endDate`, `regions`, `status`
4. `GET {flyerJson}` liefert den vollstaendigen Prospekt

---

## 4. Quelle C: Bonial (kaufDA / MeinProspekt)

**Anbieter:** Bonial International GmbH, Berlin. Groesster deutscher Prospekt-Aggregator,
nach eigenen Angaben ueber 350 Haendler.

**Technik:** Next.js mit Server Side Rendering. Die vollstaendigen Prospekt- und Angebotsdaten
liegen im `__NEXT_DATA__`-Script-Tag der SEO-Landingpages (`/Geschaefte/REWE`), ca. 108 KB JSON
pro Seite. Kein XHR-Aufruf noetig, die Daten sind bereits im HTML.

Datenqualitaet ist die hoechste aller geprueften Quellen:

```
brochure: id, title, pageCount, pages[{page, url{large,normal,thumbnail}}],
          publishedFrom/Until, validFrom/Until, publisher{id,name,logo,type}, contentBadges
offer:    id, title, brand, description,
          prices{ mainPrice, mainPriceFormatted, secondaryPrice, priceByBaseUnit,
                  conditions[], priceRange, secondaryPriceIsUVP }
          categories[], categoryPaths[[{id,name}...]]   # vollstaendige Kategoriehierarchie
          offerImages{url{large,normal,thumbnail}}
          parentContent{ id, legacyId, page{number}, type }   # Angebot -> Prospektseite
          publisherId ("DE-1062"), validFrom, validUntil
```

### Rechtliche Bewertung: kritisch

`https://www.kaufda.de/robots.txt` untersagt fuer `User-agent: *` explizit:

```
crawl-delay: 2
Disallow: /Catalogue/            # Web-Prospektviewer
Disallow: /mv/                   # Mobiler Viewer
Disallow: /brochure-viewer/brochure
Disallow: /api/febe/
Disallow: /api/frontend/
Disallow: /*/*/ajax/
Disallow: /search
```

Damit ist der automatisierte Zugriff auf den Prospektviewer und die internen APIs vom Betreiber
ausdruecklich unerwuenscht. Nur die SEO-Landingpages sind freigegeben, und das mit einer
Crawl-Verzoegerung von 2 Sekunden. Die vollstaendigen Prospektseiten (ueber die erste Seite
hinaus) liegen genau hinter den gesperrten Viewer-Pfaden.

**Konsequenz:** Bonial ist technisch die beste, rechtlich aber die problematischste Quelle. Ein
produktiver Einsatz sollte ueber den kostenpflichtigen Partnervertrag laufen, nicht ueber
Scraping.

---

## 5. Quelle D: Marktguru

**Basis-URL:** `https://api.marktguru.de/api/v1/...`
**Auth:** erforderlich. `GET /api/v1/offers/search` antwortet ohne Header mit
HTTP 401 `"Invalid or missing api key"`. Benoetigt werden `x-apikey` und `x-clientkey`.

Diese Keys sind zwar im oeffentlichen Web-Bundle eingebettet und diverse Open-Source-Projekte
extrahieren sie automatisiert. Genau das ist aber das Umgehen einer vom Betreiber gesetzten
Zugangskontrolle und widerspricht der Vorgabe, keine Zugriffsschutzmassnahmen zu umgehen.

**Bewertung: ausgeschlossen.** Aufgenommen nur zur Vollstaendigkeit der Recherche.

Randnotiz: `marktguru.de/robots.txt` erlaubt zwar alles und listet Sitemaps, der dort verlinkte
`update.rss` enthaelt jedoch ausschliesslich Cashback-Aktionen, keine Prospekte.

---

## 6. Quelle E: Haendlereigene Websites

Direkt getestet, ohne Browser, mit Standard-Browser-User-Agent:

| Haendler | URL | Status | Befund |
|---|---|---|---|
| Lidl | `lidl.de/c/online-prospekte` | 200 | Schwarz-API, siehe 3. |
| Kaufland | `filiale.kaufland.de/prospekte.html` | 200 | Schwarz-API, regionalisiert |
| REWE | `mobile-api.rewe.de` | **403** | Bot-Schutz |
| ALDI Sued | `aldi-sued.de/de/prospekte.html` | **403** | Akamai Access Denied |
| ALDI Nord | `aldi-nord.de/prospekte.html` | **403** | Bot-Schutz |
| EDEKA | `edeka.de/eh/services/prospekte.jsp` | **403** | Bot-Schutz |
| Netto | `netto-online.de/filialangebote` | **403** | Bot-Schutz |
| NORMA | `norma-online.de/de/angebote/` | 200 | FlippingBook-Viewer, PDF-basiert |
| dm | `dm.de/services/prospekte` | 200 | keine Prospektdaten im HTML |
| Rossmann | `rossmann.de/de/prospekte/` | 200 | keine Prospektdaten im HTML |
| Penny | `penny.de/services/prospekte` | 404 | Pfad veraltet |
| tegut | `tegut.com/angebote/prospekte.html` | 404 | Pfad veraltet |
| Globus | `globus.de/prospekte` | TLS-Fehler | nicht erreichbar |

Kernaussage: Bei sechs von dreizehn Haendlern steht eine aktive Bot-Erkennung davor. Das ist eine
Zugriffsschutzmassnahme. Diese Quellen sind damit fuer das Modul nicht nutzbar, ausser ueber
einen Aggregator, der die Inhalte lizenziert ausliefert.

---

## 7. Phase 3: Bewertungstabelle

| Quelle | Haendler | API | Datenqualitaet | Stabilitaet | Aufwand | Empfehlung |
|---|---|---|---|---|---|---|
| **Tjek squid-api** | Netto, Penny, Kaufland, ALDI Nord+Sued, Hit, famila, CITTI (9-14) | REST v2, keine Auth, versioniert | **Sehr hoch.** Preis, Altpreis, Waehrung, Menge mit SI-Einheit, Bild, Seitenzuordnung, Filialen mit Geokoordinaten | **Hoch.** Versionierter Pfad, kommerzielles Produkt, seit Jahren stabil | Gering | **Primaerquelle** |
| **Schwarz Leaflets** | Lidl, Kaufland | REST v4, keine Auth, versioniert | **Mittel bis hoch.** Seiten in 3 Aufloesungen, PDF, Gueltigkeit, Regionen, Produkt-Hotspots nur fuer Onlineshop-Artikel | **Hoch.** Erstanbieterig, `relatedFlyers` macht sie selbstentdeckend | Gering bis mittel | **Zweitquelle** |
| **Bonial / kaufDA** | 350+, inkl. REWE, EDEKA, dm, Rossmann | Keine API, SSR-JSON im HTML | **Hoechste.** Kategoriehierarchie, Marke, Grundpreis, UVP-Flag, Angebot-zu-Seite-Mapping | **Mittel.** `buildId` und Next.js-Struktur aendern sich bei jedem Deploy | Mittel | **Nur mit Partnervertrag.** robots.txt untersagt Viewer und interne APIs |
| **Marktguru** | viele | REST v1, API-Key noetig | Hoch | Mittel | Gering | **Ausgeschlossen**, Key-Extraktion waere Umgehung |
| **Haendlerseiten direkt** | einzeln | keine | schwankend | **Niedrig.** HTML-Struktur bricht jederzeit | **Hoch**, ein Adapter pro Haendler | Nur Einzelfaelle (NORMA-PDF) |

### Antworten auf die konkreten Bewertungsfragen

| Frage | Tjek | Schwarz | Bonial |
|---|---|---|---|
| Echte strukturierte Daten? | ja | teilweise | ja |
| PDF/Bilder verarbeiten noetig? | nein | fuer Food-Preise ja | nein fuer Angebote |
| Haendler-ID vorhanden? | ja (`dealer_id`) | implizit ueber `client_locale` | ja (`DE-1062`) |
| Standort-/Filialdaten? | ja, mit Geokoordinaten | nur Regionscodes | ja, ueber Stadt/PLZ |
| Start-/Enddatum? | ja (`run_from`/`run_till`) | ja (`startDate`/`endDate`) | ja, getrennt nach publish/valid |
| Produktinformationen? | ja | nur Onlineshop-Artikel | ja |
| Preise? | ja, normalisiert | nur Onlineshop-Artikel | ja, inkl. Grundpreis |
| Kategorien? | nur IDs | ja, als Pfad-String | ja, volle Hierarchie mit IDs |
| Bilder? | ja, 3 Aufloesungen | ja, 3 Aufloesungen + PDF | ja, 3 Aufloesungen |

---

## 8. Fazit

Keine Einzelquelle deckt alle Zielhaendler ab. Das ist die zentrale Erkenntnis und der Grund,
warum die geforderte Adapter-Architektur nicht optional, sondern notwendig ist.

Realistisch erreichbare Abdeckung ohne Vertragsabschluss und ohne Umgehung von Schutzmassnahmen:

- ueber Tjek: Netto, Penny, Kaufland, ALDI Nord, ALDI Sued, Hit, famila Nordost, famila Nordwest, CITTI
- ueber Schwarz: Lidl, Kaufland
- offen: REWE, EDEKA, dm, Rossmann, NORMA, Globus, tegut

Von den 13 genannten Wunschhaendlern sind damit 6 vollstaendig abgedeckt (Lidl, Kaufland, Penny,
Netto, ALDI Nord, ALDI Sued), davon 4 mit Preisdaten und 2 nur mit Seitenbildern. 7 bleiben offen:
REWE, EDEKA, dm, Rossmann, NORMA, Globus, tegut. Fuer diese Luecke gibt es genau zwei legitime
Wege: einen Bonial-Partnervertrag oder Einzelvereinbarungen mit den Haendlern.
