import 'package:meta/meta.dart';

import 'image_set.dart';
import 'price.dart';

/// Ein einzelnes Angebot aus einem Prospekt.
///
/// [price] ist bewusst optional: Schwarz/Kaufland liefert 422 Produkte pro
/// Prospekt, aber ohne jeden Preis. Ein Angebot ohne Preis ist ein gueltiger
/// Zustand, kein Fehler.
@immutable
class Offer {
  const Offer({
    required this.id,
    required this.title,
    this.description,
    this.brand,
    this.price,
    this.quantity,
    this.image = ImageSet.empty,
    this.pageNumber,
    this.categories = const [],
    this.link,
    this.externalProductId,
    this.validFrom,
    this.validUntil,
  });

  /// Innerhalb einer Quelle eindeutig, nicht quellenuebergreifend.
  final String id;

  final String title;
  final String? description;
  final String? brand;

  /// Null, wenn die Quelle fuer dieses Produkt keinen Preis liefert.
  final Price? price;

  final Quantity? quantity;
  final ImageSet image;

  /// Seite im Prospekt, 1-basiert. Null, wenn die Quelle sie nicht angibt.
  final int? pageNumber;

  /// Flache Kategorieliste. Hierarchien werden zu Pfadsegmenten aufgeloest.
  final List<String> categories;

  /// Weiterfuehrender Link, meist auf den Onlineshop des Haendlers.
  final Uri? link;

  /// Artikelnummer beim Haendler, z.B. Kaufland `00014395`, Lidl `100387899`.
  /// Nuetzlich, um dasselbe Produkt ueber mehrere Prospekte zu verfolgen.
  final String? externalProductId;

  /// Eigener Gueltigkeitszeitraum des Angebots.
  ///
  /// Kann vom Zeitraum des Prospekts abweichen: Marktguru fuehrt Angebote mit
  /// kuerzerer Laufzeit, etwa Wochenend- oder Tagesaktionen innerhalb eines
  /// Wochenprospekts. Null, wenn die Quelle nichts angibt, dann gilt der
  /// Zeitraum des Prospekts.
  final DateTime? validFrom;
  final DateTime? validUntil;

  bool get hasPrice => price != null;

  bool isExpiredAt(DateTime now) {
    final until = validUntil;
    return until != null && now.isAfter(until);
  }

  Offer copyWith({int? pageNumber, ImageSet? image}) => Offer(
        id: id,
        title: title,
        description: description,
        brand: brand,
        price: price,
        quantity: quantity,
        image: image ?? this.image,
        pageNumber: pageNumber ?? this.pageNumber,
        categories: categories,
        link: link,
        externalProductId: externalProductId,
        validFrom: validFrom,
        validUntil: validUntil,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (brand != null) 'brand': brand,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!.toJson(),
        if (!image.isEmpty) 'image': image.toJson(),
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (categories.isNotEmpty) 'categories': categories,
        if (link != null) 'link': link.toString(),
        if (externalProductId != null) 'externalProductId': externalProductId,
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
      };

  static Offer fromJson(Map<String, Object?> json) => Offer(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        brand: json['brand'] as String?,
        price: Price.fromJson(json['price'] as Map<String, Object?>?),
        quantity: Quantity.fromJson(json['quantity'] as Map<String, Object?>?),
        image: json['image'] == null
            ? ImageSet.empty
            : ImageSet.fromJson(json['image']! as Map<String, Object?>),
        pageNumber: (json['pageNumber'] as num?)?.toInt(),
        categories:
            (json['categories'] as List?)?.whereType<String>().toList() ??
                const [],
        link: json['link'] is String ? Uri.tryParse(json['link']! as String) : null,
        externalProductId: json['externalProductId'] as String?,
        validFrom: _date(json['validFrom']),
        validUntil: _date(json['validUntil']),
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  String toString() =>
      'Offer($title${price != null ? ', ${price!.current.toStringAsFixed(2)}' : ', ohne Preis'})';
}
