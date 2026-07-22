import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';
import 'package:multiapp/features/inventory/domain/measurement_unit.dart';

InventoryEntry _entry({
  double quantity = 1,
  double? minQuantity,
  DateTime? expiresAt,
}) {
  final now = DateTime.now();
  return InventoryEntry(
    item: InventoryItem(
      id: 'i1',
      scopeKind: 'personal',
      scopeId: 'u1',
      name: 'Milch',
      quantity: quantity,
      unit: 'liter',
      minQuantity: minQuantity,
      expiresAt: expiresAt,
      remindOnExpiry: true,
      createdAt: now,
      updatedAt: now,
      isDirty: false,
    ),
  );
}

DateTime _inDays(int days) => DateTime.now().add(Duration(days: days));

void main() {
  group('InventoryEntry Mindestbestand', () {
    test('ohne Mindestbestand nie knapp', () {
      expect(_entry(quantity: 0).isLow, isFalse);
    });

    test('knapp sobald der Mindestbestand erreicht ist', () {
      expect(_entry(quantity: 2, minQuantity: 2).isLow, isTrue);
      expect(_entry(quantity: 1, minQuantity: 2).isLow, isTrue);
      expect(_entry(quantity: 3, minQuantity: 2).isLow, isFalse);
    });
  });

  group('InventoryEntry Ablauf', () {
    test('ohne Datum keine Angabe', () {
      final entry = _entry();
      expect(entry.daysUntilExpiry, isNull);
      expect(entry.isExpired, isFalse);
      expect(entry.expiresWithin(5), isFalse);
    });

    test('heute ablaufend zählt als 0 Tage und nicht als abgelaufen', () {
      final entry = _entry(expiresAt: _inDays(0));
      expect(entry.daysUntilExpiry, 0);
      expect(entry.isExpired, isFalse);
      expect(entry.expiresWithin(5), isTrue);
    });

    test('gestern abgelaufen', () {
      final entry = _entry(expiresAt: _inDays(-1));
      expect(entry.daysUntilExpiry, -1);
      expect(entry.isExpired, isTrue);
      expect(entry.expiresWithin(5), isFalse);
    });

    test('Vorwarnfenster ist inklusiv', () {
      expect(_entry(expiresAt: _inDays(5)).expiresWithin(5), isTrue);
      expect(_entry(expiresAt: _inDays(6)).expiresWithin(5), isFalse);
    });

    test('Uhrzeit spielt keine Rolle, nur der Kalendertag', () {
      final today = DateTime.now();
      final lateToday = DateTime(today.year, today.month, today.day, 23, 59);
      expect(_entry(expiresAt: lateToday).daysUntilExpiry, 0);
    });
  });

  group('MeasurementUnit.format', () {
    test('ganze Zahlen ohne Nachkommastellen', () {
      expect(MeasurementUnit.piece.format(2), '2 Stk.');
    });

    test('Bruchteile mit deutschem Dezimalkomma', () {
      expect(MeasurementUnit.liter.format(1.5), '1,5 l');
    });

    test('parse fällt auf Stück zurück', () {
      expect(MeasurementUnit.parse('gibtsnicht'), MeasurementUnit.piece);
      expect(MeasurementUnit.parse(null), MeasurementUnit.piece);
      expect(MeasurementUnit.parse('kilogram'), MeasurementUnit.kilogram);
    });
  });
}
