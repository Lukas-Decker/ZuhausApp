import 'package:meta/meta.dart';

import 'common.dart';
import 'json.dart';

/// Sortierung der Suche (`sort`).
abstract final class SearchSort {
  /// Standard.
  static const relevance = 'relevance';

  /// Guenstigste Angebote zuerst.
  static const price = 'price';

  /// Zuerst ablaufende Prospekte zuerst.
  static const validityEnd = 'validityEnd';
}

/// Ergebnis von `GET https://www.kaufda.de/api/search`.
@immutable
class SearchResult {
  const SearchResult({
    this.brochures = const [],
    this.offers = const [],
    this.metadata = const SearchMetadata(),
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final results = asMap(json['searchResults']) ?? json;
    final contents = asMap(results['contents']) ?? const {};
    return SearchResult(
      brochures: mapList(
        contents['brochures'],
        (m) => AdContent.fromJson(m, SearchBrochure.fromJson),
      ),
      offers: mapList(contents['offers'], SearchOffer.fromJson),
      metadata: SearchMetadata.fromJson(asMap(results['metadata']) ?? const {}),
    );
  }

  final List<AdContent<SearchBrochure>> brochures;
  final List<SearchOffer> offers;
  final SearchMetadata metadata;

  /// Die Prospekte ohne Ad-Umschlag.
  List<SearchBrochure> get brochureContents =>
      brochures.map((e) => e.content).toList(growable: false);

  bool get isEmpty => brochures.isEmpty && offers.isEmpty;

  Map<String, dynamic> toJson() => {
        'searchResults': {
          'contents': {
            'brochures':
                brochures.map((e) => e.toJson((c) => c.toJson())).toList(),
            'offers': offers.map((e) => e.toJson()).toList(),
          },
          'metadata': metadata.toJson(),
        },
      };

  @override
  String toString() => 'SearchResult(${brochures.length} Prospekte, '
      '${offers.length} Angebote, ${metadata.searchType})';
}

/// Trefferzahlen, erkannte Entitaeten und Facetten einer Suche.
@immutable
class SearchMetadata {
  const SearchMetadata({
    this.brochureCount = 0,
    this.offerCount = 0,
    this.searchType,
    this.recognizedEntities = const [],
    this.publisherFacets = const [],
    this.sorts = const [],
    this.searchSuggestions = const [],
    this.minPrice,
    this.maxPrice,
  });

