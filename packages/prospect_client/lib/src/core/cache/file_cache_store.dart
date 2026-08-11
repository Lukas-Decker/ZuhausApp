import 'dart:convert';
import 'dart:io';

import '../errors/prospect_exception.dart';
import 'cache_store.dart';

/// Dateibasierter Cache. Ein JSON pro Eintrag.
///
/// Bewusst ohne Datenbank: laeuft damit unveraendert in der CLI, im Test und in
/// der Flutter-App auf allen Plattformen, ohne native Abhaengigkeit oder
/// Plattform-Setup. Das Verzeichnis wird von aussen hereingereicht, damit die
/// Kernlogik nichts ueber Flutter oder `path_provider` wissen muss.
class FileCacheStore implements CacheStore {
  FileCacheStore(this.directory);

  /// Legt den Cache unterhalb des Systemtemp-Verzeichnisses an. Fuer CLI-Nutzung.
  factory FileCacheStore.temporary({String name = 'prospect_client'}) =>
      FileCacheStore(Directory('${Directory.systemTemp.path}/$name'));

  final Directory directory;

  bool _ensured = false;

  Future<void> _ensureDirectory() async {
    if (_ensured) return;
    try {
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      _ensured = true;
    } on FileSystemException catch (e) {
      throw ConfigurationError(
        'Cache-Verzeichnis ${directory.path} ist nicht nutzbar: ${e.message}',
        cause: e,
      );
    }
  }

  /// Dateiname aus dem Schluessel. Der Schluessel selbst enthaelt URLs und
  /// damit Zeichen, die in Dateinamen nicht zulaessig sind, deshalb wird er
  /// base64url-kodiert. Bleibt eindeutig und umkehrbar.
  File _fileFor(String key) {
    final encoded = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    // Sehr lange Schluessel wuerden auf Windows das Pfadlimit reissen.
    final name = encoded.length <= 120
        ? encoded
        : '${encoded.substring(0, 100)}_${key.hashCode.toRadixString(16)}';
    return File('${directory.path}${Platform.pathSeparator}$name.json');
  }

  @override
  Future<CacheEntry?> read(String key) async {
    final file = _fileFor(key);
    try {
      if (!file.existsSync()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) return null;
      return CacheEntry.fromJson(decoded);
    } on FormatException {
      // Beschaedigter Eintrag: entfernen und wie einen Cache-Miss behandeln.
      await _deleteQuietly(file);
      return null;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String key, CacheEntry entry) async {
    await _ensureDirectory();
    final file = _fileFor(key);
    try {
      // Erst in eine temporaere Datei, dann umbenennen. Verhindert halb
      // geschriebene Eintraege, wenn der Prozess mittendrin endet.
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(entry.toJson()), flush: true);
      await temp.rename(file.path);
    } on FileSystemException {
      // Ein nicht schreibbarer Cache darf die Abfrage nicht scheitern lassen.
    }
  }

  @override
  Future<void> evict(String key) => _deleteQuietly(_fileFor(key));

  @override
  Future<void> clear({bool expiredOnly = false}) async {
    if (!directory.existsSync()) return;
    final now = DateTime.now();
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      if (!expiredOnly) {
        await _deleteQuietly(entity);
        continue;
      }
      final entry = await _readFile(entity);
      if (entry == null || !entry.isFreshAt(now)) {
        await _deleteQuietly(entity);
      }
    }
  }

  @override
  Future<CacheStats> stats() async {
    if (!directory.existsSync()) {
      return const CacheStats(entryCount: 0, expiredCount: 0, totalBytes: 0);
    }
    final now = DateTime.now();
    var count = 0;
    var expired = 0;
    var bytes = 0;
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      count++;
      bytes += await entity.length();
      final entry = await _readFile(entity);
      if (entry == null || !entry.isFreshAt(now)) expired++;
    }
    return CacheStats(
      entryCount: count,
      expiredCount: expired,
      totalBytes: bytes,
    );
  }

  Future<CacheEntry?> _readFile(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, Object?> ? CacheEntry.fromJson(decoded) : null;
    } on Object {
      return null;
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Ignorieren, ein nicht loeschbarer Eintrag ist kein Abbruchgrund.
    }
  }
}
