import '../../core/http/json_reader.dart';
import '../../core/models/brochure.dart';
import '../../core/models/brochure_page.dart';
import '../../core/models/image_set.dart';
import '../../core/models/offer.dart';
import '../../core/models/price.dart';
import '../../core/models/retailer.dart';
import '../../core/source/retailer_registry.dart';
import '../tjek/tjek_mapper.dart' show ParseReport;
import 'schwarz_api.dart';

/// Uebersetzt Schwarz-JSON in das neutrale Modell.
class SchwarzMapper {
  const SchwarzMapper();

  /// Erkennt ein abschliessendes `Z` oder einen Zonenversatz wie `+02:00`.
  static final RegExp _hasTimeZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

  Retailer retailer(SchwarzClient client) => Retailer(
        id: client.retailerId,
        name: RetailerRegistry.displayName(client.retailerId, client.displayName),
        website: switch (client.retailerId) {
          'lidl' => 'https://www.lidl.de',
          'kaufland' => 'https://filiale.kaufland.de',
          _ => null,
        },
        bindings: [
          // Bewusst ohne region_id. Ein hier hinterlegter Code gaelte als
          // ausdrueckliche Ortswahl des Aufrufers und wuerde die Aufloesung
          // aus Koordinaten aushebeln.
          SourceBinding(
            sourceId: SchwarzApi.sourceId,
            nativeId: client.clientLocale,
          ),
        ],
      );

  /// Prospekt aus einem Eintrag der Uebersicht, ohne Seiten und Produkte.
  ///
  /// Der Inhaltsgrad steht in der Uebersicht noch nicht fest, weil die
  /// Produktliste erst im Detailabruf mitkommt. Deshalb bleibt er hier
  /// [BrochureContentLevel.unknown] und wird im Detail bestimmt. "Nur Bilder"
  /// zu behaupten waere schlicht falsch: der Kaufland-Wochenprospekt enthaelt
  /// 422 Produkte, die in der Uebersicht nur nicht auftauchen.
  Brochure? overviewEntry(
    Map<String, Object?> json,
    SchwarzClient client,
    ParseReport report,
  ) {
    final id = json.stringAt('id');
    if (id == null) {
      report.skip('Prospekt ohne id');
      return null;
    }

    final name = json.stringAt('name') ?? client.displayName;
    final title = json.stringAt('title');

    return Brochure(
      id: BrochureId(SchwarzApi.sourceId, _nativeId(client, id)),
      retailerId: client.retailerId,
      title: name,
      subtitle: title,
      contentLevel: BrochureContentLevel.unknown,
      validFrom: _date(json.stringAt('offerStartDate') ?? json.stringAt('startDate')),
      validUntil: _date(json.stringAt('offerEndDate') ?? json.stringAt('endDate')),
      pageCount: 0,
      cover: ImageSet(
        thumbnail: json.uriAt('thumbnailUrl'),
        normal: json.mapAt('teasers')?.uriAt('teaser_w1010'),
        large: json.mapAt('teasers')?.uriAt('teaser_2020x1440'),
      ),
      pdfUrl: json.uriAt('hiResPdfUrl') ?? json.uriAt('pdfUrl'),
      coverage: _coverage(json),
      regionCodes: _regionCodes(json),
      webUrl: json.uriAt('flyerUrlAbsolute'),
    );
  }

  /// Liest `regions` und leitet daraus die Reichweite ab.
  ///
  /// Das Feld ist mal ein Objekt, mal ein Array, je nachdem ob der Prospekt
  /// einem oder mehreren Gebieten zugeordnet ist. Beobachtete Werte fuer
  /// `type`: `national`, `offer_region` (Lidl, rund 40 Varianten je Woche),
  /// `store` (Kaufland, Code ist die Filialnummer).
  BrochureCoverage _coverage(Map<String, Object?> json) {
    final regions = _regionObjects(json);
    if (regions.isEmpty) return BrochureCoverage.unknown;

    if (regions.any((r) => r.stringAt('type') == 'national')) {
      return BrochureCoverage.national;
    }
    if (regions.any((r) => r.stringAt('type') == 'store')) {
      return BrochureCoverage.storeBound;
    }
    if (regions.any((r) => r.stringAt('type') == 'offer_region')) {
      return BrochureCoverage.regional;
    }

    // Typ unbekannt, aber ein Code liegt vor. Code "0" ist bundesweit.
    final codes = regions.map((r) => r.stringAt('code')).nonNulls;
    if (codes.isEmpty) return BrochureCoverage.unknown;
    return codes.every((c) => c == '0')
        ? BrochureCoverage.national
        : BrochureCoverage.regional;
  }

  List<String> _regionCodes(Map<String, Object?> json) => _regionObjects(json)
      .map((r) => r.stringAt('code'))
      .nonNulls
      .where((code) => code != '0')
      .toList();

  List<Map<String, Object?>> _regionObjects(Map<String, Object?> json) {
    final regions = json['regions'];
    return switch (regions) {
      final Map<String, Object?> single => [single],
      final List<Object?> many => many.whereType<Map<String, Object?>>().toList(),
      _ => const [],
    };
  }