  factory SearchMetadata.fromJson(Map<String, dynamic> json) {
    final counts = asMap(json['contentCount']) ?? const {};
    final facets = <SearchFacet>[];
    double? minPrice;
    double? maxPrice;
    for (final filter in mapList(json['filters'], (m) => m)) {
      final name = asString(filter['name']);
      final value = asMap(filter['value']);
      if (name == 'publisher') {
        facets.addAll(mapList(value?['values'], SearchFacet.fromJson));
      } else if (name == 'price') {
        minPrice = asDouble(value?['min']);
        maxPrice = asDouble(value?['max']);
      }
    }
    return SearchMetadata(
      brochureCount: asInt(counts['brochure']) ?? 0,
      offerCount: asInt(counts['offer']) ?? 0,
      searchType: asString(json['searchType']),
      recognizedEntities:
          mapList(json['recognizedEntities'], RecognizedEntity.fromJson),
      publisherFacets: facets,
      sorts: mapList(json['sorts'], (m) => asString(m['name']) ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      searchSuggestions: stringList(json['searchSuggestions']),
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  /// Gesamtzahl passender Prospekte, unabhaengig von `limit`.
  final int brochureCount;

  /// Gesamtzahl passender Angebote, unabhaengig von `limit`.
  final int offerCount;

  /// `retailer`, wenn der Suchbegriff als Haendler erkannt wurde,
  /// `product` bei einer Produktsuche.
  final String? searchType;

  /// Was die Suche im Begriff erkannt hat, z. B. den Haendler `Lidl`.
  final List<RecognizedEntity> recognizedEntities;

  /// Haendler, die im Ergebnis vorkommen. Der Endpunkt filtert nicht selbst
  /// danach, das muss der Aufrufer tun.
  final List<SearchFacet> publisherFacets;
  final List<String> sorts;
  final List<String> searchSuggestions;
  final double? minPrice;
  final double? maxPrice;

  /// `true`, wenn der Begriff als Haendlername verstanden wurde.
  bool get isRetailerSearch => searchType == 'retailer';

  /// Der erkannte Haendler, falls vorhanden.
  RecognizedEntity? get retailer {
    for (final entity in recognizedEntities) {
      if (entity.type == 'RETAILER') return entity;
    }
    return null;
  }

  Map<String, dynamic> toJson() => compact({
        'contentCount': {'brochure': brochureCount, 'offer': offerCount},
        'searchType': searchType,
        'recognizedEntities':
            recognizedEntities.map((e) => e.toJson()).toList(),
        'filters': [
          {
            'name': 'publisher',
            'type': 'select',
            'value': {
              'values': publisherFacets.map((e) => e.toJson()).toList(),
            },
          },
          if (minPrice != null || maxPrice != null)
            {
              'name': 'price',
              'type': 'range',
              'value': compact({'min': minPrice, 'max': maxPrice}),
            },
        ],
        'sorts': sorts.map((e) => {'name': e}).toList(),
        'searchSuggestions': searchSuggestions,
      });

  @override
  String toString() => 'SearchMetadata($searchType, $brochureCount Prospekte, '
      '$offerCount Angebote)';
}

/// Ein im Suchbegriff erkannter Haendler, eine Kategorie oder eine Marke.
@immutable
class RecognizedEntity {
  const RecognizedEntity({
    required this.id,
    required this.value,
    required this.type,
  });

  factory RecognizedEntity.fromJson(Map<String, dynamic> json) =>
      RecognizedEntity(
        id: asString(json['id']) ?? '',
        value: asString(json['value']) ?? '',
        type: asString(json['type']) ?? '',
      );

  final String id;
  final String value;

  /// `RETAILER`, `CATEGORY` oder `MANUFACTURER`.
  final String type;

  Map<String, dynamic> toJson() => {'id': id, 'value': value, 'type': type};

  @override
  String toString() => '$type: $value ($id)';
}

/// Ein Facettenwert, z. B. ein Haendler im Ergebnis.
@immutable
class SearchFacet {
  const SearchFacet({required this.value, this.name});

  factory SearchFacet.fromJson(Map<String, dynamic> json) => SearchFacet(
        value: asString(json['value']) ?? '',
        name: asString(json['name']),
      );

  /// Die ID, z. B. `DE-1013`.
  final String value;

  /// Der Anzeigename, z. B. `Lidl`.
  final String? name;

  Map<String, dynamic> toJson() => compact({'value': value, 'name': name});

  @override
  String toString() => '${name ?? value} ($value)';
}

/// Prospekt-Treffer der Suche.
@immutable
class SearchBrochure {
  const SearchBrochure({
    required this.id,
    required this.title,
    required this.publisher,
    this.legacyId,
    this.type,
    this.image,
    this.pageCount = 0,
    this.pageNumber,
    this.distance,
    this.badges = const [],
    this.validFrom,
    this.validUntil,
    this.publishedFrom,
    this.publishedUntil,
    this.hideValidityDate = false,
    this.adPlacement,
  });

  factory SearchBrochure.fromJson(Map<String, dynamic> json) => SearchBrochure(
        id: asString(json['contentId']) ?? asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        publisher: Publisher.fromJson(asMap(json['publisher']) ?? const {}),
        legacyId: asInt(json['legacyId']),
        type: asString(json['type']),
        image: asString(json['image']) ??
            asString(asMap(json['brochureImage'])?['url']),
        pageCount: asInt(json['pageCount']) ?? 0,
        pageNumber: asInt(json['page']),
        distance: asDouble(json['distance']),
        badges: mapList(json['contentBadges'], ContentBadge.fromJson),
        validFrom: asDateTime(json['validFrom']),
        validUntil: asDateTime(json['validUntil']),
        publishedFrom: asDateTime(json['publishedFrom']),
        publishedUntil: asDateTime(json['publishedUntil']),
        hideValidityDate: asBool(json['hideValidityDate']) ?? false,
        adPlacement: asString(json['adPlacement']),
      );

  /// UUID, direkt verwendbar mit `client.brochure()` und `client.pages()`.
  final String id;
  final int? legacyId;
  final String title;

  /// `BROCHURE` fuer statische Prospekte.
  final String? type;
  final Publisher publisher;
  final String? image;
  final int pageCount;

  /// Nullbasierte Seite, auf der der Treffer sitzt.
  final int? pageNumber;

  /// Entfernung zur naechsten Filiale in Kilometern.
  final double? distance;
  final List<ContentBadge> badges;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? publishedFrom;
  final DateTime? publishedUntil;
  final bool hideValidityDate;
  final String? adPlacement;

  /// `true`, wenn der Prospekt gerade laeuft.
  bool get isValidNow {
    final now = DateTime.now();
    final from = validFrom;
    final until = validUntil;
    if (from != null && now.isBefore(from)) return false;
    if (until != null && now.isAfter(until)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => compact({
        'contentId': id,
        'legacyId': legacyId,
        'title': title,
        'type': type,
        'publisher': publisher.toJson(),
        'image': image,
        'pageCount': pageCount,
        'page': pageNumber,
        'distance': distance,
        'contentBadges': badges.map((e) => e.toJson()).toList(),
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'publishedFrom': publishedFrom?.toIso8601String(),
        'publishedUntil': publishedUntil?.toIso8601String(),
        'hideValidityDate': hideValidityDate,
        'adPlacement': adPlacement,
      });

  @override
  String toString() => 'SearchBrochure($id, ${publisher.name}, $title)';
}

/// Angebots-Treffer der Suche.
///
/// Anderes Format als [Offer] aus dem Prospekt-Endpunkt: die Preise sind hier
/// bereits fertig formatiert.
@immutable
class SearchOffer {
  const SearchOffer({
    required this.id,
    required this.title,
    this.brand,
    this.publisherId,
    this.publisherName,
    this.parent,
    this.price,
    this.imageThumbnail,
    this.imageNormal,
    this.imageLarge,
    this.categoryPaths = const [],
    this.preview = false,
    this.score,
    this.adPlacement,
  });

  factory SearchOffer.fromJson(Map<String, dynamic> json) {
    final images = asMap(asMap(json['offerImages'])?['url']);
    return SearchOffer(
      id: asString(json['id']) ?? '',
      title: asString(json['title']) ?? '',
      brand: asString(json['brand']),
      publisherId: asString(json['publisherId']),
      publisherName: asString(json['publisherName']),
      parent: switch (asMap(json['parentContent'])) {
        final Map<String, dynamic> m => SearchOfferParent.fromJson(m),
        null => null,
      },
      price: switch (asMap(json['prices'])) {
        final Map<String, dynamic> m => SearchPrice.fromJson(m),
        null => null,
      },
      imageThumbnail: asString(images?['thumbnail']),
      imageNormal: asString(images?['normal']),
      imageLarge: asString(images?['large']),
      categoryPaths: [
        for (final path in (json['categoryPaths'] as List? ?? const []))
          mapList(path, CategoryRef.fromJson),
      ],
      preview: asBool(json['preview']) ?? false,
      score: asDouble(json['score']),
      adPlacement: asString(json['adPlacement']),
    );
  }

  final String id;
  final String title;
  final String? brand;
  final String? publisherId;
  final String? publisherName;

  /// Prospekt und Seite, auf der das Angebot steht.
  final SearchOfferParent? parent;
  final SearchPrice? price;
  final String? imageThumbnail;
  final String? imageNormal;
  final String? imageLarge;

  /// Mehrere Kategoriepfade von grob nach fein.
  final List<List<CategoryRef>> categoryPaths;
  final bool preview;
  final double? score;
  final String? adPlacement;

  /// Marke plus Titel, sofern eine Marke gemeldet wird.
  String get displayName =>
      brand == null || brand!.isEmpty ? title : '$brand $title';

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'title': title,
        'brand': brand,
        'publisherId': publisherId,
        'publisherName': publisherName,
        'parentContent': parent?.toJson(),
        'prices': price?.toJson(),
        'offerImages': {
          'url': compact({
            'thumbnail': imageThumbnail,
            'normal': imageNormal,
            'large': imageLarge,
          }),
        },
        'categoryPaths': [
          for (final path in categoryPaths)
            path.map((e) => e.toJson()).toList(),
        ],
        'preview': preview,
        'score': score,
        'adPlacement': adPlacement,
      });

  @override
  String toString() => 'SearchOffer($id, $displayName)';
}

/// Verweis vom Suchtreffer auf das Prospekt.
@immutable
class SearchOfferParent {
  const SearchOfferParent({
    required this.id,
    this.legacyId,
    this.type,
    this.pageNumber,
  });

  factory SearchOfferParent.fromJson(Map<String, dynamic> json) =>
      SearchOfferParent(
        id: asString(json['id']) ?? '',
        legacyId: asInt(json['legacyId']),
        type: asString(json['type']),
        pageNumber: asInt(asMap(json['page'])?['number']),
      );

  /// Prospekt-UUID, direkt verwendbar mit `client.pages()`.
  final String id;
  final int? legacyId;
  final String? type;

  /// 1-basierte Seitennummer. Anders als beim Seiten-Endpunkt, der ab 0
  /// zaehlt - am echten Verhalten des Viewers gemessen.
  final int? pageNumber;

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'legacyId': legacyId,
        'type': type,
        'page': pageNumber == null ? null : {'number': pageNumber},
      });

  @override
  String toString() => 'SearchOfferParent($id, Seite $pageNumber)';
}

/// Fertig formatierter Preis eines Suchtreffers.
@immutable
class SearchPrice {
  const SearchPrice({
    this.mainPrice,
    this.mainPriceFormatted,
    this.mainPriceFrequency,
    this.secondaryPrice,
    this.secondaryPriceFormatted,
    this.secondaryPriceIsUvp = false,
    this.priceByBaseUnit,
    this.description,
    this.isRange = false,
    this.conditions = const [],
  });

