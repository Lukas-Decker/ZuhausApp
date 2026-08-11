import 'package:kaufda_api/kaufda_api.dart' as kd;

import '../../core/models/brochure.dart';
import '../../core/models/brochure_page.dart';
import '../../core/models/geo.dart';
import '../../core/models/image_set.dart';
import '../../core/models/offer.dart';
import '../../core/models/price.dart';
import '../../core/models/retailer.dart';
import '../../core/models/store.dart';
import '../../core/source/retailer_registry.dart';

/// Uebersetzt kaufDA-Modelle in das neutrale Datenmodell.
///
/// Einzige Stelle, an der kaufDA-spezifische Feldnamen und Konventionen
/// vorkommen. Zwei davon sind stolperanfaellig und werden hier zentral
/// geradegezogen: kaufDA zaehlt Seiten nullbasiert (das neutrale Modell ab 1)
/// und liefert Trefferflaechen normalisiert auf 0..1 (das neutrale Modell
/// erwartet Prozent 0..100).
class KaufdaMapper {
  const KaufdaMapper();

  static const String sourceId = 'kaufda';

  /// Menschenlesbare Prospektseite auf kaufda.de, fuer "im Browser oeffnen".
  static Uri webUrlFor(String brochureId) =>
      Uri.https('www.kaufda.de', '/contentViewer/$brochureId');

  Retailer? retailer(kd.Publisher publisher) {
    if (publisher.id.isEmpty || publisher.name.isEmpty) return null;
    final canonical = RetailerRegistry.canonicalId(publisher.name);
    return Retailer(
      id: canonical,
      name: RetailerRegistry.displayName(canonical, publisher.name),
      logo: _imageSetFromRefs(publisher.images),
      bindings: [
        SourceBinding(
          sourceId: sourceId,
          nativeId: publisher.id,
          // Der Suchendpunkt arbeitet mit Namen, nicht mit IDs. Der Rohname
          // wird deshalb am Binding mitgefuehrt.
          params: {'name': publisher.name},
        ),
      ],
    );
  }

  Brochure? brochureFromShelf(kd.ShelfBrochure raw) {
    if (raw.id.isEmpty) return null;
    return Brochure(
      id: BrochureId(sourceId, raw.id),
      retailerId: RetailerRegistry.canonicalId(raw.publisher.name),
      title: raw.title.isEmpty ? raw.publisher.name : raw.title,
      // Die Uebersicht enthaelt keine Angebote, erst der Detailabruf zeigt,
      // wie tief die Daten gehen.
      contentLevel: BrochureContentLevel.unknown,
      validFrom: raw.validFrom,
      validUntil: raw.validUntil,
      publishedAt: raw.publishedFrom,
      pageCount: raw.pageCount,
      cover: _cover(raw.image, raw.images),
      // Das Regal ist immer auf einen Standort gefiltert, die Prospekte sind
      // also ortsbezogen und ohne Ortsangabe nicht sinnvoll anzeigbar.
      coverage: BrochureCoverage.regional,
      webUrl: webUrlFor(raw.id),
      closestStore: _store(raw),
    );
  }

  Store? _store(kd.ShelfBrochure raw) {
    final store = raw.closestStore;
    if (store == null) return null;
    return Store(
      id: '${store.id}',
      retailerId: RetailerRegistry.canonicalId(raw.publisher.name),
      name: store.name.isEmpty ? null : store.name,
      street: [
        if (store.street != null && store.street!.isNotEmpty) store.street!,
        if (store.streetNumber != null && store.streetNumber!.isNotEmpty)
          store.streetNumber!,
      ].join(' '),
      zipCode: store.zip,
      city: store.city,
      location: store.lat != null && store.lng != null
          ? GeoPoint(store.lat!, store.lng!)
          : null,
    );
  }

  Brochure brochureDetail(kd.Brochure meta, List<kd.BrochurePage> rawPages) {
    final pages = <BrochurePage>[];
    final offers = <Offer>[];
    for (final page in rawPages) {
      pages.add(_page(page));
      for (final entry in page.offers) {
        final mapped = offer(entry.content);
        if (mapped != null) offers.add(mapped);
      }
    }

    return Brochure(
      id: BrochureId(sourceId, meta.id),
      retailerId: RetailerRegistry.canonicalId(meta.publisher.name),
      title: meta.title.isEmpty ? meta.publisher.name : meta.title,
      contentLevel: offers.isEmpty
          ? BrochureContentLevel.imagesOnly
          : offers.any((o) => o.hasPrice)
              ? BrochureContentLevel.productsWithPrices
              : BrochureContentLevel.productsWithoutPrices,
      validFrom: meta.validFrom,
      validUntil: meta.validUntil,
      pageCount: meta.pageCount == 0 ? pages.length : meta.pageCount,
      cover: _cover(meta.image, const []),
      coverage: BrochureCoverage.regional,
      pages: pages,
      offers: offers,
      webUrl: webUrlFor(meta.id),
    );
  }

  BrochurePage _page(kd.BrochurePage raw) {
    final largest = raw.largestImage;
    final hotspots = <Hotspot>[];
    for (final entry in raw.offers) {
      final area = entry.content.parentContent?.area;
      if (area == null) continue;
      hotspots.add(
        Hotspot(
          // kaufDA normalisiert auf 0..1, das neutrale Modell auf 0..100.
          left: area.topLeft.x * 100,
          top: area.topLeft.y * 100,
          width: area.width * 100,
          height: area.height * 100,
          offerId: entry.content.id,
        ),
      );
    }
    return BrochurePage(
      number: raw.number + 1,
      images: ImageSet(
        thumbnail: _uri(raw.imageBySize('75x96')?.url),
        normal: _uri(raw.imageBySize('768x1024')?.url ?? largest?.url),
        large: _uri(largest?.url),
      ),
      dimensions: largest?.width != null && largest?.height != null
          ? PageDimensions(
              largest!.width!.toDouble(),
              largest.height!.toDouble(),
            )
          : null,
      hotspots: hotspots,
    );
  }

