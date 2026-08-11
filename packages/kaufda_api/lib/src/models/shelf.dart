import 'package:meta/meta.dart';

import 'common.dart';
import 'json.dart';

/// Branchenfilter der Shelf-Suche (`sectorIds`).
///
/// Die Liste entspricht den Filterchips auf `www.kaufda.de/shelf`.
abstract final class KaufdaSector {
  static const moebelUndEinrichtung = 'DE-24';
  static const supermarkt = 'DE-48';
  static const discounter = 'DE-22';
  static const weitereGeschaefte = 'DE-52';
  static const elektromaerkte = 'DE-20';
  static const drogerieUndParfuemerie = 'DE-51';
  static const baumaerkte = 'DE-19';
  static const apotheken = 'DE-144967788';
  static const banken = 'DE-141091236';
  static const biomaerkte = 'DE-25';
  static const zoohandlung = 'DE-139937565';
  static const reise = 'DE-1180242156';
  static const baecker = 'DE-136615005';
  static const sportgeschaefte = 'DE-16';
  static const buchhandlungen = 'DE-140100810';
  static const sonderposten = 'DE-113946634';
  static const parfuemerienUndBeauty = 'DE-32';
  static const mode = 'DE-23';
  static const werkstattUndAuto = 'DE-16873602';

  /// Anzeigenamen zu den Branchen-IDs.
  static const names = <String, String>{
    moebelUndEinrichtung: 'Möbel & Einrichtung',
    supermarkt: 'Supermarkt',
    discounter: 'Discounter',
    weitereGeschaefte: 'Weitere Geschäfte',
    elektromaerkte: 'Elektromärkte',
    drogerieUndParfuemerie: 'Drogerie und Parfümerie',
    baumaerkte: 'Baumärkte',
    apotheken: 'Apotheken',
    banken: 'Banken',
    biomaerkte: 'Biomärkte',
    zoohandlung: 'Zoohandlung',
    reise: 'Reise',
    baecker: 'Bäcker',
    sportgeschaefte: 'Sportgeschäfte',
    buchhandlungen: 'Buchhandlungen',
    sonderposten: 'Sonderposten',
    parfuemerienUndBeauty: 'Parfümerien & Beauty',
    mode: 'Mode',
    werkstattUndAuto: 'Werkstatt & Auto',
  };

  /// Alle bekannten Branchen-IDs.
  static List<String> get all => names.keys.toList(growable: false);
}

/// Seiteninformation der Shelf-Antwort.
@immutable
class PageInfo {
  const PageInfo({
    this.number = 0,
    this.size = 0,
    this.totalElements = 0,
    this.totalPages = 0,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
        number: asInt(json['number']) ?? 0,
        size: asInt(json['size']) ?? 0,
        totalElements: asInt(json['totalElements']) ?? 0,
        totalPages: asInt(json['totalPages']) ?? 0,
      );

  /// Nullbasierte Seitennummer.
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasNext => number + 1 < totalPages;

  Map<String, dynamic> toJson() => {
        'number': number,
        'size': size,
        'totalElements': totalElements,
        'totalPages': totalPages,
      };

  @override
  String toString() =>
      'PageInfo(Seite ${number + 1}/$totalPages, $totalElements gesamt)';
}

/// Eine Seite der Shelf-Suche: Prospekte im Umkreis eines Standorts.
@immutable
class ShelfPage {
  const ShelfPage({this.items = const [], this.page = const PageInfo()});

  factory ShelfPage.fromJson(Map<String, dynamic> json) {
    final items = <AdContent<ShelfBrochure>>[];
    for (final entry in (json['contents'] as List? ?? const [])) {
      if (entry is! Map<String, dynamic>) continue;
      // Neben Prospekten liegen im Regal auch Blog-Karussells, die kein
      // abrufbares Content-Objekt haben.
      if (!_brochureTypes.contains(asString(entry['contentType']))) continue;
      final content = asMap(entry['content']);
      if (content == null || asString(content['contentId']) == null) continue;
      items.add(AdContent.fromJson(entry, ShelfBrochure.fromJson));
    }
    return ShelfPage(
      items: items,
      page: PageInfo.fromJson(asMap(json['page']) ?? const {}),
    );
  }

  static const _brochureTypes = {'brochure', 'brochurePremium'};

  final List<AdContent<ShelfBrochure>> items;
  final PageInfo page;

  /// Die Prospekte ohne Ad-Umschlag.
  List<ShelfBrochure> get brochures =>
      items.map((e) => e.content).toList(growable: false);

  bool get isEmpty => items.isEmpty;

  Map<String, dynamic> toJson() => {
        'contents': items.map((e) => e.toJson((c) => c.toJson())).toList(),
        'page': page.toJson(),
      };

