import 'package:meta/meta.dart';

import 'json.dart';

/// Ein Bild in einer bestimmten Groesse, z. B. `128x128` oder `zoomlarge`.
@immutable
class ImageRef {
  const ImageRef({required this.url, this.size, this.type});

  factory ImageRef.fromJson(Map<String, dynamic> json) => ImageRef(
        url: asString(json['url']) ?? '',
        size: asString(json['size']),
        type: asString(json['type']),
      );

  final String url;

  /// Format `<breite>x<hoehe>`, so wie es die API meldet.
  final String? size;

  /// Optionaler Verwendungszweck, z. B. `offer`, `storeLogo`, `storeMapMarker`.
  final String? type;

  /// Breite aus [size], falls parsebar.
  int? get width => _dimension(0);

  /// Hoehe aus [size], falls parsebar.
  int? get height => _dimension(1);

  int? _dimension(int index) {
    final parts = size?.split('x');
    if (parts == null || parts.length != 2) return null;
    return int.tryParse(parts[index]);
  }

  Map<String, dynamic> toJson() =>
      compact({'url': url, 'size': size, 'type': type});

  @override
  String toString() => 'ImageRef($url, size: $size, type: $type)';
}

/// Bildmasse in Pixeln.
@immutable
class Dimensions {
  const Dimensions({required this.width, required this.height});

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
        width: asInt(json['width']) ?? 0,
        height: asInt(json['height']) ?? 0,
      );

  final int width;
  final int height;

  Map<String, dynamic> toJson() => {'width': width, 'height': height};

  @override
  String toString() => '${width}x$height';
}

/// Haendler bzw. Werbetreibender, z. B. `DE-1013` / `Lidl`.
@immutable
class Publisher {
  const Publisher({
    required this.id,
    required this.name,
    this.type,
    this.primarySectorId,
    this.images = const [],
  });

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        type: asString(json['type']),
        primarySectorId: asString(json['primarySectorId']),
        images: mapList(json['images'], ImageRef.fromJson),
      );

  final String id;
  final String name;

  /// Bisher nur `RETAILER` beobachtet.
  final String? type;
  final String? primarySectorId;
  final List<ImageRef> images;

  /// Logo in der gewuenschten Groesse, z. B. `logo('128x128')`.
  ImageRef? logo(String size) {
    for (final image in images) {
      if (image.size == size && image.type == null) return image;
    }
    return null;
  }

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'name': name,
        'type': type,
        'primarySectorId': primarySectorId,
        'images': images.map((e) => e.toJson()).toList(),
      });

  @override
  String toString() => 'Publisher($id, $name)';
}

/// Badge auf einer Prospektkachel, z. B. `new`, `popular`, `valid_soon`.
@immutable
class ContentBadge {
  const ContentBadge({required this.name});

  factory ContentBadge.fromJson(Map<String, dynamic> json) =>
      ContentBadge(name: asString(json['name']) ?? '');

  final String name;

  Map<String, dynamic> toJson() => {'name': name};

  @override
  String toString() => name;
}

/// Externe Zaehl-Pixel. In der aufgezeichneten Traffic-Probe immer leer,
/// deshalb bewusst untypisiert durchgereicht.
@immutable
class ExternalTracking {
  const ExternalTracking({this.impression = const [], this.click = const []});

  factory ExternalTracking.fromJson(Map<String, dynamic> json) =>
      ExternalTracking(
        impression: (json['impression'] as List?) ?? const [],
        click: (json['click'] as List?) ?? const [],
      );

  final List<dynamic> impression;
  final List<dynamic> click;

  bool get isEmpty => impression.isEmpty && click.isEmpty;

  Map<String, dynamic> toJson() => {'impression': impression, 'click': click};
}

/// Umschlag, in dem die API ausgespielte Inhalte liefert: der eigentliche
/// Inhalt plus Platzierungs- und Tracking-Metadaten.
@immutable
class AdContent<T> {
  const AdContent({
    required this.content,
    this.placement,
    this.adFormat,
    this.externalTracking,
  });

  static AdContent<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseContent,
  ) =>
      AdContent<T>(
        content: parseContent(asMap(json['content']) ?? const {}),
        placement: asString(json['placement']),
        adFormat: asString(json['adFormat']),
        externalTracking: switch (asMap(json['externalTracking'])) {
          final Map<String, dynamic> m => ExternalTracking.fromJson(m),
          null => null,
        },
      );

  /// z. B. `ad_placement__brochure_bar`, `ad_placement__next_brochure`.
  final String? placement;

  /// z. B. `ad_format__brochure_card_cover`.
  final String? adFormat;
  final T content;
  final ExternalTracking? externalTracking;

  Map<String, dynamic> toJson(Object? Function(T) encodeContent) => compact({
        'placement': placement,
        'adFormat': adFormat,
        'content': encodeContent(content),
        'externalTracking': externalTracking?.toJson(),
      });

  @override
  String toString() => 'AdContent($placement, $content)';
}

/// Normalisierter Punkt (0..1) relativ zur Seitengroesse.
@immutable
class NormalizedPoint {
  const NormalizedPoint({required this.x, required this.y});

  factory NormalizedPoint.fromJson(Map<String, dynamic> json) =>
      NormalizedPoint(
        x: asDouble(json['x']) ?? 0,
        y: asDouble(json['y']) ?? 0,
      );

  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  String toString() => '($x, $y)';
}

/// Normalisiertes Rechteck (0..1) auf einer Prospektseite.
@immutable
class NormalizedArea {
  const NormalizedArea({required this.topLeft, required this.bottomRight});

  factory NormalizedArea.fromJson(Map<String, dynamic> json) => NormalizedArea(
        topLeft: NormalizedPoint.fromJson(asMap(json['topLeft']) ?? const {}),
        bottomRight:
            NormalizedPoint.fromJson(asMap(json['bottomRight']) ?? const {}),
      );

  final NormalizedPoint topLeft;
  final NormalizedPoint bottomRight;

  double get width => bottomRight.x - topLeft.x;
  double get height => bottomRight.y - topLeft.y;

  Map<String, dynamic> toJson() =>
      {'topLeft': topLeft.toJson(), 'bottomRight': bottomRight.toJson()};

  @override
  String toString() => 'NormalizedArea($topLeft -> $bottomRight)';
}