  /// Vollstaendiger Prospekt aus dem Detailabruf.
  Brochure flyer(
    Map<String, Object?> json,
    SchwarzClient client,
    ParseReport report,
  ) {
    final id = json.stringAt('id') ?? 'unknown';
    final products = _products(json.mapAt('products'));
    final pages = _pages(json.objectsAt('pages'), products);

    final offers = <Offer>[];
    for (final entry in products.values) {
      final offer = _offer(entry, report);
      if (offer != null) offers.add(offer);
    }

    // Inhaltsgrad aus den echten Daten ableiten, nicht raten. Kaufland liefert
    // Produkte ohne Preis, Lidl Produkte mit Preis, Sonderprospekte gar keine.
    final contentLevel = switch ((offers.isNotEmpty, offers.any((o) => o.hasPrice))) {
      (false, _) => BrochureContentLevel.imagesOnly,
      (true, false) => BrochureContentLevel.productsWithoutPrices,
      (true, true) => BrochureContentLevel.productsWithPrices,
    };

    return Brochure(
      id: BrochureId(SchwarzApi.sourceId, _nativeId(client, id)),
      retailerId: client.retailerId,
      title: json.stringAt('name') ?? client.displayName,
      subtitle: json.stringAt('title'),
      contentLevel: contentLevel,
      validFrom: _date(json.stringAt('offerStartDate') ?? json.stringAt('startDate')),
      validUntil: _date(json.stringAt('offerEndDate') ?? json.stringAt('endDate')),
      pageCount: pages.length,
      cover: ImageSet(
        thumbnail: json.uriAt('thumbnailUrl'),
        normal: json.mapAt('teasers')?.uriAt('teaser_w1010'),
        large: json.mapAt('teasers')?.uriAt('teaser_2020x1440'),
      ),
      pdfUrl: json.uriAt('hiResPdfUrl') ?? json.uriAt('pdfUrl'),
      coverage: _coverage(json),
      regionCodes: _regionCodes(json),
      pages: pages,
      offers: offers,
      webUrl: json.uriAt('flyerUrlAbsolute'),
    );
  }

  /// Weitere Prospekte, die im Detailabruf mitgeliefert werden.
  ///
  /// Macht die Quelle selbstentdeckend: aus einem Prospekt findet man die
  /// naechsten, ohne die Uebersicht erneut abzufragen.
  List<Brochure> relatedFlyers(
    Map<String, Object?> json,
    SchwarzClient client,
    ParseReport report,
  ) {
    final result = <Brochure>[];
    for (final entry in json.objectsAt('relatedFlyers')) {
      final brochure = overviewEntry(entry, client, report);
      if (brochure != null) result.add(brochure);
    }
    return result;
  }

