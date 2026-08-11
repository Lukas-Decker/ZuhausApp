import 'package:meta/meta.dart';

/// Ein zwischengespeicherter HTTP-Antwortkoerper mit Validierungsmetadaten.
@immutable
class CacheEntry {
  const CacheEntry({
    required this.body,
    required this.storedAt,
    this.expiresAt,
    this.etag,
    this.lastModified,
  });

  final String body;
  final DateTime storedAt;

  /// Ab wann der Eintrag als veraltet gilt. Null bedeutet: nie ablaufen.
  final DateTime? expiresAt;

  /// ETag der Quelle, fuer bedingte Requests per `If-None-Match`.
  final String? etag;

  /// `Last-Modified` der Quelle, fuer `If-Modified-Since`.
  final String? lastModified;

  bool isFreshAt(DateTime now) {
    final expires = expiresAt;
    return expires == null || now.isBefore(expires);
  }

  /// True, wenn ein bedingter Request moeglich ist. Spart bei 304 den Body.
  bool get canRevalidate => etag != null || lastModified != null;

  CacheEntry refreshed(DateTime now, {Duration? ttl}) => CacheEntry(
        body: body,
        storedAt: now,
        expiresAt: ttl == null ? expiresAt : now.add(ttl),
        etag: etag,
        lastModified: lastModified,
      );

  Map<String, Object?> toJson() => {
        'body': body,
        'storedAt': storedAt.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (etag != null) 'etag': etag,
        if (lastModified != null) 'lastModified': lastModified,
      };

  static CacheEntry? fromJson(Map<String, Object?> json) {
    final body = json['body'];
    final storedAt = json['storedAt'];
    if (body is! String || storedAt is! String) return null;
    final stored = DateTime.tryParse(storedAt);
    if (stored == null) return null;
    return CacheEntry(
      body: body,
      storedAt: stored,
      expiresAt: json['expiresAt'] is String
          ? DateTime.tryParse(json['expiresAt']! as String)
          : null,
      etag: json['etag'] as String?,
      lastModified: json['lastModified'] as String?,
    );
  }
}

/// Statistik ueber den Cache, fuer `prospect_client cache stats`.
@immutable
class CacheStats {
  const CacheStats({
    required this.entryCount,
    required this.expiredCount,
    required this.totalBytes,
  });

  final int entryCount;
  final int expiredCount;
  final int totalBytes;

  @override
  String toString() =>
      'CacheStats($entryCount Eintraege, davon $expiredCount abgelaufen, '
      '${(totalBytes / 1024).toStringAsFixed(1)} KiB)';
}

/// Persistenz fuer zwischengespeicherte Antworten.
///
/// Bewusst ein Interface: die CLI, die Tests und die Flutter-App bekommen
/// jeweils die passende Implementierung, die Kernlogik bleibt identisch.
abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);

  Future<void> write(String key, CacheEntry entry);

  Future<void> evict(String key);

  /// Loescht alles, oder mit [expiredOnly] nur abgelaufene Eintraege.
  Future<void> clear({bool expiredOnly = false});

  Future<CacheStats> stats();
}

/// Cache, der nichts speichert. Fuer Tests und `--no-cache`.
class NullCacheStore implements CacheStore {
  const NullCacheStore();

  @override
  Future<CacheEntry?> read(String key) async => null;

  @override
  Future<void> write(String key, CacheEntry entry) async {}

  @override
  Future<void> evict(String key) async {}

  @override
  Future<void> clear({bool expiredOnly = false}) async {}

  @override
  Future<CacheStats> stats() async =>
      const CacheStats(entryCount: 0, expiredCount: 0, totalBytes: 0);
}

/// Cache im Arbeitsspeicher. Ueberlebt den Prozess nicht.
class MemoryCacheStore implements CacheStore {
  MemoryCacheStore();

  final Map<String, CacheEntry> _entries = {};

  @override
  Future<CacheEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, CacheEntry entry) async =>
      _entries[key] = entry;

  @override
  Future<void> evict(String key) async => _entries.remove(key);

  @override
  Future<void> clear({bool expiredOnly = false}) async {
    if (!expiredOnly) {
      _entries.clear();
      return;
    }
    final now = DateTime.now();
    _entries.removeWhere((_, entry) => !entry.isFreshAt(now));
  }

  @override
  Future<CacheStats> stats() async {
    final now = DateTime.now();
    var expired = 0;
    var bytes = 0;
    for (final entry in _entries.values) {
      if (!entry.isFreshAt(now)) expired++;
      bytes += entry.body.length;
    }
    return CacheStats(
      entryCount: _entries.length,
      expiredCount: expired,
      totalBytes: bytes,
    );
  }
}
