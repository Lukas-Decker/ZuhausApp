import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:multiapp/features/inventory/data/open_food_facts_service.dart';
import 'package:multiapp/features/inventory/domain/measurement_unit.dart';

OpenFoodFactsService _serviceReturning(
  Object body, {
  int status = 200,
  void Function(http.Request)? onRequest,
}) {
  return OpenFoodFactsService(
    client: MockClient((request) async {
      onRequest?.call(request);
      return http.Response.bytes(
        utf8.encode(body is String ? body : jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

void main() {
  group('parseQuantity', () {
    test('erkennt Gramm und Kilogramm', () {
      expect(
        OpenFoodFactsService.parseQuantity('500 g'),
        (amount: 500.0, unit: MeasurementUnit.gram),
      );
      expect(
        OpenFoodFactsService.parseQuantity('1 kg'),
        (amount: 1.0, unit: MeasurementUnit.kilogram),
      );
    });

    test('erkennt Komma als Dezimaltrennzeichen', () {
      expect(
        OpenFoodFactsService.parseQuantity('1,5 l'),
        (amount: 1.5, unit: MeasurementUnit.liter),
      );
    });

    test('rechnet Zentiliter in Milliliter um', () {
      expect(
        OpenFoodFactsService.parseQuantity('33 cl'),
        (amount: 330.0, unit: MeasurementUnit.milliliter),
      );
    });

    test('gibt null bei fehlender oder unlesbarer Angabe', () {
      expect(OpenFoodFactsService.parseQuantity(null), isNull);
      expect(OpenFoodFactsService.parseQuantity('Familienpackung'), isNull);
    });
  });

  group('lookup', () {
    test('liefert das Produkt und bevorzugt den deutschen Namen', () async {
      final service = _serviceReturning({
        'status': 1,
        'product': {
          'product_name': 'Whole milk',
          'product_name_de': 'Vollmilch',
          'brands': 'Weihenstephan',
          'categories': 'Dairies, Milks',
          'quantity': '1 l',
          'image_front_small_url': 'https://example.invalid/milk.jpg',
        },
      });

      final result = await service.lookup('4001234567890');

      expect(result, isNotNull);
      expect(result!.name, 'Vollmilch');
      expect(result.brand, 'Weihenstephan');
      expect(result.category, 'Milks');
      expect(result.unit, MeasurementUnit.liter);
      expect(result.quantity, 1);
    });

    test('sendet nur den Barcode und einen User-Agent', () async {
      http.Request? seen;
      final service = _serviceReturning(
        {'status': 0},
        onRequest: (request) => seen = request,
      );

      await service.lookup('4001234567890');

      expect(seen!.url.path, '/api/v2/product/4001234567890.json');
      expect(seen!.url.queryParameters.keys, ['fields']);
      expect(seen!.headers['User-Agent'], contains('MultiApp'));
    });

    test('liefert null bei unbekanntem Produkt', () async {
      final service = _serviceReturning({'status': 0});
      expect(await service.lookup('0000000000000'), isNull);
    });

    test('liefert null bei HTTP 404', () async {
      final service = _serviceReturning('', status: 404);
      expect(await service.lookup('0000000000000'), isNull);
    });

    test('liefert null wenn kein Name vorhanden ist', () async {
      final service = _serviceReturning({
        'status': 1,
        'product': {'brands': 'Ohne Namen'},
      });
      expect(await service.lookup('4001234567890'), isNull);
    });

    test('meldet Serverfehler als lesbare Ausnahme', () async {
      final service = _serviceReturning('', status: 500);
      expect(
        () => service.lookup('4001234567890'),
        throwsA(isA<ProductLookupException>()),
      );
    });

    test('meldet Netzwerkfehler als lesbare Ausnahme', () async {
      final service = OpenFoodFactsService(
        client: MockClient((_) async => throw const SocketExceptionStub()),
      );
      expect(
        () => service.lookup('4001234567890'),
        throwsA(
          isA<ProductLookupException>().having(
            (e) => e.message,
            'message',
            contains('Keine Verbindung'),
          ),
        ),
      );
    });
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
