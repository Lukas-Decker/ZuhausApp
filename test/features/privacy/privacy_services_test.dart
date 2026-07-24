import 'package:drift/drift.dart' show Variable, UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/app_info.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';
import 'package:multiapp/features/privacy/data/audit_service.dart';
import 'package:multiapp/features/privacy/data/data_export_service.dart';
import 'package:multiapp/features/privacy/data/retention_service.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InventoryRepository inventory;

  setUp(() {
    db = createTestDatabase();
    inventory = InventoryRepository(db);
  });

  tearDown(() => db.close());

  Future<String> firstInventoryId() async {
    final rows = await db.customSelect('SELECT id FROM inventory_items').get();
    return rows.first.data['id'] as String;
  }

  Future<void> markDeleted(String id, {required int daysAgo, required bool synced}) async {
    final seconds =
        DateTime.now().subtract(Duration(days: daysAgo)).millisecondsSinceEpoch ~/
        1000;
    await db.customUpdate(
      'UPDATE inventory_items SET deleted_at = ?, is_dirty = ? WHERE id = ?',
      variables: [
        Variable<int>(seconds),
        Variable<int>(synced ? 0 : 1),
        Variable<String>(id),
      ],
      updateKind: UpdateKind.update,
    );
  }

  group('DataExportService', () {
    test('build enthaelt alle Tabellen und die Zeilen', () async {
      await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Milch',
        quantity: 2,
        unit: 'piece',
      );

      final export = await DataExportService(db).build(appVersion: '0.12.0');

      expect(export['app'], appName);
      expect(export['version'], '0.12.0');
      final tables = export['tables'] as Map<String, dynamic>;
      // Jede Datentabelle ist vertreten, auch die leeren.
      for (final t in AppDatabase.dataTables) {
        expect(tables.containsKey(t), isTrue, reason: t);
      }
      final items = tables['inventory_items'] as List;
      expect(items, hasLength(1));
      expect((items.first as Map)['name'], 'Milch');
    });
  });

  group('RetentionService', () {
    test('entfernt alte, synchronisierte Grabsteine', () async {
      await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Alt',
        quantity: 1,
        unit: 'piece',
      );
      final id = await firstInventoryId();
      await markDeleted(id, daysAgo: 200, synced: true);

      final removed = await RetentionService(db).purge(90);

      expect(removed, 1);
      final rows = await db.customSelect('SELECT id FROM inventory_items').get();
      expect(rows, isEmpty);
    });

    test('behaelt frische und noch nicht synchronisierte Grabsteine', () async {
      // Frisch geloescht (innerhalb der Frist), synchronisiert.
      await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Frisch',
        quantity: 1,
        unit: 'piece',
      );
      final freshId = await firstInventoryId();
      await markDeleted(freshId, daysAgo: 2, synced: true);

      // Alt geloescht, aber noch nicht hochgeladen (is_dirty = 1).
      await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'AltDirty',
        quantity: 1,
        unit: 'piece',
      );
      final dirtyRows = await db
          .customSelect("SELECT id FROM inventory_items WHERE name = 'AltDirty'")
          .get();
      await markDeleted(dirtyRows.first.data['id'] as String, daysAgo: 200, synced: false);

      final removed = await RetentionService(db).purge(90);

      expect(removed, 0);
      final rows = await db.customSelect('SELECT id FROM inventory_items').get();
      expect(rows, hasLength(2));
    });

    test('bei 0 Tagen wird nichts entfernt', () async {
      await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Egal',
        quantity: 1,
        unit: 'piece',
      );
      final id = await firstInventoryId();
      await markDeleted(id, daysAgo: 9999, synced: true);

      expect(await RetentionService(db).purge(0), 0);
    });
  });

  group('AuditService', () {
    test('log schreibt einen Eintrag, watchRecent liest ihn', () async {
      final service = AuditService(db);
      await service.log(
        scope: personalScope,
        entityType: 'consent',
        action: 'accept',
        summary: 'Test bestaetigt',
        actorName: 'Lukas',
      );

      final entries = await service.watchRecent().first;
      expect(entries, hasLength(1));
      expect(entries.first.summary, 'Test bestaetigt');
      expect(entries.first.action, 'accept');
      expect(entries.first.actorName, 'Lukas');
    });
  });
}
