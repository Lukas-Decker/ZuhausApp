import '../../core/http/json_reader.dart';
import '../../core/models/brochure.dart';
import '../../core/models/brochure_page.dart';
import '../../core/models/image_set.dart';
import '../../core/models/offer.dart';
import '../../core/models/price.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/retailer_registry.dart';
import '../tjek/tjek_mapper.dart' show ParseReport;
import 'marktguru_api.dart';

/// Uebersetzt Marktguru-JSON in das neutrale Modell.
class MarktguruMapper {
  const MarktguruMapper(this._api);

  final MarktguruApi _api;

  /// Haendler-IDs kommen als `retailers/126802`. Fuer Abrufe und Bild-URLs
  /// wird nur die Zahl gebraucht.
  static String? retailerNumber(String? id) {
    if (id == null) return null;
    final index = id.lastIndexOf('/');
    return index < 0 ? id : id.substring(index + 1);
  }

  Retailer? retailer(Map<String, Object?> json, ParseReport report) {
    final rawId = json.stringAt('id');
    final name = json.stringAt('name');
    final number = retailerNumber(rawId);
    if (number == null || name == null) {
      report.skip('Haendler ohne id oder name');
      return null;
    }

    final canonical = RetailerRegistry.canonicalId(name);
    return Retailer(
      id: canonical,
      name: RetailerRegistry.displayName(canonical, name),
      logo: ImageSet(
        thumbnail: _api.retailerLogo(number, size: 'small'),
        normal: _api.retailerLogo(number),
        large: _api.retailerLogo(number, size: 'large'),
      ),
      bindings: [
        SourceBinding(sourceId: MarktguruApi.sourceId, nativeId: number),
      ],
    );
  }

  /// Ein Prospekt, bei Marktguru "leaflet flight" genannt.
  ///
  /// Die Bilder haengen nicht am Flight, sondern an `mainLeafletId`. Ohne
  /// diese Unterscheidung bleiben die Seiten leer.
  Brochure? brochure(Map<String, Object?> json, ParseReport report) {
    final id = json.intAt('id');
    if (id == null) {
      report.skip('Prospekt ohne id');
      return null;
    }

    final advertiser = json.mapAt('advertiser');
    final retailerName = advertiser?.stringAt('name') ?? 'unknown';
    final leafletId = json.intAt('mainLeafletId');
    final pageCount = json.intAt('pageCount') ?? 0;

    return Brochure(
      id: BrochureId(MarktguruApi.sourceId, '$id'),
      retailerId: RetailerRegistry.canonicalId(retailerName),
      title: json.stringAt('title') ?? retailerName,
      subtitle: json.stringAt('highlightText'),
      // Marktguru liefert die Angebote getrennt vom Prospekt. Ob welche
      // vorliegen, sagt offerCount.
      contentLevel: (json.intAt('offerCount') ?? 0) > 0
          ? BrochureContentLevel.productsWithPrices
          : BrochureContentLevel.imagesOnly,
      // Die Suche ist bereits auf eine Postleitzahl eingeschraenkt, die
      // Treffer gelten also fuer diesen Ort. Ob ein Prospekt daneben noch
      // bundesweit gilt, sagt die Quelle nicht.
      coverage: BrochureCoverage.regional,
      validFrom: json.dateAt('validFrom'),
      validUntil: json.dateAt('validTo'),
      pageCount: pageCount,
      cover: leafletId == null
          ? ImageSet.empty
          : _pageImages(leafletId, json.intAt('mainLeafletPageIndex') ?? 0),
      pages: leafletId == null
          ? const []
          : [
              for (var i = 0; i < pageCount; i++)
                BrochurePage(number: i + 1, images: _pageImages(leafletId, i)),
            ],
    );
  }

  Offer? offer(Map<String, Object?> json, ParseReport report) {
    final id = json.intAt('id');
    if (id == null) {
      report.skip('Angebot ohne id');
      return null;
    }

    // Der Produktname steht in product.name, description ist der Zusatztext.
    final title = json.mapAt('product')?.stringAt('name') ??
        json.stringAt('description');
    if (title == null) {
      report.skip('Angebot ohne Produktnamen');
      return null;
    }

    final validity = json.objectsAt('validityDates');
    final hasImage = (json.mapAt('images')?.intAt('count') ?? 0) > 0;

    return Offer(
      id: '$id',
      title: title,
      description: json.stringAt('description'),
      brand: json.mapAt('brand')?.stringAt('name'),
      price: _price(json),
      quantity: _quantity(json),
      image: hasImage
          ? ImageSet(
              thumbnail: _api.offerImage('$id', size: 'small'),
              normal: _api.offerImage('$id'),
              large: _api.offerImage('$id', size: 'large'),
            )
          : ImageSet.empty,
      categories: json
          .objectsAt('categories')
          .map((c) => c.stringAt('name'))
          .nonNulls
          .toList(),
      link: json.uriAt('externalUrl'),
      externalProductId: json.stringAt('externalId') ??
          json.mapAt('product')?.intAt('id')?.toString(),
      validFrom: validity.isEmpty ? null : validity.first.dateAt('from'),
      validUntil: validity.isEmpty ? null : validity.first.dateAt('to'),
    );
  }

  Store? store(Map<String, Object?> json, String retailerId, ParseReport report) {
    final id = json.intAt('id') ?? json.intAt('storeId');
    if (id == null) {
      report.skip('Filiale ohne id');
      return null;
    }
    return Store(
      id: '$id',
      retailerId: retailerId,
      name: json.stringAt('name'),
      street: json.stringAt('street') ?? json.stringAt('address'),
      zipCode: json.stringAt('zipCode') ?? json.stringAt('zip'),
      city: json.stringAt('city'),
    );
  }

  /// `referencePrice` ist der Grundpreis je Einheit, `unit.shortName` die
  /// Einheit dazu. Beides wird zu einem lesbaren Text zusammengesetzt, weil
  /// das neutrale Modell den Grundpreis als Text fuehrt.
  Price? _price(Map<String, Object?> json) {
    final current = json.doubleAt('price');
    if (current == null) return null;

    final reference = json.doubleAt('referencePrice');
    final unit = json.mapAt('unit')?.stringAt('shortName');

    return Price(
      current: current,
      currency: 'EUR',
      previous: json.doubleAt('oldPrice'),
      basePriceText: reference != null && unit != null
          ? '1 $unit = ${reference.toStringAsFixed(2)}'
          : null,
    );
  }

  /// `volume` ist die Menge in der Basiseinheit, `unit.shortName` die Einheit.
  /// Ein Angebot mit `volume: 0.06` und `shortName: kg` sind 60 Gramm.
  Quantity? _quantity(Map<String, Object?> json) {
    final volume = json.doubleAt('volume');
    final unit = json.mapAt('unit')?.stringAt('shortName');
    final pieces = json.intAt('quantity');
    if (volume == null && unit == null && pieces == null) return null;

    return Quantity(
      unitSymbol: unit,
      sizeFrom: volume,
      sizeTo: volume,
      siSymbol: unit,
      siFactor: volume == null ? null : 1.0,
      piecesFrom: pieces,
      piecesTo: pieces,
    );
  }

  ImageSet _pageImages(int leafletId, int pageIndex) => ImageSet(
        thumbnail: _api.leafletPageImage('$leafletId', pageIndex, size: 'small'),
        normal: _api.leafletPageImage('$leafletId', pageIndex, size: 'medium'),
        large: _api.leafletPageImage('$leafletId', pageIndex),
      );
}
