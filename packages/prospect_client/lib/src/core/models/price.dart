import 'package:meta/meta.dart';

/// Preis eines Angebots.
///
/// Bewusst als eigenes Objekt und nicht als Feldergruppe auf [Offer], weil
/// Quellen wie Schwarz/Kaufland Produkte ohne jeden Preis liefern. Dort ist
/// `Offer.price` schlicht null, statt dass Platzhalterwerte erfunden werden.
@immutable
class Price {
  const Price({
    required this.current,
    required this.currency,
    this.previous,
    this.basePriceText,
    this.formatted,
  });

  /// Aktueller Preis als Zahl, nicht als formatierter Text.
  final double current;

  /// ISO-4217-Code, in der Praxis immer `EUR`.
  final String currency;

  /// Streichpreis, falls die Quelle einen liefert (Tjek `pre_price`).
  final double? previous;

  /// Grundpreisangabe im Originaltext, z.B. `(1 kg = 6.60)`.
  /// Wird nicht geparst, weil die Formate zwischen Quellen zu stark schwanken.
  final String? basePriceText;

  /// Von der Quelle vorformatierte Darstellung, falls vorhanden.
  final String? formatted;

  bool get hasDiscount => previous != null && previous! > current;

  /// Rabatt in Prozent, gerundet auf eine Nachkommastelle.
  /// Null, wenn kein Streichpreis vorliegt oder dieser nicht groesser ist.
  double? get discountPercent {
    final before = previous;
    if (before == null || before <= 0 || before <= current) return null;
    return double.parse((((before - current) / before) * 100).toStringAsFixed(1));
  }

  Map<String, Object?> toJson() => {
        'current': current,
        'currency': currency,
        if (previous != null) 'previous': previous,
        if (basePriceText != null) 'basePriceText': basePriceText,
        if (formatted != null) 'formatted': formatted,
      };

  static Price? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final current = json['current'];
    if (current is! num) return null;
    return Price(
      current: current.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      previous: (json['previous'] as num?)?.toDouble(),
      basePriceText: json['basePriceText'] as String?,
      formatted: json['formatted'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Price &&
      other.current == current &&
      other.currency == currency &&
      other.previous == previous &&
      other.basePriceText == basePriceText &&
      other.formatted == formatted;

  @override
  int get hashCode =>
      Object.hash(current, currency, previous, basePriceText, formatted);

  @override
  String toString() =>
      'Price(${current.toStringAsFixed(2)} $currency${previous != null ? ', statt ${previous!.toStringAsFixed(2)}' : ''})';
}

/// Mengenangabe eines Angebots.
///
/// Uebernimmt die Struktur von Tjek, weil sie die einzige Quelle ist, die eine
/// SI-Normalisierung mitliefert. Damit lassen sich Angebote unterschiedlicher
/// Haendler vergleichen, ohne Texte zu parsen.
@immutable
class Quantity {
  const Quantity({
    this.unitSymbol,
    this.sizeFrom,
    this.sizeTo,
    this.siSymbol,
    this.siFactor,
    this.piecesFrom,
    this.piecesTo,
  });

  /// Einheit wie in der Anzeige, z.B. `g` oder `l`.
  final String? unitSymbol;

  /// Untere und obere Grenze der Packungsgroesse. Bei fixen Groessen gleich.
  final double? sizeFrom;
  final double? sizeTo;

  /// Basiseinheit und Umrechnungsfaktor, z.B. `kg` mit Faktor 0.001 fuer Gramm.
  final String? siSymbol;
  final double? siFactor;

  final int? piecesFrom;
  final int? piecesTo;

  /// Groesse in der SI-Basiseinheit, sofern beide Angaben vorliegen.
  /// Nutzt die untere Grenze, damit Grundpreise nicht zu guenstig wirken.
  double? get sizeInSiUnit {
    final size = sizeFrom;
    final factor = siFactor;
    if (size == null || factor == null) return null;
    return size * factor;
  }

  bool get isEmpty =>
      unitSymbol == null && sizeFrom == null && piecesFrom == null;

  Map<String, Object?> toJson() => {
        if (unitSymbol != null) 'unitSymbol': unitSymbol,
        if (sizeFrom != null) 'sizeFrom': sizeFrom,
        if (sizeTo != null) 'sizeTo': sizeTo,
        if (siSymbol != null) 'siSymbol': siSymbol,
        if (siFactor != null) 'siFactor': siFactor,
        if (piecesFrom != null) 'piecesFrom': piecesFrom,
        if (piecesTo != null) 'piecesTo': piecesTo,
      };

  static Quantity? fromJson(Map<String, Object?>? json) {
    if (json == null || json.isEmpty) return null;
    return Quantity(
      unitSymbol: json['unitSymbol'] as String?,
      sizeFrom: (json['sizeFrom'] as num?)?.toDouble(),
      sizeTo: (json['sizeTo'] as num?)?.toDouble(),
      siSymbol: json['siSymbol'] as String?,
      siFactor: (json['siFactor'] as num?)?.toDouble(),
      piecesFrom: (json['piecesFrom'] as num?)?.toInt(),
      piecesTo: (json['piecesTo'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    if (isEmpty) return 'Quantity(leer)';
    final size = sizeFrom == sizeTo || sizeTo == null
        ? '${sizeFrom ?? ''}'
        : '$sizeFrom-$sizeTo';
    return 'Quantity($size ${unitSymbol ?? ''})'.replaceAll('  ', ' ');
  }
}
