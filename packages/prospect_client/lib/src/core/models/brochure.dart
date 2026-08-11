import 'package:meta/meta.dart';

import 'brochure_page.dart';
import 'image_set.dart';
import 'offer.dart';
import 'store.dart';

/// Wie tief die Daten eines Prospekts strukturiert sind.
///
/// Direkt aus der Messung abgeleitet, nicht theoretisch: ALDI liefert ueber
/// Tjek ausschliesslich Seitenbilder, Kaufland ueber Schwarz 422 Produkte ohne
/// Preis, Netto ueber Tjek vollstaendige Angebote mit Preis und Streichpreis.
/// Ein einzelnes bool waere fuer diese drei Faelle zu grob.
enum BrochureContentLevel {
  /// Noch nicht bestimmt.
  ///
  /// Gilt fuer Listeneintraege von Quellen, die den Inhaltsgrad erst im
  /// Detailabruf preisgeben. Schwarz ist so ein Fall: die Uebersicht enthaelt
  /// keine Produkte, das heisst aber nicht, dass der Prospekt keine hat.
  /// Bewusst ein eigener Wert, damit die App nicht faelschlich "nur Bilder"
  /// anzeigt, wo in Wahrheit noch nichts geprueft wurde.
  unknown,

  /// Nur Seitenbilder und ggf. PDF. Keine Produktdaten.
  imagesOnly,

  /// Produktnamen, Bilder und Seitenpositionen, aber keine Preise.
  productsWithoutPrices,

  /// Vollstaendige Angebote inklusive Preis.
  productsWithPrices;

  /// True nur, wenn geprueft und Produkte vorhanden.
  bool get hasProducts =>
      this == productsWithoutPrices || this == productsWithPrices;

  bool get hasPrices => this == productsWithPrices;

  /// True, wenn ein Detailabruf noetig ist, um den Inhalt zu kennen.
  bool get isDetermined => this != unknown;
}

/// Fuer welchen Bereich ein Prospekt gilt.
///
/// Ohne diese Unterscheidung ist eine Prospektliste irrefuehrend: HIT
/// veroeffentlicht denselben Wochenprospekt in ueber 50 Filialvarianten
/// ("KW 33/2026 Hann. Muenden", "... Bonn-Bad Godesberg", ...), Lidl in rund
/// 40 Regionalvarianten. Wer die unbesehen untereinander anzeigt, praesentiert
/// Nutzern ueberwiegend Angebote, die in ihrer Filiale nicht gelten.
enum BrochureCoverage {
  /// Nicht bestimmbar, weil die Quelle dazu nichts sagt.
  unknown,

  /// Gilt bundesweit in allen Filialen des Haendlers.
  national,

  /// Gilt in einem Vertriebsgebiet, nicht bundesweit.
  regional,

  /// Gilt nur in bestimmten Filialen.
  storeBound;

  /// True, wenn der Prospekt ohne Ortsbezug nicht sinnvoll anzeigbar ist.
  bool get needsLocation => this == regional || this == storeBound;
}

/// Global eindeutige Prospekt-Kennung.
///
/// Die nativen IDs der Quellen kollidieren potenziell, deshalb wird die
/// Quellen-ID immer mitgefuehrt. Serialisierte Form: `tjek:3sBnfFlz`.
@immutable
class BrochureId {
  const BrochureId(this.sourceId, this.nativeId);

  final String sourceId;
  final String nativeId;

  static BrochureId? tryParse(String value) {
    final index = value.indexOf(':');
    if (index <= 0 || index == value.length - 1) return null;
    return BrochureId(value.substring(0, index), value.substring(index + 1));
  }

  @override
  bool operator ==(Object other) =>
      other is BrochureId &&
      other.sourceId == sourceId &&
      other.nativeId == nativeId;

  @override
  int get hashCode => Object.hash(sourceId, nativeId);

  @override
  String toString() => '$sourceId:$nativeId';
}

/// Ein digitaler Prospekt.
@immutable
class Brochure {
  const Brochure({
    required this.id,
    required this.retailerId,
    required this.title,
    required this.contentLevel,
    this.subtitle,
    this.validFrom,
    this.validUntil,
    this.publishedAt,
    this.pageCount = 0,
    this.cover = ImageSet.empty,
    this.pdfUrl,
    this.coverage = BrochureCoverage.unknown,
    this.regionCodes = const [],
    this.pages = const [],
    this.offers = const [],
    this.webUrl,
    this.closestStore,
  });

  final BrochureId id;

  /// Kanonische Haendler-ID, quellenunabhaengig (z.B. `kaufland`).
  final String retailerId;

  final String title;

  /// Zusatzzeile der Quelle, meist der Gueltigkeitszeitraum als Text.
  final String? subtitle;

  final BrochureContentLevel contentLevel;

  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? publishedAt;

  /// Seitenzahl laut Quelle. Kann von `pages.length` abweichen, solange die
  /// Detailansicht nicht geladen wurde.
  final int pageCount;

  final ImageSet cover;
  final Uri? pdfUrl;

