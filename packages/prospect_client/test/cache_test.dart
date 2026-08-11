import 'dart:io';

import 'package:prospect_client/prospect_client.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileCacheStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('prospect_cache_test');
    store = FileCacheStore(dir);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('FileCacheStore', () {
    test('schreibt und liest einen Eintrag vollstaendig zurueck', () async {
      final entry = CacheEntry(
        body: '{"ok":true}',
        storedAt: DateTime.utc(2026, 8, 10, 12),
        expiresAt: DateTime.utc(2026, 8, 10, 18),
        etag: 'W/"abc"',
        lastModified: 'Mon, 10 Aug 2026 10:00:00 GMT',
      );
      await store.write('https://example.test/a?b=c', entry);

      final read = await store.read('https://example.test/a?b=c');
      expect(read, isNotNull);
      expect(read!.body, '{"ok":true}');
      expect(read.etag, 'W/"abc"');
      expect(read.lastModified, 'Mon, 10 Aug 2026 10:00:00 GMT');
      expect(read.expiresAt, DateTime.utc(2026, 8, 10, 18));
    });

    test('liefert null fuer unbekannte Schluessel', () async {
      expect(await store.read('gibt-es-nicht'), isNull);
    });

    test('haelt Schluessel mit URL-Sonderzeichen auseinander', () async {
      // Schluessel sind vollstaendige URLs. Query-Parameter unterscheiden
      // Abfragen, die sonst dieselbe Datei traefen.
      const a = 'https://squid-api.tjek.com/v2/catalogs?dealer_id=A&limit=100';
      const b = 'https://squid-api.tjek.com/v2/catalogs?dealer_id=B&limit=100';
      await store.write(a, _entry('erste'));
      await store.write(b, _entry('zweite'));

      expect((await store.read(a))!.body, 'erste');
      expect((await store.read(b))!.body, 'zweite');
    });

    test('behandelt eine beschaedigte Datei wie einen Cache-Miss', () async {
      await store.write('key', _entry('gut'));
      // Simuliert einen abgebrochenen Schreibvorgang.
      for (final file in dir.listSync().whereType<File>()) {
        file.writeAsStringSync('{ kaputt');
      }
      expect(await store.read('key'), isNull);
      // Der defekte Eintrag wird dabei entfernt.
      expect(await store.read('key'), isNull);
    });

    test('erkennt Frische anhand von expiresAt', () {
      final expired = CacheEntry(
        body: '{}',
        storedAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      );
      expect(expired.isFreshAt(DateTime.utc(2026, 1, 1, 12)), isTrue);
      expect(expired.isFreshAt(DateTime.utc(2026, 1, 3)), isFalse);

      final eternal =
          CacheEntry(body: '{}', storedAt: DateTime.utc(2026, 1, 1));
      expect(eternal.isFreshAt(DateTime.utc(2030, 1, 1)), isTrue);
    });

    test('loescht mit expiredOnly nur abgelaufene Eintraege', () async {
      await store.write(
        'frisch',
        CacheEntry(
          body: 'a',
          storedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      await store.write(
        'alt',
        CacheEntry(
          body: 'b',
          storedAt: DateTime.now().subtract(const Duration(days: 2)),
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      await store.clear(expiredOnly: true);
      expect(await store.read('frisch'), isNotNull);
      expect(await store.read('alt'), isNull);
    });

    test('leert bei clear alles', () async {
      await store.write('a', _entry('x'));
      await store.write('b', _entry('y'));
      await store.clear();
      expect((await store.stats()).entryCount, 0);
    });

    test('zaehlt Eintraege, abgelaufene und Groesse', () async {
      await store.write('a', _entry('x'));
      await store.write(
        'b',
        CacheEntry(
          body: 'y',
          storedAt: DateTime.now(),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      final stats = await store.stats();
      expect(stats.entryCount, 2);
      expect(stats.expiredCount, 1);
      expect(stats.totalBytes, greaterThan(0));
    });

    test('scheitert nicht an einem noch nicht angelegten Verzeichnis', () async {
      final missing = FileCacheStore(
        Directory('${dir.path}${Platform.pathSeparator}tief${Platform.pathSeparator}drin'),
      );
      expect(await missing.read('x'), isNull);
      expect((await missing.stats()).entryCount, 0);
      await missing.write('x', _entry('ok'));
      expect((await missing.read('x'))!.body, 'ok');
    });

    test('verkraftet sehr lange Schluessel', () async {
      // Windows begrenzt Pfadlaengen. Lange Query-Strings duerfen den Cache
      // nicht sprengen.
      final key = 'https://example.test/?q=${'x' * 500}';
      await store.write(key, _entry('lang'));
      expect((await store.read(key))!.body, 'lang');
    });
  });

  group('MemoryCacheStore', () {
    test('verhaelt sich wie der Dateicache', () async {
      final memory = MemoryCacheStore();
      await memory.write('a', _entry('x'));
      expect((await memory.read('a'))!.body, 'x');
      await memory.evict('a');
      expect(await memory.read('a'), isNull);
    });
  });

  group('NullCacheStore', () {
    test('speichert nichts', () async {
      const nothing = NullCacheStore();
      await nothing.write('a', _entry('x'));
      expect(await nothing.read('a'), isNull);
      expect((await nothing.stats()).entryCount, 0);
    });
  });

  group('CacheEntry', () {
    test('meldet Revalidierbarkeit nur mit Validator', () {
      expect(_entry('x').canRevalidate, isFalse);
      expect(
        CacheEntry(body: 'x', storedAt: DateTime.now(), etag: 'e').canRevalidate,
        isTrue,
      );
    });

    test('behaelt beim Auffrischen den Koerper und die Validatoren', () {
      final entry = CacheEntry(
        body: 'original',
        storedAt: DateTime.utc(2026, 1, 1),
        etag: 'e',
      );
      final refreshed = entry.refreshed(
        DateTime.utc(2026, 6, 1),
        ttl: const Duration(hours: 6),
      );
      expect(refreshed.body, 'original');
      expect(refreshed.etag, 'e');
      expect(refreshed.expiresAt, DateTime.utc(2026, 6, 1, 6));
    });
  });
}

CacheEntry _entry(String body) =>
    CacheEntry(body: body, storedAt: DateTime.now());
