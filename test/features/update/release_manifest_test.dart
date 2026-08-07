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
