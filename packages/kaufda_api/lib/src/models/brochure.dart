import 'package:meta/meta.dart';

import 'common.dart';
import 'json.dart';

/// Vollstaendige Prospekt-Metadaten aus `GET /v1/brochures/{id}`.
@immutable
class Brochure {
  const Brochure({
    required this.id,
    required this.title,
    required this.type,
    required this.publisher,
    this.legacyId,
    this.image,
    this.headerImage,
    this.pageCount = 0,
    this.preview = false,
    this.nearestStoreEnabled = false,
    this.showPremiumPanel = false,
    this.badges = const [],
    this.validFrom,
    this.validUntil,
  });

  factory Brochure.fromJson(Map<String, dynamic> json) => Brochure(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        type: asString(json['type']) ?? '',
        publisher: Publisher.fromJson(asMap(json['publisher']) ?? const {}),
        legacyId: asInt(json['legacyId']),
        image: asString(json['image']),
        headerImage: asString(asMap(json['header'])?['image']),
        pageCount: asInt(json['pageCount']) ?? 0,
        preview: asBool(json['preview']) ?? false,
        nearestStoreEnabled: asBool(json['nearestStoreEnabled']) ?? false,
        showPremiumPanel: asBool(json['showPremiumPanel']) ?? false,
        badges: mapList(json['contentBadges'], ContentBadge.fromJson),
        validFrom: asDateTime(json['validFrom']),
        validUntil: asDateTime(json['validUntil']),
      );

  /// UUID des Prospekts, wird von allen anderen Endpunkten als `brochureId`
  /// erwartet.
  final String id;

  /// Numerische Alt-ID, taucht im Tracking als `id` auf.
  final int? legacyId;
  final String title;

  /// Bisher beobachtet: `static_brochure`.
  final String type;
  final Publisher publisher;

  /// Vorschaubild (Titelseite).
  final String? image;

  /// Optionales Kopfbild im Viewer.
  final String? headerImage;
  final int pageCount;
  final bool preview;
  final bool nearestStoreEnabled;
  final bool showPremiumPanel;
  final List<ContentBadge> badges;
  final DateTime? validFrom;
  final DateTime? validUntil;

  bool get isValidNow {
    final now = DateTime.now();
    final from = validFrom;
    final until = validUntil;
    if (from != null && now.isBefore(from)) return false;
    if (until != null && now.isAfter(until)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'legacyId': legacyId,
        'title': title,
        'type': type,
        'publisher': publisher.toJson(),
        'image': image,
        'header': headerImage == null ? null : {'image': headerImage},
        'pageCount': pageCount,
        'preview': preview,
        'nearestStoreEnabled': nearestStoreEnabled,
        'showPremiumPanel': showPremiumPanel,
        'contentBadges': badges.map((e) => e.toJson()).toList(),
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
      });

  @override
  String toString() => 'Brochure($id, ${publisher.name}, $title)';
}

/// Verkuerzte Prospekt-Kachel, wie sie in Sidebar, Related und LastPage
/// ausgeliefert wird.
@immutable
class BrochureSummary {
  const BrochureSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.publisher,
    this.legacyId,
    this.image,
    this.badges = const [],
    this.validFrom,
    this.validUntil,
  });

  factory BrochureSummary.fromJson(Map<String, dynamic> json) =>
      BrochureSummary(
        id: asString(json['contentId']) ?? asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        type: asString(json['type']) ?? '',
        publisher: Publisher.fromJson(asMap(json['publisher']) ?? const {}),
        legacyId: asInt(json['id']),
        image: asString(json['image']),
        badges: mapList(json['contentBadges'], ContentBadge.fromJson),
        validFrom: asDateTime(json['validFrom']),
        validUntil: asDateTime(json['validUntil']),
      );

  /// UUID (`contentId` im Rohformat).
  final String id;

  /// Numerische Alt-ID (`id` im Rohformat).
  final int? legacyId;
  final String title;
  final String type;
  final Publisher publisher;
  final String? image;
  final List<ContentBadge> badges;
  final DateTime? validFrom;
  final DateTime? validUntil;

  /// `true`, wenn der Prospekt gerade laeuft. Fehlende Angaben gelten als
  /// gueltig.
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
        'image': image,
        'contentBadges': badges.map((e) => e.toJson()).toList(),
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
      });

  @override
  String toString() => 'BrochureSummary($id, ${publisher.name}, $title)';
}

/// Antwortform von `/v1/sidebar`, `/v1/lastPage` und `/v1/brochures/related`.
@immutable
class BrochureCollections {
  const BrochureCollections({
    this.publisherBrochures = const [],
    this.sectorBrochures = const [],
    this.popularBrochures = const [],
  });

  factory BrochureCollections.fromJson(Map<String, dynamic> json) =>
      BrochureCollections(
        publisherBrochures: _parse(json['publisherBrochures']),
        sectorBrochures: _parse(json['sectorBrochures']),
        popularBrochures: _parse(json['popularBrochures']),
      );

  static List<AdContent<BrochureSummary>> _parse(Object? value) => mapList(
        value,
        (json) => AdContent.fromJson(json, BrochureSummary.fromJson),
      );

  /// Weitere Prospekte desselben Haendlers.
  final List<AdContent<BrochureSummary>> publisherBrochures;

  /// Prospekte aus derselben Branche.
  final List<AdContent<BrochureSummary>> sectorBrochures;

  /// Aktuell beliebte Prospekte in der Naehe.
  final List<AdContent<BrochureSummary>> popularBrochures;

  /// Alle drei Listen hintereinander.
  List<AdContent<BrochureSummary>> get all =>
      [...publisherBrochures, ...sectorBrochures, ...popularBrochures];

  bool get isEmpty => all.isEmpty;

  Map<String, dynamic> toJson() => {
        'publisherBrochures': _encode(publisherBrochures),
        'sectorBrochures': _encode(sectorBrochures),
        'popularBrochures': _encode(popularBrochures),
      };

  static List<Map<String, dynamic>> _encode(
    List<AdContent<BrochureSummary>> items,
  ) =>
      items.map((e) => e.toJson((c) => c.toJson())).toList();

  @override
  String toString() => 'BrochureCollections(publisher: '
      '${publisherBrochures.length}, sector: ${sectorBrochures.length}, '
      'popular: ${popularBrochures.length})';
}