  factory SearchPrice.fromJson(Map<String, dynamic> json) => SearchPrice(
        mainPrice: asDouble(json['mainPrice']),
        mainPriceFormatted: asString(json['mainPriceFormatted']),
        mainPriceFrequency: asString(json['mainPriceFrequency']),
        secondaryPrice: asDouble(json['secondaryPrice']),
        secondaryPriceFormatted: asString(json['secondaryPriceFormatted']),
        secondaryPriceIsUvp: asBool(json['secondaryPriceIsUVP']) ?? false,
        priceByBaseUnit: asString(json['priceByBaseUnit']),
        description: asString(json['description']),
        isRange: asBool(json['priceRange']) ?? false,
        conditions: stringList(json['conditions']),
      );

  final double? mainPrice;

  /// Bereits lokalisiert, z. B. `0,49 €`.
  final String? mainPriceFormatted;
  final String? mainPriceFrequency;

  /// Streichpreis, `0`, wenn es keinen gibt.
  final double? secondaryPrice;
  final String? secondaryPriceFormatted;

  /// `true`, wenn der Streichpreis die UVP ist.
  final bool secondaryPriceIsUvp;

  /// Grundpreis als Freitext, z. B. `1 kg = 2.33`.
  final String? priceByBaseUnit;
  final String? description;
  final bool isRange;
  final List<String> conditions;

