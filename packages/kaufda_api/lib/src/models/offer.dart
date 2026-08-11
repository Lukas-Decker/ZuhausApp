import 'package:meta/meta.dart';

import 'common.dart';
import 'json.dart';

/// Ein Angebot auf einer Prospektseite.
@immutable
class Offer {
  const Offer({
    required this.id,
    required this.type,
    this.publisher,
    this.image,
    this.parentContent,
    this.products = const [],
    this.deals = const [],
    this.linkOuts = const [],
    this.discountLabels = const [],
    this.publicationProfiles = const [],
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: asString(json['id']) ?? '',
        type: asString(json['type']) ?? 'offer',
        publisher: switch (asMap(json['publisher'])) {
          final Map<String, dynamic> m => Publisher.fromJson(m),
          null => null,
        },
        image: asString(json['image']),
        parentContent: switch (asMap(json['parentContent'])) {
          final Map<String, dynamic> m => OfferParent.fromJson(m),
          null => null,
        },
        products: mapList(json['products'], Product.fromJson),
        deals: mapList(json['deals'], Deal.fromJson),
        linkOuts: mapList(json['linkOuts'], OfferLinkOut.fromJson),
        discountLabels: mapList(json['discountLabel'], DiscountLabel.fromJson),
        publicationProfiles:
            mapList(json['publicationProfiles'], PublicationProfile.fromJson),
      );

  final String id;

  /// Bisher beobachtet: `offer`.
  final String type;
  final Publisher? publisher;

  /// Freigestelltes Angebotsbild.
  final String? image;

  /// Verweis auf Prospekt, Seite und Position des Angebots.
  final OfferParent? parentContent;
  final List<Product> products;
  final List<Deal> deals;
  final List<OfferLinkOut> linkOuts;
  final List<DiscountLabel> discountLabels;
  final List<PublicationProfile> publicationProfiles;

  /// Erstes Produkt, falls vorhanden.
  Product? get product => products.isEmpty ? null : products.first;

  /// Anzeigename: Marke plus Produktname, sonst leerer String.
  String get displayName {
    final p = product;
    if (p == null) return '';
    final brand = p.brandName;
    return brand == null || brand.isEmpty ? p.name : '$brand ${p.name}';
  }

  /// Der guenstigste Preis ueber alle Deals hinweg.
  Deal? get bestDeal {
    Deal? best;
    for (final deal in deals) {
      final price = deal.min;
      if (price == null) continue;
      if (best == null || price < (best.min ?? double.infinity)) best = deal;
    }
    return best;
  }

  /// Der regulaere Verkaufspreis, falls die API einen liefert.
  Deal? get salesPrice => _dealOfType('SALES_PRICE');

  /// Der Aktionspreis (z. B. mit Kundenkarte), falls vorhanden.
  Deal? get specialPrice => _dealOfType('SPECIAL_PRICE');

  Deal? _dealOfType(String type) {
    for (final deal in deals) {
      if (deal.type == type) return deal;
    }
    return null;
  }

  /// Gueltigkeitsbeginn aus dem ersten Publikationsprofil.
  DateTime? get validFrom =>
      publicationProfiles.isEmpty ? null : publicationProfiles.first.startDate;

  /// Gueltigkeitsende aus dem ersten Publikationsprofil.
  DateTime? get validUntil =>
      publicationProfiles.isEmpty ? null : publicationProfiles.first.endDate;

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'type': type,
        'publisher': publisher?.toJson(),
        'image': image,
        'parentContent': parentContent?.toJson(),
        'products': products.map((e) => e.toJson()).toList(),
        'deals': deals.map((e) => e.toJson()).toList(),
        'linkOuts': linkOuts.map((e) => e.toJson()).toList(),
        'discountLabel': discountLabels.map((e) => e.toJson()).toList(),
        'publicationProfiles':
            publicationProfiles.map((e) => e.toJson()).toList(),
      });

  @override
  String toString() => 'Offer($id, $displayName)';
}

