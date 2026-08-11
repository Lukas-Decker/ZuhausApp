import 'package:meta/meta.dart';

import 'image_set.dart';

/// Abmessungen einer Prospektseite in Pixeln, soweit die Quelle sie angibt.
@immutable
class PageDimensions {
  const PageDimensions(this.width, this.height);

  final double width;
  final double height;

  double get aspectRatio => height == 0 ? 1.0 : width / height;

  Map<String, Object?> toJson() => {'width': width, 'height': height};

  static PageDimensions? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final w = json['width'];
    final h = json['height'];
    if (w is! num || h is! num) return null;
    return PageDimensions(w.toDouble(), h.toDouble());
  }

  @override
  String toString() => '${width.toInt()}x${height.toInt()}';
}

/// Position eines Angebots oder Links auf einer Prospektseite.
///
/// Alle Werte sind Prozent der Seitenbreite bzw. -hoehe (0 bis 100). Beide
/// angebundenen Quellen arbeiten relativ, damit die Koordinaten unabhaengig
/// von der gewaehlten Bildaufloesung gueltig bleiben.
@immutable
class Hotspot {
  const Hotspot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.offerId,
    this.label,
    this.link,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// Verweis auf [Offer.id], falls der Hotspot ein Angebot markiert.
  final String? offerId;

  final String? label;
  final Uri? link;

  Map<String, Object?> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        if (offerId != null) 'offerId': offerId,
        if (label != null) 'label': label,
        if (link != null) 'link': link.toString(),
      };

  static Hotspot? fromJson(Map<String, Object?> json) {
    final l = json['left'];
    final t = json['top'];
    final w = json['width'];
    final h = json['height'];
    if (l is! num || t is! num || w is! num || h is! num) return null;
    return Hotspot(
      left: l.toDouble(),
      top: t.toDouble(),
      width: w.toDouble(),
      height: h.toDouble(),
      offerId: json['offerId'] as String?,
      label: json['label'] as String?,
      link: json['link'] is String ? Uri.tryParse(json['link']! as String) : null,
    );
  }

  @override
  String toString() => 'Hotspot(${offerId ?? label ?? '?'})';
}

/// Eine Seite eines Prospekts.
@immutable
class BrochurePage {
  const BrochurePage({
    required this.number,
    this.images = ImageSet.empty,
    this.dimensions,
    this.altText,
    this.hotspots = const [],
  });

  /// 1-basierte Seitenzahl.
  final int number;

  final ImageSet images;
  final PageDimensions? dimensions;

  /// Bildbeschreibung der Quelle. Schwarz liefert hier brauchbare Texte, die
  /// sich direkt als Accessibility-Label verwenden lassen.
  final String? altText;

  final List<Hotspot> hotspots;

  Map<String, Object?> toJson() => {
        'number': number,
        if (!images.isEmpty) 'images': images.toJson(),
        if (dimensions != null) 'dimensions': dimensions!.toJson(),
        if (altText != null) 'altText': altText,
        if (hotspots.isNotEmpty)
          'hotspots': hotspots.map((h) => h.toJson()).toList(),
      };

  static BrochurePage fromJson(Map<String, Object?> json) => BrochurePage(
        number: (json['number'] as num).toInt(),
        images: json['images'] == null
            ? ImageSet.empty
            : ImageSet.fromJson(json['images']! as Map<String, Object?>),
        dimensions:
            PageDimensions.fromJson(json['dimensions'] as Map<String, Object?>?),
        altText: json['altText'] as String?,
        hotspots: (json['hotspots'] as List?)
                ?.whereType<Map<String, Object?>>()
                .map(Hotspot.fromJson)
                .whereType<Hotspot>()
                .toList() ??
            const [],
      );

  @override
  String toString() => 'BrochurePage($number)';
}
