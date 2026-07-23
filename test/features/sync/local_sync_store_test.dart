import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';
import 'package:multiapp/features/sync/local_sync_store.dart';

import '../../helpers/test_database.dart';

/// Liest die Rohdaten einer Inventar-Zeile (inkl. Sync-Spalten) als Map.
Future<Map<String, dynamic>> _rawItem(AppDatabase db, String id) async {
  final rows = await db
      .customSelect('SELECT * FROM inventory_items WHERE id = ?',
          variables: [Variable<String>(id)])
      .get();
  return Map<String, dynamic>.from(rows.single.data);
}

void main() {
  late AppDatabase db;
  late LocalSyncStore store;
  late InventoryRepository inventory;

  setUp(() {
    db = createTestDatabase();
    store = LocalSyncStore(db);
    inventory = InventoryRepository(db);
  });

  tearDown(() => db.close());

  group('applyRemote LWW', () {
    test('neuerer Server-Stand ueberschreibt, aelterer nicht', () async {
      final id = await inventory.addItem(
        scope: personalScope,
        userId: 'u1',
        name: 'Milch',
        quantity: 1,
        unit: 'liter',
      );
      final raw = await _rawItem(db, id);
      final localUpdated = raw['updated_at'] as int;

      // Aelterer Server-Stand: darf NICHT ueberschreiben.
      await store.applyRemote('inventory_items', {
        ...raw,
        'name': 'Alt',
        'updated_at': localUpdated - 100,
      });
      expect((await _rawItem(db, id))['name'], 'Milch');

      // Neuerer Server-Stand: ueberschreibt.
      await store.applyRemote('inventory_items', {
        ...raw,
        'name': 'Neu',
        'updated_at': localUpdated + 100,
      });
      expect((await _rawItem(db, id))['name'], 'Neu');
    });

    test('unbekannter Server-Datensatz wird eingefuegt', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await store.applyRemote('inventory_items', {
        'id': 'remote-1',
        'scope_kind': 'personal',
        'scope_id': 'user-1',
        'name': 'Vom Server',
        'quantity': 3.0,
        'unit': 'piece',
        'remind_on_expiry': 1,
        'created_at': now,
        'updated_at': now,
      });
      final items = await inventory.watchItems(personalScope).first;
      expect(items.map((e) => e.item.name), contains('Vom Server'));
    });

    test('applyRemote markiert die Zeile als sauber (is_dirty=0)', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await store.applyRemote('inventory_items', {
        'id': 'remote-2',
        'scope_kind': 'personal',
        'scope_id': 'user-1',
        'name': 'Server',
        'quantity': 1.0,
        'unit': 'piece',
        'remind_on_expiry': 1,
        'created_at': now,
        'updated_at': now,
      });
      final raw = await _rawItem(db, 'remote-2');
      expect(raw['is_dirty'], 0);
    });
  });

  group('Outbox', () {
    test('pendingDeltas summiert je Feld und liefert die IDs', () async {
      await db.logCounterDelta(
        table: 'inventory_items',
        rowId: 'x',
        field: 'quantity',
        delta: -2,
      );
      await db.logCounterDelta(
        table: 'inventory_items',
        rowId: 'x',
        field: 'quantity',
        delta: -1,
      );
      final result = await store.pendingDeltas('inventory_items', 'x');
      expect(result.values['quantity'], -3);
      expect(result.ids, hasLength(2));

      await store.clearOutbox(result.ids);
      final after = await store.pendingDeltas('inventory_items', 'x');
      expect(after.values, isEmpty);
    });
  });

  group('Meta', () {
    test('speichert und liest den Pull-Zeitstempel', () async {
      expect(await store.getMeta('lastPull'), isNull);
      await store.setMeta('lastPull', '2026-07-23T10:00:00Z');
      expect(await store.getMeta('lastPull'), '2026-07-23T10:00:00Z');
      await store.setMeta('lastPull', '2026-07-23T11:00:00Z');
      expect(await store.getMeta('lastPull'), '2026-07-23T11:00:00Z');
    });
  });
}