  Offer? offer(kd.Offer raw) {
    if (raw.id.isEmpty) return null;
    final product = raw.product;
    final title = raw.displayName.isEmpty
        ? (product?.name ?? '')
        : raw.displayName;
    if (title.isEmpty) return null;

    final pageNumber = raw.parentContent?.pageNumber;
    return Offer(
      id: raw.id,
      title: title,
      description: product == null || product.description.isEmpty
          ? null
          : product.description,
      brand: product?.brandName,
      price: _price(raw),
      image: ImageSet(normal: _uri(raw.image)),
      pageNumber: pageNumber == null ? null : pageNumber + 1,
      categories: [
        for (final path in product?.categoryPaths ?? const <kd.CategoryPath>[])
          if (path.name.isNotEmpty) path.name,
      ],
      link: _uri(raw.linkOuts.isEmpty ? null : raw.linkOuts.first.url),
      validFrom: raw.validFrom,
      validUntil: raw.validUntil,
      retailerName: raw.publisher?.name,
      brochureRef: raw.parentContent == null
          ? null
          : BrochureId(sourceId, raw.parentContent!.id).toString(),
    );
  }

  /// Aktionspreis vor Verkaufspreis vor guenstigstem Deal. Der Streichpreis
  /// kommt aus dem regulaeren Preis bzw. der UVP, aber nur wenn er wirklich
  /// hoeher liegt.
  Price? _price(kd.Offer raw) {
    final deal = raw.specialPrice ?? raw.salesPrice ?? raw.bestDeal;
    final current = deal?.price ?? deal?.min;
    if (deal == null || current == null) return null;

    double? previous;
    for (final type in const ['REGULAR_PRICE', 'RECOMMENDED_RETAIL_PRICE']) {
      for (final other in raw.deals) {
        if (other.type != type) continue;
        final value = other.price ?? other.min;
        if (value != null && value > current) previous = value;
      }
      if (previous != null) break;
    }

    return Price(
      current: current,
      currency: deal.currencyCode ?? 'EUR',
      previous: previous,
      basePriceText: deal.priceByBaseUnit,
    );
  }

  /// [validFrom]/[validUntil] kommen vom zugehoerigen Prospekt-Treffer:
  /// der Suchendpunkt liefert die Gueltigkeit nicht am Angebot selbst.
  Offer? searchOffer(
    kd.SearchOffer raw, {
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    if (raw.id.isEmpty || raw.title.isEmpty) return null;
    final main = raw.price?.mainPrice;
    final previous = raw.price?.secondaryPrice;
    final pageNumber = raw.parent?.pageNumber;
    return Offer(
      id: raw.id,
      title: raw.title,
      brand: raw.brand,
      description: raw.price?.description,
      price: main == null
          ? null
          : Price(
              current: main,
              currency: 'EUR',
              // kaufDA meldet 0, wenn es keinen Streichpreis gibt.
              previous: previous != null && previous > main ? previous : null,
              basePriceText: raw.price?.priceByBaseUnit,
              formatted: raw.price?.mainPriceFormatted,
            ),
      image: ImageSet(
        thumbnail: _uri(raw.imageThumbnail),
        normal: _uri(raw.imageNormal),
        large: _uri(raw.imageLarge),
      ),
      pageNumber: pageNumber == null ? null : pageNumber + 1,
      categories: [
        for (final ref in raw.categoryPaths.isEmpty
            ? const <kd.CategoryRef>[]
            : raw.categoryPaths.first)
          if (ref.name.isNotEmpty) ref.name,
      ],
      retailerName: raw.publisherName,
      brochureRef: raw.parent == null
          ? null
          : BrochureId(sourceId, raw.parent!.id).toString(),
      validFrom: validFrom,
      validUntil: validUntil,
    );
  }

  /// Titelbild: das Einzelbild der Kachel plus die Groessenstaffel, sofern
  /// beides vorhanden ist.
  ImageSet _cover(String? single, List<kd.ImageRef> refs) {
    final fromRefs = _imageSetFromRefs(refs);
    if (!fromRefs.isEmpty) return fromRefs;
    final uri = _uri(single);
    return uri == null ? ImageSet.empty : ImageSet(normal: uri);
  }

  /// Sortiert eine kaufDA-Groessenstaffel in klein/mittel/gross ein.
  ImageSet _imageSetFromRefs(List<kd.ImageRef> refs) {
    final sized = refs.where((r) => r.url.isNotEmpty).toList()
      ..sort((a, b) =>
          ((a.width ?? 0) * (a.height ?? 0)).compareTo(
            (b.width ?? 0) * (b.height ?? 0),
          ));
    if (sized.isEmpty) return ImageSet.empty;
    return ImageSet(
      thumbnail: _uri(sized.first.url),
      normal: _uri(sized[sized.length ~/ 2].url),
      large: _uri(sized.last.url),
    );
  }

  Uri? _uri(String? value) =>
      value == null || value.isEmpty ? null : Uri.tryParse(value);
}
