import '../../core/http/json_reader.dart';
import '../../core/models/brochure.dart';
import '../../core/models/brochure_page.dart';
import '../../core/models/geo.dart';
import '../../core/models/image_set.dart';
import '../../core/models/offer.dart';
import '../../core/models/price.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/retailer_registry.dart';
import 'tjek_api.dart';

/// Zaehlt uebersprungene Eintraege beim Mapping.
///
/// Ein einzelner kaputter Datensatz darf nie die ganze Antwort verwerfen.
/// Stattdessen wird er ausgelassen und hier vermerkt, damit die CLI und die
/// App sichtbar machen koennen, dass etwas nicht stimmt.
class ParseReport {
  int skipped = 0;
  final List<String> reasons = [];

  void skip(String reason) {
    skipped++;
    if (reasons.length < 10 && !reasons.contains(reason)) reasons.add(reason);
  }

  bool get hasIssues => skipped > 0;

  String get summary =>
      '$skipped Eintrag/Eintraege uebersprungen: ${reasons.join('; ')}';
}

/// Uebersetzt Tjek-JSON in das neutrale Modell.
///
/// Einzige Stelle im Adapter, an der Tjek-Feldnamen vorkommen.
class TjekMapper {
  const TjekMapper();

  Retailer? retailer(Map<String, Object?> json, ParseReport report) {
    final id = json.stringAt('id');
    final name = json.stringAt('name');
    if (id == null || name == null) {
      report.skip('Haendler ohne id oder name');
      return null;
    }
    final canonical = RetailerRegistry.canonicalId(name);
    return Retailer(
      id: canonical,
      name: RetailerRegistry.displayName(canonical, name),
      website: json.stringAt('website'),
      description: json.stringAt('description'),
      logo: ImageSet(normal: json.uriAt('logo')),
      colorHex: json.stringAt('color'),
      countryCode: json.mapAt('country')?.stringAt('id') ?? 'DE',
      bindings: [SourceBinding(sourceId: TjekApi.sourceId, nativeId: id)],
    );
  }

  /// Prospekt aus einem `catalogs`-Eintrag, ohne Seiten und Angebote.
  ///
  /// [BrochureContentLevel] wird aus `offer_count` abgeleitet. Das ist der
  /// entscheidende Punkt: ALDI liefert dort konsistent 0, Netto mehrere
  /// hundert. Ein Prospekt mit 0 Angeboten ist bei Tjek immer ein reiner
  /// Bildprospekt, kein Fehler und kein noch nicht geladener Zustand.
  Brochure? brochure(Map<String, Object?> json, ParseReport report) {
    final id = json.stringAt('id');
    if (id == null) {
      report.skip('Prospekt ohne id');
      return null;
    }

    final branding = json.mapAt('branding');
    final dealerName = branding?.stringAt('name') ??
        json.mapAt('dealer')?.stringAt('name') ??
        'unknown';
    final offerCount = json.intAt('offer_count') ?? 0;

    // `all_stores` unterscheidet bundesweite von filialgebundenen Prospekten.
    // Ohne diese Angabe waere die Liste irrefuehrend: HIT veroeffentlicht
    // denselben Wochenprospekt in ueber 50 Filialvarianten, Netto dagegen
    // wirklich bundesweit.
    final allStores = json.boolAt('all_stores');

    return Brochure(
      id: BrochureId(TjekApi.sourceId, id),
      retailerId: RetailerRegistry.canonicalId(dealerName),
      title: json.stringAt('label') ?? dealerName,
      contentLevel: offerCount > 0
          ? BrochureContentLevel.productsWithPrices
          : BrochureContentLevel.imagesOnly,
      coverage: switch (allStores) {
        true => BrochureCoverage.national,
        false => BrochureCoverage.storeBound,
        null => BrochureCoverage.unknown,
      },
      regionCodes: [
        // Manche Kataloge nennen die Filiale direkt, die meisten nicht. Die
        // vollstaendige Zuordnung liefert /v2/catalogs/{id}/stores.
        if (json.stringAt('store_id') case final storeId?) storeId,
      ],
      validFrom: json.dateAt('run_from'),
      validUntil: json.dateAt('run_till'),
      publishedAt: json.dateAt('publish'),
      pageCount: json.intAt('page_count') ?? 0,
      cover: _imageSet(json.mapAt('images')),
      pdfUrl: json.uriAt('pdf_url'),
    );
  }

  /// Seiten aus `/pages`. Die API liefert ein reines Array ohne Seitennummern,
  /// die Position im Array ist die Seitennummer.
  List<BrochurePage> pages(
    List<Map<String, Object?>> json,
    Map<int, List<Hotspot>> hotspotsByPage,
  ) =>
      [
        for (var i = 0; i < json.length; i++)
          BrochurePage(
            number: i + 1,
            images: _imageSet(json[i]),
            hotspots: hotspotsByPage[i + 1] ?? const [],
          ),
      ];