  /// Die Produkt-Map ist auf Hotspot-IDs geschluesselt, nicht auf Produkt-IDs.
  /// Der Schluessel wird mitgefuehrt, weil die Seiten-Links darueber
  /// referenzieren.
  Map<String, Map<String, Object?>> _products(Map<String, Object?>? json) {
    if (json == null) return const {};
    final result = <String, Map<String, Object?>>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is Map<String, Object?>) {
        result[entry.key] = {...value, '_hotspotId': entry.key};
      }
    }
    return result;
  }

  List<BrochurePage> _pages(
    List<Map<String, Object?>> json,
    Map<String, Map<String, Object?>> products,
  ) =>
      [
        for (final page in json)
          BrochurePage(
            number: page.intAt('number') ?? (json.indexOf(page) + 1),
            images: ImageSet(
              thumbnail: page.uriAt('thumbnail'),
              normal: page.uriAt('image'),
              large: page.uriAt('zoom'),
            ),
            dimensions: _dimensions(page),
            altText: page.stringAt('altText'),
            hotspots: _hotspots(page, products),
          ),
      ];

  PageDimensions? _dimensions(Map<String, Object?> page) {
    final width = page.doubleAt('width');
    final height = page.doubleAt('height');
    if (width == null || height == null) return null;
    return PageDimensions(width, height);
  }

  /// Links einer Seite. Die Koordinaten sind bereits Prozentwerte, hier ist
  /// also anders als bei Tjek keine Umrechnung noetig.
  List<Hotspot> _hotspots(
    Map<String, Object?> page,
    Map<String, Map<String, Object?>> products,
  ) {
    final result = <Hotspot>[];
    for (final link in page.objectsAt('links')) {
      final left = link.doubleAt('left');
      final top = link.doubleAt('top');
      final width = link.doubleAt('width');
      final height = link.doubleAt('height');
      if (left == null || top == null || width == null || height == null) {
        continue;
      }

      final hotspotId = link.stringAt('id');
      final isProduct = link.stringAt('displayType') == 'product';

      // Der Link referenziert den Hotspot-Schluessel, das Angebot traegt
      // spaeter aber die Produkt-ID. Hier wird umgeschluesselt.
      String? offerId;
      if (isProduct && hotspotId != null) {
        final product = products[hotspotId];
        final productId = product == null ? null : product['productId'];
        if (productId is String) offerId = productId;
      }

      result.add(
        Hotspot(
          left: left,
          top: top,
          width: width,
          height: height,
          offerId: offerId,
          label: link.stringAt('title'),
          link: isProduct ? null : link.uriAt('url'),
        ),
      );
    }
    return result;
  }

  Offer? _offer(Map<String, Object?> json, ParseReport report) {
    final productId = json.stringAt('productId');
    final title = json.stringAt('title');
    if (productId == null || title == null) {
      report.skip('Produkt ohne productId oder title');
      return null;
    }

    final price = json.doubleAt('price');
    final currency = json.stringAt('currencyText') ?? 'EUR';

    return Offer(
      // Produkt-ID als Angebots-ID: sie ist innerhalb eines Prospekts eindeutig
      // und laesst sich ueber mehrere Prospekte hinweg wiedererkennen.
      id: productId,
      title: title.trim(),
      description: _stripHtmlEntities(json.stringAt('description')),
      brand: json.stringAt('brand'),
      price: price == null ? null : Price(current: price, currency: currency),
      image: ImageSet(normal: json.uriAt('image')),
      categories: _categories(json),
      link: json.uriAt('url'),
      externalProductId: productId,
    );
  }

  /// `categoryPrimary` ist ein Pfad der Form `Kategorien/Baumarkt/Werkstatt`.
  /// Das erste Segment ist ein Sammelbegriff ohne Informationswert und wird
  /// ausgelassen.
  List<String> _categories(Map<String, Object?> json) {
    final path = json.stringAt('categoryPrimary');
    if (path == null) return const [];
    final segments = path.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty);
    return segments.length > 1 ? segments.skip(1).toList() : segments.toList();
  }

  /// Die Beschreibungen enthalten HTML-Entities wie `&auml;`. Ein voller
  /// HTML-Parser waere hier ueberdimensioniert, es kommen nur die deutschen
  /// Umlaute und wenige Sonderzeichen vor.
  String? _stripHtmlEntities(String? value) {
    if (value == null) return null;
    const replacements = {
      '&auml;': 'a', '&ouml;': 'o', '&uuml;': 'u',
      '&Auml;': 'A', '&Ouml;': 'O', '&Uuml;': 'U',
      '&szlig;': 'ss', '&amp;': '&', '&quot;': '"',
      '&lt;': '<', '&gt;': '>', '&nbsp;': ' ',
    };
    var result = value;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.trim();
  }

  /// Trenner zwischen Mandant und Prospekt-ID in der nativen ID.
  ///
  /// Bewusst ein Punkt: die IDs landen als Ganzes in CLI-Argumenten, und
  /// Zeichen wie `|` oder `/` muessten dort in jeder Shell einzeln escaped
  /// werden. Ein Punkt kommt weder in Haendler-IDs noch in den UUIDs der
  /// Quelle vor und ist damit eindeutig.
  static const String nativeIdSeparator = '.';

  /// Prospekt-IDs der Quelle sind ohne Mandant nicht aufloesbar, deshalb wird
  /// der Mandant in die native ID kodiert: `kaufland.019fa326-...`.
  String _nativeId(SchwarzClient client, String flyerId) =>
      '${client.retailerId}$nativeIdSeparator$flyerId';

  /// Gegenstueck zu [_nativeId].
  static (String retailerId, String flyerId)? splitNativeId(String nativeId) {
    final index = nativeId.indexOf(nativeIdSeparator);
    if (index <= 0 || index == nativeId.length - 1) return null;
    return (nativeId.substring(0, index), nativeId.substring(index + 1));
  }

  /// Die Uebersicht liefert Datumsangaben als `2026-08-08`, der Detailabruf
  /// zusaetzlich als `08/09/2026 00:00:00`. Beide Formate werden unterstuetzt.
  ///
  /// Keine der beiden Varianten traegt eine Zeitzone. `DateTime.tryParse`
  /// deutet solche Angaben als Ortszeit, ein anschliessendes `toUtc()` schoebe
  /// sie dann um den Zonenversatz. Aus dem 08.08. wuerde in Mitteleuropa der
  /// 07.08. um 22 Uhr, und ein Prospekt erschiene einen Tag zu frueh. Deshalb
  /// werden die Angaben als Kalenderdaten in UTC gelesen.
  static DateTime? _date(String? value) {
    if (value == null || value.isEmpty) return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) {
      // Traegt die Angabe eine Zone, hat Dart bereits korrekt umgerechnet.
      if (iso.isUtc || _hasTimeZone.hasMatch(value)) return iso.toUtc();
      return DateTime.utc(
        iso.year,
        iso.month,
        iso.day,
        iso.hour,
        iso.minute,
        iso.second,
      );
    }

    final match =
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})(?:\s+(\d{2}):(\d{2}):(\d{2}))?$')
            .firstMatch(value);
    if (match == null) return null;
    return DateTime.utc(
      int.parse(match.group(3)!),
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(4) ?? '0'),
      int.parse(match.group(5) ?? '0'),
      int.parse(match.group(6) ?? '0'),
    );
  }
}