  /// Fuer welchen Bereich der Prospekt gilt.
  final BrochureCoverage coverage;

  /// Regionscodes oder Filialnummern der Quelle, fuer die dieser Prospekt gilt.
  ///
  /// Eine Liste, weil Lidl einen Prospekt regelmaessig mehreren
  /// `offer_region`-Codes zuordnet. Leer bei nationalen Prospekten und bei
  /// Quellen, die keine Codes fuehren. Die konkreten Filialen liefert
  /// [ProspectRepository.getBrochureStores].
  final List<String> regionCodes;

  /// Erster Regionscode, fuer Anzeige und Weitergabe an die Quelle.
  String? get primaryRegionCode =>
      regionCodes.isEmpty ? null : regionCodes.first;

  /// Leer in der Listenansicht, gefuellt nach [ProspectRepository.getBrochure].
  final List<BrochurePage> pages;
  final List<Offer> offers;

  /// Menschenlesbare Seite beim Haendler, fuer "im Browser oeffnen".
  final Uri? webUrl;

  /// Naechstgelegene Filiale zum abgefragten Standort, sofern die Quelle sie
  /// direkt am Prospekt mitliefert (kaufDA-Shelf tut das). Beantwortet die
  /// Nutzerfrage "wo gilt das bei mir", ohne einen eigenen Filialabruf.
  final Store? closestStore;

  String get sourceId => id.sourceId;

  /// True, sobald Seiten oder Angebote geladen wurden.
  bool get isDetailLoaded => pages.isNotEmpty || offers.isNotEmpty;

  bool isExpiredAt(DateTime now) {
    final until = validUntil;
    return until != null && now.isAfter(until);
  }

  bool isActiveAt(DateTime now) {
    final from = validFrom;
    if (from != null && now.isBefore(from)) return false;
    return !isExpiredAt(now);
  }

  Brochure copyWith({
    List<BrochurePage>? pages,
    List<Offer>? offers,
    BrochureContentLevel? contentLevel,
    Uri? pdfUrl,
    int? pageCount,
  }) =>
      Brochure(
        id: id,
        retailerId: retailerId,
        title: title,
        subtitle: subtitle,
        contentLevel: contentLevel ?? this.contentLevel,
        validFrom: validFrom,
        validUntil: validUntil,
        publishedAt: publishedAt,
        pageCount: pageCount ?? this.pageCount,
        cover: cover,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        coverage: coverage,
        regionCodes: regionCodes,
        pages: pages ?? this.pages,
        offers: offers ?? this.offers,
        webUrl: webUrl,
        closestStore: closestStore,
      );

  Map<String, Object?> toJson() => {
        'id': id.toString(),
        'retailerId': retailerId,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'contentLevel': contentLevel.name,
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
        'pageCount': pageCount,
        if (!cover.isEmpty) 'cover': cover.toJson(),
        if (pdfUrl != null) 'pdfUrl': pdfUrl.toString(),
        'coverage': coverage.name,
        if (regionCodes.isNotEmpty) 'regionCodes': regionCodes,
        if (webUrl != null) 'webUrl': webUrl.toString(),
        if (closestStore != null) 'closestStore': closestStore!.toJson(),
        if (pages.isNotEmpty) 'pages': pages.map((p) => p.toJson()).toList(),
        if (offers.isNotEmpty) 'offers': offers.map((o) => o.toJson()).toList(),
      };

  static Brochure fromJson(Map<String, Object?> json) => Brochure(
        id: BrochureId.tryParse(json['id']! as String)!,
        retailerId: json['retailerId'] as String? ?? 'unknown',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        contentLevel: BrochureContentLevel.values.firstWhere(
          (l) => l.name == json['contentLevel'],
          orElse: () => BrochureContentLevel.unknown,
        ),
        validFrom: _date(json['validFrom']),
        validUntil: _date(json['validUntil']),
        publishedAt: _date(json['publishedAt']),
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        cover: json['cover'] == null
            ? ImageSet.empty
            : ImageSet.fromJson(json['cover']! as Map<String, Object?>),
        pdfUrl:
            json['pdfUrl'] is String ? Uri.tryParse(json['pdfUrl']! as String) : null,
        coverage: BrochureCoverage.values.firstWhere(
          (c) => c.name == json['coverage'],
          orElse: () => BrochureCoverage.unknown,
        ),
        regionCodes:
            (json['regionCodes'] as List?)?.whereType<String>().toList() ??
                const [],
        webUrl:
            json['webUrl'] is String ? Uri.tryParse(json['webUrl']! as String) : null,
        closestStore: json['closestStore'] is Map<String, Object?>
            ? Store.fromJson(json['closestStore']! as Map<String, Object?>)
            : null,
        pages: (json['pages'] as List?)
                ?.whereType<Map<String, Object?>>()
                .map(BrochurePage.fromJson)
                .toList() ??
            const [],
        offers: (json['offers'] as List?)
                ?.whereType<Map<String, Object?>>()
                .map(Offer.fromJson)
                .toList() ??
            const [],
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  String toString() => 'Brochure($id, $title, ${contentLevel.name})';
}