  /// Hotspots nach Seitenzahl gruppiert.
  ///
  /// Tjek liefert je Hotspot eine Map `locations` von Seitennummer auf ein
  /// Polygon aus [x, y]-Paaren im Bereich 0 bis 1. Das neutrale Modell nutzt
  /// ein Rechteck in Prozent, deshalb wird die Bounding Box des Polygons
  /// gebildet und mit 100 skaliert.
  Map<int, List<Hotspot>> hotspotsByPage(List<Map<String, Object?>> json) {
    final result = <int, List<Hotspot>>{};
    for (final entry in json) {
      final locations = entry.mapAt('locations');
      if (locations == null) continue;
      final offerId = entry.mapAt('offer')?.stringAt('id') ?? entry.stringAt('id');
      final heading = entry.stringAt('heading');

      for (final location in locations.entries) {
        final page = int.tryParse(location.key);
        final polygon = location.value;
        if (page == null || polygon is! List) continue;

        final box = _boundingBox(polygon);
        if (box == null) continue;

        result.putIfAbsent(page, () => []).add(
              Hotspot(
                left: box.$1 * 100,
                top: box.$2 * 100,
                width: box.$3 * 100,
                height: box.$4 * 100,
                offerId: offerId,
                label: heading,
              ),
            );
      }
    }
    return result;
  }

  Offer? offer(Map<String, Object?> json, ParseReport report) {
    final id = json.stringAt('id');
    final heading = json.stringAt('heading');
    if (id == null || heading == null) {
      report.skip('Angebot ohne id oder heading');
      return null;
    }

    return Offer(
      id: id,
      title: heading,
      description: json.stringAt('description'),
      price: _price(json.mapAt('pricing')),
      quantity: _quantity(json.mapAt('quantity')),
      image: _imageSet(json.mapAt('images')),
      pageNumber: json.intAt('catalog_page'),
      link: json.mapAt('links')?.uriAt('webshop'),
    );
  }

  Store? store(Map<String, Object?> json, String retailerId, ParseReport report) {
    final id = json.stringAt('id');
    if (id == null) {
      report.skip('Filiale ohne id');
      return null;
    }
    final lat = json.doubleAt('latitude');
    final lng = json.doubleAt('longitude');
    return Store(
      id: id,
      retailerId: retailerId,
      name: json.stringAt('name'),
      street: json.stringAt('street'),
      zipCode: json.stringAt('zip_code'),
      city: json.stringAt('city'),
      countryCode: json.mapAt('country')?.stringAt('id') ?? 'DE',
      location: lat != null && lng != null ? GeoPoint(lat, lng) : null,
    );
  }

  Price? _price(Map<String, Object?>? json) {
    if (json == null) return null;
    final current = json.doubleAt('price');
    if (current == null) return null;
    return Price(
      current: current,
      currency: json.stringAt('currency') ?? 'EUR',
      previous: json.doubleAt('pre_price'),
    );
  }

  Quantity? _quantity(Map<String, Object?>? json) {
    if (json == null) return null;
    final unit = json.mapAt('unit');
    final si = unit?.mapAt('si');
    final size = json.mapAt('size');
    final pieces = json.mapAt('pieces');
    final quantity = Quantity(
      unitSymbol: unit?.stringAt('symbol'),
      sizeFrom: size?.doubleAt('from'),
      sizeTo: size?.doubleAt('to'),
      siSymbol: si?.stringAt('symbol'),
      siFactor: si?.doubleAt('factor'),
      piecesFrom: pieces?.intAt('from'),
      piecesTo: pieces?.intAt('to'),
    );
    return quantity.isEmpty ? null : quantity;
  }

  /// Tjek nennt die drei Stufen `thumb`, `view` und `zoom`.
  ImageSet _imageSet(Map<String, Object?>? json) {
    if (json == null) return ImageSet.empty;
    return ImageSet(
      thumbnail: json.uriAt('thumb'),
      normal: json.uriAt('view'),
      large: json.uriAt('zoom'),
    );
  }

  /// Bounding Box eines Polygons als (left, top, width, height) in 0 bis 1.
  (double, double, double, double)? _boundingBox(List<Object?> polygon) {
    double? minX, minY, maxX, maxY;
    for (final point in polygon) {
      if (point is! List || point.length < 2) continue;
      final x = point[0];
      final y = point[1];
      if (x is! num || y is! num) continue;
      minX = minX == null ? x.toDouble() : (x < minX ? x.toDouble() : minX);
      maxX = maxX == null ? x.toDouble() : (x > maxX ? x.toDouble() : maxX);
      minY = minY == null ? y.toDouble() : (y < minY ? y.toDouble() : minY);
      maxY = maxY == null ? y.toDouble() : (y > maxY ? y.toDouble() : maxY);
    }
    if (minX == null || minY == null || maxX == null || maxY == null) return null;
    return (minX, minY, maxX - minX, maxY - minY);
  }
}
