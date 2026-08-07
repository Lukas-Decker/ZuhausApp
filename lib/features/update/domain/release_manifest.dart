import 'package:flutter/foundation.dart';

/// Eine Version im Format major.minor.patch (eine angehängte Build-Nummer
/// nach dem "+" wird mitgelesen, entscheidet aber erst als letztes Kriterium).
@immutable
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, [this.build = 0]);

  final int major;
  final int minor;
  final int patch;
  final int build;

  /// Liest "0.21.0", "0.21.0+39" oder "v0.21" ein. Fehlende Stellen zählen
  /// als 0. Gibt `null` zurück, wenn gar keine Zahl zu erkennen ist.
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('v') || text.startsWith('V')) text = text.substring(1);

    final plus = text.indexOf('+');
    final build = plus >= 0 ? int.tryParse(text.substring(plus + 1)) ?? 0 : 0;
    if (plus >= 0) text = text.substring(0, plus);

    final parts = text.split('.');
    final numbers = <int>[];
    for (final part in parts.take(3)) {
      final digits = RegExp(r'\d+').firstMatch(part)?.group(0);
      if (digits == null) break;
      numbers.add(int.parse(digits));
    }
    if (numbers.isEmpty) return null;
    return AppVersion(
      numbers[0],
      numbers.length > 1 ? numbers[1] : 0,
      numbers.length > 2 ? numbers[2] : 0,
      build,
    );
  }

  @override
  int compareTo(AppVersion other) {
    final byMajor = major.compareTo(other.major);
    if (byMajor != 0) return byMajor;
    final byMinor = minor.compareTo(other.minor);
    if (byMinor != 0) return byMinor;
    final byPatch = patch.compareTo(other.patch);
    if (byPatch != 0) return byPatch;
    return build.compareTo(other.build);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      other.build == build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Eine herunterladbare Datei eines Releases (APK bzw. Windows-ZIP).
@immutable
class ReleaseAsset {
  const ReleaseAsset({
    required this.url,
    required this.fileName,
    this.sizeBytes,
    this.sha256,
  });

  final Uri url;
  final String fileName;
  final int? sizeBytes;

  /// Prüfsumme der Datei (hex, klein geschrieben). Fehlt sie, wird nach dem
  /// Download nicht geprüft.
  final String? sha256;

  static ReleaseAsset? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final url = Uri.tryParse('${raw['url'] ?? ''}');
    if (url == null || !url.hasScheme) return null;
    final name = '${raw['file'] ?? ''}'.trim();
    return ReleaseAsset(
      url: url,
      fileName: _safeFileName(
        name.isNotEmpty
            ? name
            : (url.pathSegments.isNotEmpty
                  ? url.pathSegments.last
                  : 'update.bin'),
      ),
      sizeBytes: (raw['size'] as num?)?.toInt(),
      sha256: '${raw['sha256'] ?? ''}'.trim().toLowerCase().isEmpty
          ? null
          : '${raw['sha256']}'.trim().toLowerCase(),
    );
  }

  /// Aus dem Manifest darf kein Pfad werden: der Name landet direkt im
  /// Zwischenspeicher, also bleiben nur harmlose Zeichen stehen.
  static String _safeFileName(String raw) {
    final base = raw.split(RegExp(r'[\\/]')).last;
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty || cleaned.startsWith('.') ? 'update.bin' : cleaned;
  }
}

/// Das Manifest, das auf dem Server liegt und die aktuelle Version beschreibt.
@immutable
class ReleaseManifest {
  const ReleaseManifest({
    required this.latest,
    this.minimum,
    this.notes,
    this.publishedAt,
    this.assets = const {},
    this.androidAbis = const {},
  });

  /// Neueste veröffentlichte Version.
  final AppVersion latest;

  /// Kleinste noch erlaubte Version. Wer darunter liegt, bekommt ein
  /// Pflicht-Update, das sich nicht wegklicken lässt.
  final AppVersion? minimum;

  /// Änderungen dieser Version, eine Zeile pro Punkt.
  final String? notes;

  final DateTime? publishedAt;

  /// Pakete je Plattform: 'android' (universelle APK) und 'windows'.
  final Map<String, ReleaseAsset> assets;

  /// Android-Pakete je Prozessorart, z. B. 'arm64-v8a'.
  ///
  /// Eine APK für alle Prozessorarten waere fast dreimal so gross, deshalb
  /// wird pro ABI eine gebaut und das Geraet sucht sich die passende.
  final Map<String, ReleaseAsset> androidAbis;

  /// Sucht das Paket für diese Plattform.
  ///
  /// [abis] ist die Vorzugsliste des Geraets (beste zuerst, aus
  /// Build.SUPPORTED_ABIS). Passt keine, bleibt die universelle APK als
  /// Rueckfall, sofern das Manifest eine hat.
  ReleaseAsset? assetFor(String platform, {List<String> abis = const []}) {
    if (platform == 'android') {
      for (final abi in abis) {
        final match = androidAbis[abi];
        if (match != null) return match;
      }
      return assets['android'];
    }
    return assets[platform];
  }

  factory ReleaseManifest.fromJson(Map<String, dynamic> json) {
    final latest = AppVersion.tryParse('${json['latestVersion'] ?? ''}');
    if (latest == null) {
      throw const FormatException('Manifest ohne gültiges Feld latestVersion.');
    }

    final assets = <String, ReleaseAsset>{};
    final windows = ReleaseAsset.fromJson(json['windows']);
    if (windows != null) assets['windows'] = windows;

    // Der Android-Block ist entweder ein einzelnes Paket (dann steht dort
    // eine url) oder eine Liste je Prozessorart.
    final androidAbis = <String, ReleaseAsset>{};
    final android = json['android'];
    if (android is Map) {
      if (android['url'] != null) {
        final single = ReleaseAsset.fromJson(android);
        if (single != null) assets['android'] = single;
      } else {
        for (final entry in android.entries) {
          final asset = ReleaseAsset.fromJson(entry.value);
          if (asset != null) androidAbis['${entry.key}'] = asset;
        }
      }
    }

    final notes = '${json['notes'] ?? ''}'.trim();
    return ReleaseManifest(
      latest: latest,
      minimum: AppVersion.tryParse('${json['minVersion'] ?? ''}'),
      notes: notes.isEmpty ? null : notes,
      publishedAt: DateTime.tryParse('${json['publishedAt'] ?? ''}')?.toLocal(),
      assets: assets,
      androidAbis: androidAbis,
    );
  }
}

/// Ergebnis einer Prüfung: nichts zu tun, Update möglich oder Pflicht.
enum UpdateAvailability {
  none,
  optional,
  required;

  bool get hasUpdate => this != UpdateAvailability.none;
  bool get isRequired => this == UpdateAvailability.required;
}

/// Vergleicht die laufende Version mit dem Manifest.
///
/// Ohne passendes Paket ([asset] ist null) gibt es nichts zu installieren,
/// also auch keine Meldung. Ein Pflicht-Update entsteht nur, wenn es
/// tatsächlich eine neuere Version zum Installieren gibt.
UpdateAvailability evaluateUpdate({
  required AppVersion current,
  required ReleaseManifest manifest,
  required ReleaseAsset? asset,
}) {
  if (asset == null) return UpdateAvailability.none;
  if (!(current < manifest.latest)) return UpdateAvailability.none;
  final minimum = manifest.minimum;
  if (minimum != null && current < minimum) return UpdateAvailability.required;
  return UpdateAvailability.optional;
}
