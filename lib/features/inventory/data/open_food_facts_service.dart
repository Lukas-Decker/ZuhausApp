import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/measurement_unit.dart';

/// Ergebnis einer Produktabfrage.
class ProductLookupResult {
  const ProductLookupResult({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.category,
    this.unit = MeasurementUnit.piece,
    this.quantity = 1,
  });

  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? category;
  final MeasurementUnit unit;
  final double quantity;
}

/// Fehler bei der Produktabfrage, mit einer Meldung für die Oberfläche.
class ProductLookupException implements Exception {
  const ProductLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fragt Produktdaten bei Open Food Facts ab.
///
/// Übertragen wird ausschließlich der gescannte Barcode. Die Abfrage findet
/// nur statt, wenn die Nutzerin oder der Nutzer vorher eingewilligt hat.
class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client, this.appVersion = '0.2.0'})
    : _client = client ?? http.Client();

  static const _host = 'world.openfoodfacts.org';
  static const _fields =
      'product_name,product_name_de,brands,image_front_small_url,'
      'categories,quantity';

  final http.Client _client;
  final String appVersion;

  /// Liefert `null`, wenn der Barcode dort nicht bekannt ist.
  Future<ProductLookupResult?> lookup(String barcode) async {
    final uri = Uri.https(_host, '/api/v2/product/$barcode.json', {
      'fields': _fields,
    });

    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'MultiApp/$appVersion (Flutter)'})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ProductLookupException(
        'Keine Verbindung zur Produktdatenbank. Du kannst das Produkt '
        'trotzdem von Hand anlegen.',
      );
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw ProductLookupException(
        'Produktdatenbank antwortet nicht (${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const ProductLookupException('Unerwartete Antwort der Produktdatenbank.');
    }

    if (body['status'] != 1) return null;
    final product = body['product'];
    if (product is! Map<String, dynamic>) return null;

    final name = _firstNonEmpty([
      product['product_name_de'],
      product['product_name'],
    ]);
    if (name == null) return null;

    final parsed = parseQuantity(product['quantity'] as String?);

    return ProductLookupResult(
      barcode: barcode,
      name: name,
      brand: _firstNonEmpty([product['brands']]),
      imageUrl: _firstNonEmpty([product['image_front_small_url']]),
      category: _firstCategory(product['categories'] as String?),
      unit: parsed?.unit ?? MeasurementUnit.piece,
      quantity: parsed?.amount ?? 1,
    );
  }

  void dispose() => _client.close();

  static String? _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _firstCategory(String? categories) {
    if (categories == null || categories.trim().isEmpty) return null;
    return categories.split(',').last.trim();
  }

  /// Zerlegt Angaben wie "500 g", "1,5 l" oder "6 x 0.33 l".
  static ({double amount, MeasurementUnit unit})? parseQuantity(String? raw) {
    if (raw == null) return null;
    final match = RegExp(
      r'([\d]+(?:[.,]\d+)?)\s*(kg|g|ml|cl|l|st(?:ü|ue)ck|stk)\b',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return null;

    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (amount == null) return null;

    return switch (match.group(2)!.toLowerCase()) {
      'kg' => (amount: amount, unit: MeasurementUnit.kilogram),
      'g' => (amount: amount, unit: MeasurementUnit.gram),
      'ml' => (amount: amount, unit: MeasurementUnit.milliliter),
      'cl' => (amount: amount * 10, unit: MeasurementUnit.milliliter),
      'l' => (amount: amount, unit: MeasurementUnit.liter),
      _ => (amount: amount, unit: MeasurementUnit.piece),
    };
  }
}