/// Verweis vom Angebot zurueck auf Prospekt, Seite und Trefferflaeche.
@immutable
class OfferParent {
  const OfferParent({
    required this.id,
    this.legacyId,
    this.type,
    this.pageNumber,
    this.area,
  });

  factory OfferParent.fromJson(Map<String, dynamic> json) {
    final page = asMap(json['page']);
    return OfferParent(
      id: asString(json['id']) ?? '',
      legacyId: asInt(json['legacyId']),
      type: asString(json['type']),
      pageNumber: asInt(page?['number']),
      area: switch (asMap(page?['area'])) {
        final Map<String, dynamic> m => NormalizedArea.fromJson(m),
        null => null,
      },
    );
  }

  final String id;
  final int? legacyId;
  final String? type;

  /// Nullbasierte Seitennummer, so wie die API sie liefert.
  final int? pageNumber;

  /// Klickflaeche auf der Seite, normalisiert auf 0..1.
  final NormalizedArea? area;

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'legacyId': legacyId,
        'type': type,
        'page': pageNumber == null && area == null
            ? null
            : compact({'number': pageNumber, 'area': area?.toJson()}),
      });

  @override
  String toString() => 'OfferParent($id, page: $pageNumber)';
}

/// Beworbenes Produkt inklusive Kategoriepfad.
@immutable
class Product {
  const Product({
    required this.name,
    this.brandName,
    this.descriptionParagraphs = const [],
    this.images = const [],
    this.categoryPaths = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        name: asString(json['name']) ?? '',
        brandName: asString(json['brandName']),
        descriptionParagraphs: mapList(
          json['description'],
          (m) => asString(m['paragraph']) ?? '',
        ).where((e) => e.isNotEmpty).toList(growable: false),
        images: mapList(json['images'], ProductImage.fromJson),
        categoryPaths: mapList(json['categoryPaths'], CategoryPath.fromJson),
      );

  final String name;
  final String? brandName;
  final List<String> descriptionParagraphs;
  final List<ProductImage> images;

  /// Kategoriepfad von grob nach fein, z. B. Lebensmittel > Obst > Weintrauben.
  final List<CategoryPath> categoryPaths;

  String get description => descriptionParagraphs.join('\n');

  Map<String, dynamic> toJson() => compact({
        'name': name,
        'brandName': brandName,
        'description':
            descriptionParagraphs.map((e) => {'paragraph': e}).toList(),
        'images': images.map((e) => e.toJson()).toList(),
        'categoryPaths': categoryPaths.map((e) => e.toJson()).toList(),
      });

  @override
  String toString() => 'Product(${brandName ?? ''} $name)';
}

/// Produktbild mit Abmessungen.
@immutable
class ProductImage {
  const ProductImage({required this.url, this.dimensions});

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        url: asString(json['url']) ?? '',
        dimensions: switch (asMap(json['dimensions'])) {
          final Map<String, dynamic> m => Dimensions.fromJson(m),
          null => null,
        },
      );

  final String url;
  final Dimensions? dimensions;

  Map<String, dynamic> toJson() =>
      compact({'url': url, 'dimensions': dimensions?.toJson()});

  @override
  String toString() => 'ProductImage($url)';
}

/// Ein Knoten im Kategoriebaum.
@immutable
class CategoryPath {
  const CategoryPath({required this.id, required this.name});

  factory CategoryPath.fromJson(Map<String, dynamic> json) => CategoryPath(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;
}

/// Preisangabe zu einem Angebot.
@immutable
class Deal {
  const Deal({
    required this.type,
    this.min,
    this.max,
    this.currencyCode,
    this.frequency,
    this.priceByBaseUnit,
    this.description,
    this.conditions = const [],
  });

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        type: asString(json['type']) ?? '',
        min: asDouble(json['min']),
        max: asDouble(json['max']),
        currencyCode: asString(json['currencyCode']),
        frequency: asString(json['frequency']),
        priceByBaseUnit: asString(json['priceByBaseUnit']),
        description: asString(json['description']),
        conditions: mapList(json['conditions'], DealCondition.fromJson),
      );