  @override
  String toString() => 'ShelfPage(${items.length} Prospekte, $page)';
}

/// Prospektkachel aus der Shelf-Suche.
///
/// Enthaelt mehr als [BrochureSummary]: Seitenzahl, Veroeffentlichungszeitraum
/// und die naechstgelegene Filiale liegen direkt bei.
@immutable
class ShelfBrochure {
  const ShelfBrochure({
    required this.id,
    required this.title,
    required this.publisher,
    this.legacyId,
    this.type,
    this.image,
    this.images = const [],
    this.badges = const [],
    this.pageCount = 0,
    this.validFrom,
    this.validUntil,
    this.publishedFrom,
    this.publishedUntil,
    this.closestStore,
    this.hideValidityDate = false,
    this.storeDetailsEnabled = false,
    this.score,
  });

  factory ShelfBrochure.fromJson(Map<String, dynamic> json) => ShelfBrochure(
        id: asString(json['contentId']) ?? '',
        title: asString(json['title']) ?? '',
        publisher: Publisher.fromJson(asMap(json['publisher']) ?? const {}),
        legacyId: asInt(json['id']),
        type: asString(json['type']),
        image: asString(asMap(json['brochureImage'])?['url']),
        images: mapList(json['brochureImages'], ImageRef.fromJson),
        badges: mapList(json['contentBadges'], ContentBadge.fromJson),
        pageCount: asInt(json['pageCount']) ?? 0,
        validFrom: asDateTime(json['validFrom']),
        validUntil: asDateTime(json['validUntil']),
        publishedFrom: asDateTime(json['publishedFrom']),
        publishedUntil: asDateTime(json['publishedUntil']),
        closestStore: switch (asMap(json['closestStore'])) {
          final Map<String, dynamic> m => ShelfStore.fromJson(m),
          null => null,
        },
        hideValidityDate: asBool(json['hideValidityDate']) ?? false,
        storeDetailsEnabled: asBool(json['storeDetailsEnabled']) ?? false,
        score: asDouble(json['score']),
      );

  /// UUID, direkt verwendbar mit `client.brochure()` und `client.pages()`.
  final String id;

  /// Numerische Alt-ID.
  final int? legacyId;
  final String title;

  /// `BROCHURE` fuer statische Prospekte, `DYNAMIC` fuer Premium-Kacheln.
  final String? type;
  final Publisher publisher;
  final String? image;
  final List<ImageRef> images;
  final List<ContentBadge> badges;
  final int pageCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? publishedFrom;
  final DateTime? publishedUntil;

  /// Naechstgelegene Filiale zum abgefragten Standort.
  final ShelfStore? closestStore;
  final bool hideValidityDate;
  final bool storeDetailsEnabled;

  /// Relevanzwert der Sortierung.
  final double? score;

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
        'id': legacyId,
        'title': title,
        'type': type,
        'publisher': publisher.toJson(),
        'brochureImage': image == null ? null : {'url': image},
        'brochureImages': images.map((e) => e.toJson()).toList(),
        'contentBadges': badges.map((e) => e.toJson()).toList(),
        'pageCount': pageCount,
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'publishedFrom': publishedFrom?.toIso8601String(),
        'publishedUntil': publishedUntil?.toIso8601String(),
        'closestStore': closestStore?.toJson(),
        'hideValidityDate': hideValidityDate,
        'storeDetailsEnabled': storeDetailsEnabled,
        'score': score,
      });

  @override
  String toString() => 'ShelfBrochure($id, ${publisher.name}, $title)';
}

/// Filiale, wie sie in der Shelf-Antwort steckt.
///
/// Eigenes Modell, weil die Shelf-API andere Feldnamen und eine numerische ID
/// verwendet als `/v1/nearestStore`.
@immutable
class ShelfStore {
  const ShelfStore({
    required this.id,
    required this.name,
    this.externalId,
    this.street,
    this.streetNumber,
    this.zip,
    this.city,
    this.lat,
    this.lng,
  });

  factory ShelfStore.fromJson(Map<String, dynamic> json) => ShelfStore(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
        externalId: asString(json['externalId']),
        street: asString(json['street']),
        streetNumber: asString(json['streetNumber']),
        zip: asString(json['zip']),
        city: asString(json['city']),
        lat: asDouble(json['latitude']),
        lng: asDouble(json['longitude']),
      );

  final int id;
  final String name;

  /// Filialnummer beim Haendler.
  final String? externalId;
  final String? street;
  final String? streetNumber;
  final String? zip;
  final String? city;
  final double? lat;
  final double? lng;

  String get address {
    final line1 = [street, streetNumber].where(_notEmpty).join(' ');
    final line2 = [zip, city].where(_notEmpty).join(' ');
    return [line1, line2].where((e) => e.isNotEmpty).join(', ');
  }

  static bool _notEmpty(String? value) => value != null && value.isNotEmpty;

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'name': name,
        'externalId': externalId,
        'street': street,
        'streetNumber': streetNumber,
        'zip': zip,
        'city': city,
        'latitude': lat,
        'longitude': lng,
      });

  @override
  String toString() => 'ShelfStore($id, $name, $address)';
}