  Map<String, dynamic> toJson() => compact({
        'mainPrice': mainPrice,
        'mainPriceFormatted': mainPriceFormatted,
        'mainPriceFrequency': mainPriceFrequency,
        'secondaryPrice': secondaryPrice,
        'secondaryPriceFormatted': secondaryPriceFormatted,
        'secondaryPriceIsUVP': secondaryPriceIsUvp,
        'priceByBaseUnit': priceByBaseUnit,
        'description': description,
        'priceRange': isRange,
        'conditions': conditions,
      });

  @override
  String toString() => mainPriceFormatted ?? '${mainPrice ?? ''}';
}

/// Kategorieknoten eines Suchtreffers.
@immutable
class CategoryRef {
  const CategoryRef({required this.id, required this.name});

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;
}

/// Ergebnis einer Haendlersuche: der erkannte Haendler plus seine Treffer.
@immutable
class RetailerSearch {
  const RetailerSearch({
    required this.query,
    required this.result,
    this.publisherId,
    this.publisherName,
    this.brochures = const [],
    this.offers = const [],
  });

  /// Der eingegebene Suchbegriff.
  final String query;

  /// Die vollstaendige Antwort, falls Metadaten gebraucht werden.
  ///
  /// Achtung: `result.metadata.brochureCount` und `offerCount` zaehlen alle
  /// Haendler im Suchergebnis. Die Suche mischt verwandte Haendler bei, eine
  /// Suche nach `Lidl` liefert also auch Penny und Netto. Die auf den
  /// erkannten Haendler gefilterten Treffer stehen in [brochures]
  /// und [offers].
  final SearchResult result;

  /// ID des erkannten Haendlers, z. B. `DE-1013`.
  final String? publisherId;

  /// Name des erkannten Haendlers, z. B. `Lidl`.
  final String? publisherName;

  /// Prospekte dieses Haendlers.
  final List<SearchBrochure> brochures;

  /// Angebote dieses Haendlers.
  final List<SearchOffer> offers;

  /// `true`, wenn der Begriff eindeutig als Haendler erkannt wurde.
  bool get isRetailer => publisherId != null;

  @override
  String toString() => 'RetailerSearch($query -> ${publisherName ?? 'kein '
          'Haendler erkannt'}, ${brochures.length} Prospekte, '
      '${offers.length} Angebote)';
}
