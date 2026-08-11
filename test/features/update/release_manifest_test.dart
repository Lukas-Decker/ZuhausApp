import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/features/update/domain/release_manifest.dart';

ReleaseManifest _manifest({required String latest, String? minimum}) =>
    ReleaseManifest.fromJson({
      'latestVersion': latest,
      'minVersion': ?minimum,
      'android': {
        for (final abi in const ['arm64-v8a', 'armeabi-v7a'])
          abi: {
            'url': 'https://example.org/releases/Android-$latest-$abi.apk',
            'size': 42,
          },
      },
    });

void main() {
  group('AppVersion', () {
    test('vergleicht Zahlen, nicht Zeichenketten', () {
      final small = AppVersion.tryParse('0.9.0')!;
      final big = AppVersion.tryParse('0.10.0')!;
      expect(small < big, isTrue);
      expect(big < small, isFalse);
    });

    test('liest Build-Nummer und v-Prefix, sonst null', () {
      expect(AppVersion.tryParse('v0.21')?.toString(), '0.21.0');
      expect(AppVersion.tryParse('0.21.0+39')?.build, 39);
      expect(AppVersion.tryParse('keine Version'), isNull);
    });
  });

  group('assetFor', () {
    final manifest = _manifest(latest: '0.21.0');

    test('nimmt die erste Prozessorart, die das Geraet unterstuetzt', () {
      final asset = manifest.assetFor(
        'android',
        abis: const ['armeabi-v7a', 'arm64-v8a'],
      );
      expect(asset?.fileName, 'Android-0.21.0-armeabi-v7a.apk');
    });

    test('ohne passende Prozessorart gibt es kein Paket', () {
      expect(manifest.assetFor('android', abis: const ['mips']), isNull);
      expect(manifest.assetFor('windows'), isNull);
    });
  });

  group('changesSince', () {
    final manifest = ReleaseManifest.fromJson({
      'latestVersion': '0.24.2',
      'notes': '- neuester Punkt',
      'changelog': [
        {'version': '0.24.2', 'notes': '- C', 'date': '2026-08-11'},
        {'version': '0.24.0', 'notes': '- A'},
        {'version': '0.24.1', 'notes': '- B'},
        {'version': '0.24.1', 'notes': ''},
      ],
    });

    test('liefert nur neuere Versionen, neueste zuerst', () {
      final changes = manifest.changesSince(AppVersion.tryParse('0.24.0')!);
      expect(changes.map((e) => e.version.toString()), ['0.24.2', '0.24.1']);
      expect(changes.first.date, isNotNull);
    });

    test('meldet nichts, wenn die laufende Version die neueste ist', () {
      expect(manifest.changesSince(AppVersion.tryParse('0.24.2')!), isEmpty);
    });

    test('faellt ohne Changelog auf notes zurueck', () {
      final legacy = ReleaseManifest.fromJson({
        'latestVersion': '0.24.2',
        'notes': '- nur ein Text',
      });
      final changes = legacy.changesSince(AppVersion.tryParse('0.20.0')!);
      expect(changes.single.notes, '- nur ein Text');
      expect(changes.single.version.toString(), '0.24.2');
    });
  });

  group('evaluateUpdate', () {
    final current = AppVersion.tryParse('0.20.0')!;
    const abis = ['arm64-v8a'];

    UpdateAvailability check(ReleaseManifest manifest) => evaluateUpdate(
      current: current,
      manifest: manifest,
      asset: manifest.assetFor('android', abis: abis),
    );

    test('meldet nichts, wenn die laufende Version aktuell ist', () {
      expect(check(_manifest(latest: '0.20.0')), UpdateAvailability.none);
    });

    test('unterscheidet freiwilliges und erzwungenes Update', () {
      expect(check(_manifest(latest: '0.21.0')), UpdateAvailability.optional);
      expect(
        check(_manifest(latest: '0.21.0', minimum: '0.21.0')),
        UpdateAvailability.required,
      );
    });

    test('ohne Paket fuer das Geraet gibt es nichts zu melden', () {
      final manifest = _manifest(latest: '0.21.0', minimum: '0.21.0');
      expect(
        evaluateUpdate(
          current: current,
          manifest: manifest,
          asset: manifest.assetFor('windows'),
        ),
        UpdateAvailability.none,
      );
    });
  });
}
