import 'package:meta/meta.dart';

import 'common.dart';
import 'json.dart';
import 'offer.dart';

/// Eine Prospektseite aus `GET /v1/brochures/{id}/pages`.
@immutable
class BrochurePage {
  const BrochurePage({
    required this.number,
    this.images = const [],
    this.linkOuts = const [],
    this.offers = const [],
  });

  factory BrochurePage.fromJson(Map<String, dynamic> json) => BrochurePage(
        number: asInt(json['number']) ?? 0,
        images: mapList(json['images'], ImageRef.fromJson),
        linkOuts: mapList(json['linkOuts'], PageLinkOut.fromJson),
        offers: mapList(
          json['offers'],
          (m) => AdContent.fromJson(m, Offer.fromJson),
        ),
      );

  /// Nullbasierte Seitennummer.
  final int number;

  /// Seitenbilder in mehreren Groessen (`75x96`, `768x1024`, `1600x1600`,
  /// `2800x2800`).
  final List<ImageRef> images;

  /// Verlinkte Flaechen auf der Seite.
  final List<PageLinkOut> linkOuts;
  final List<AdContent<Offer>> offers;

  /// Die Angebote ohne Ad-Umschlag.
  List<Offer> get offerContents =>
      offers.map((e) => e.content).toList(growable: false);

  /// Seitenbild in exakt dieser Groesse, z. B. `imageBySize('768x1024')`.
  ImageRef? imageBySize(String size) {
    for (final image in images) {
      if (image.size == size) return image;
    }
    return null;
  }

  /// Das groesste verfuegbare Seitenbild.
  ImageRef? get largestImage {
    ImageRef? best;
    var bestArea = -1;
    for (final image in images) {
      final area = (image.width ?? 0) * (image.height ?? 0);
      if (area > bestArea) {
        bestArea = area;
        best = image;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'images': images.map((e) => e.toJson()).toList(),
        'linkOuts': linkOuts.map((e) => e.toJson()).toList(),
        'offers': offers.map((e) => e.toJson((c) => c.toJson())).toList(),
      };

  @override
  String toString() =>
      'BrochurePage($number, ${offers.length} Angebote, ${images.length} Bilder)';
}

/// Verlinkte Flaeche auf einer Prospektseite.
@immutable
class PageLinkOut {
  const PageLinkOut({
    required this.id,
    this.label,
    this.webUrl,
    this.mobileUrl,
    this.position,
  });

  factory PageLinkOut.fromJson(Map<String, dynamic> json) => PageLinkOut(
        id: asString(json['id']) ?? '',
        label: asString(json['label']),
        webUrl: asString(json['webUrl']),
        mobileUrl: asString(json['mobileUrl']),
        position: switch (asMap(json['position'])) {
          final Map<String, dynamic> m => NormalizedPoint.fromJson(m),
          null => null,
        },
      );

  final String id;
  final String? label;
  final String? webUrl;
  final String? mobileUrl;

  /// Position des Hotspots, normalisiert auf 0..1.
  final NormalizedPoint? position;

  String? get url => mobileUrl ?? webUrl;

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'label': label,
        'webUrl': webUrl,
        'mobileUrl': mobileUrl,
        'position': position?.toJson(),
      });

  @override
  String toString() => 'PageLinkOut($label)';
}