  /// Beobachtete Werte: `SALES_PRICE`, `SPECIAL_PRICE`, `REGULAR_PRICE`,
  /// `RECOMMENDED_RETAIL_PRICE`, `OTHER`.
  final String type;
  final double? min;
  final double? max;
  final String? currencyCode;

  /// Bisher nur `ONCE` beobachtet.
  final String? frequency;

  /// Grundpreis als Freitext, z. B. `1 kg = 2.50`.
  final String? priceByBaseUnit;
  final String? description;
  final List<DealCondition> conditions;

  /// Preis, wenn min und max identisch sind.
  double? get price => min == max ? min : null;

  bool get isPriceRange => min != null && max != null && min != max;

  Map<String, dynamic> toJson() => compact({
        'type': type,
        'min': min,
        'max': max,
        'currencyCode': currencyCode,
        'frequency': frequency,
        'priceByBaseUnit': priceByBaseUnit,
        'description': description,
        'conditions': conditions.map((e) => e.toJson()).toList(),
      });

  @override
  String toString() => isPriceRange
      ? 'Deal($type, $min-$max $currencyCode)'
      : 'Deal($type, $min $currencyCode)';
}

/// Bedingung fuer einen Preis, z. B. Kundenkarte oder Mindestmenge.
@immutable
class DealCondition {
  const DealCondition({this.other, this.loyaltyProgram});

  factory DealCondition.fromJson(Map<String, dynamic> json) => DealCondition(
        other: asString(json['other']),
        loyaltyProgram: asString(json['loyaltyProgram']),
      );

  /// Freitext, z. B. `Mit Lidl Plus`.
  final String? other;

  /// Name des Treueprogramms.
  final String? loyaltyProgram;

  String get label => loyaltyProgram ?? other ?? '';

  Map<String, dynamic> toJson() =>
      compact({'other': other, 'loyaltyProgram': loyaltyProgram});

  @override
  String toString() => label;
}

/// Rabatt-Auszeichnung, z. B. `DISCOUNT_AMOUNT` mit Wert `15.00`.
@immutable
class DiscountLabel {
  const DiscountLabel({required this.value, required this.type});

  factory DiscountLabel.fromJson(Map<String, dynamic> json) => DiscountLabel(
        value: asString(json['value']) ?? '',
        type: asString(json['type']) ?? '',
      );

  final String value;
  final String type;

  Map<String, dynamic> toJson() => {'value': value, 'type': type};

  @override
  String toString() => '$type: $value';
}

/// Gueltigkeitszeitraum eines Angebots.
@immutable
class PublicationProfile {
  const PublicationProfile({this.startDate, this.endDate});

  factory PublicationProfile.fromJson(Map<String, dynamic> json) {
    final validity = asMap(json['validity']);
    return PublicationProfile(
      startDate: asDateTime(validity?['startDate']),
      endDate: asDateTime(validity?['endDate']),
    );
  }

  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, dynamic> toJson() => {
        'validity': compact({
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        }),
      };

  @override
  String toString() => 'PublicationProfile($startDate - $endDate)';
}

/// Deeplink aus einem Angebot in den Shop des Haendlers.
@immutable
class OfferLinkOut {
  const OfferLinkOut({this.label, this.intent, this.webUrl, this.mobileUrl});

  factory OfferLinkOut.fromJson(Map<String, dynamic> json) => OfferLinkOut(
        label: asString(json['label']),
        intent: asString(json['intent']),
        webUrl: asString(json['webUrl']),
        mobileUrl: asString(json['mobileUrl']),
      );

  final String? label;

  /// Bisher nur `OTHER` beobachtet.
  final String? intent;
  final String? webUrl;
  final String? mobileUrl;

  /// Bevorzugt die mobile URL, faellt auf die Web-URL zurueck.
  String? get url => mobileUrl ?? webUrl;

  Map<String, dynamic> toJson() => compact({
        'label': label,
        'intent': intent,
        'webUrl': webUrl,
        'mobileUrl': mobileUrl,
      });

  @override
  String toString() => 'OfferLinkOut($label)';
}
