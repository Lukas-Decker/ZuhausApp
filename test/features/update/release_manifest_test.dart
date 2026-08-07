import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/features/update/domain/release_manifest.dart';

ReleaseManifest _manifest({
  required String latest,
  String? minimum,
  bool withAndroid = true,
}) => ReleaseManifest.fromJson({
  'latestVersion': latest,
  'minVersion': ?minimum,
  if (withAndroid)
    'android': {
      'url': 'https://example.org/releases/Android-$latest.apk',
      'size': 42,
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

  group('evaluateUpdate', () {
    final current = AppVersion.tryParse('0.20.0')!;

    test('meldet nichts, wenn die laufende Version aktuell ist', () {
      final status = evaluateUpdate(
        current: current,
        manifest: _manifest(latest: '0.20.0'),
        platform: 'android',
      );
      expect(status, UpdateAvailability.none);
    });

    test('unterscheidet freiwilliges und erzwungenes Update', () {
      expect(
        evaluateUpdate(
          current: current,
          manifest: _manifest(latest: '0.21.0'),
          platform: 'android',
        ),
        UpdateAvailability.optional,
      );
      expect(
        evaluateUpdate(
          current: current,
          manifest: _manifest(latest: '0.21.0', minimum: '0.21.0'),
          platform: 'android',
        ),
        UpdateAvailability.required,
      );
    });

    test('ohne Paket fuer die Plattform gibt es nichts zu melden', () {
      final status = evaluateUpdate(
        current: current,
        manifest: _manifest(latest: '0.21.0', minimum: '0.21.0'),
        platform: 'windows',
      );
      expect(status, UpdateAvailability.none);
    });
  });
}
