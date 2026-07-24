import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/app_info.dart';
import 'package:multiapp/core/providers.dart';
import 'package:multiapp/core/security/app_lock.dart';
import 'package:multiapp/core/security/app_lock_gate.dart';
import 'package:multiapp/core/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Steuerbarer Ersatz fuer das echte biometrische Schloss.
class _FakeAppLock implements AppLock {
  _FakeAppLock({this.result = false});

  bool result;
  int authCalls = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> authenticate() async {
    authCalls++;
    return result;
  }
}

Future<ProviderContainer> _container({bool appLock = false}) async {
  SharedPreferences.setMockInitialValues({
    if (appLock) 'security.applock.enabled': true,
  });
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  group('AppSettings App-Schloss', () {
    test('ist standardmaessig aus und laesst sich schalten', () async {
      final container = await _container();
      addTearDown(container.dispose);

      expect(container.read(appSettingsProvider).appLockEnabled, isFalse);

      await container
          .read(appSettingsProvider.notifier)
          .setAppLockEnabled(true);

      expect(container.read(appSettingsProvider).appLockEnabled, isTrue);
      expect(
        container.read(sharedPreferencesProvider).getBool(
          'security.applock.enabled',
        ),
        isTrue,
      );
    });
  });

  group('AppLockGate', () {
    testWidgets('bei ausgeschaltetem Schloss bleibt alles offen', (
      tester,
    ) async {
      final container = await _container();
      addTearDown(container.dispose);
      final lock = _FakeAppLock();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              container.read(sharedPreferencesProvider),
            ),
            appLockProvider.overrideWithValue(lock),
          ],
          child: const MaterialApp(
            home: AppLockGate(child: Scaffold(body: Text('Geheimer Inhalt'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Geheimer Inhalt'), findsOneWidget);
      expect(find.text('$appName ist gesperrt'), findsNothing);
      expect(lock.authCalls, 0);
    });

    testWidgets('sperrt beim Start und entsperrt nach Erfolg', (tester) async {
      final container = await _container(appLock: true);
      addTearDown(container.dispose);
      final lock = _FakeAppLock(result: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              container.read(sharedPreferencesProvider),
            ),
            appLockProvider.overrideWithValue(lock),
          ],
          child: const MaterialApp(
            home: AppLockGate(child: Scaffold(body: Text('Geheimer Inhalt'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Startet gesperrt, der automatische Versuch schlug fehl.
      expect(find.text('$appName ist gesperrt'), findsOneWidget);
      expect(lock.authCalls, greaterThanOrEqualTo(1));

      // Jetzt gelingt die Verifikation.
      lock.result = true;
      await tester.tap(find.text('Entsperren'));
      await tester.pumpAndSettle();

      expect(find.text('$appName ist gesperrt'), findsNothing);
      expect(find.text('Geheimer Inhalt'), findsOneWidget);
    });
  });
}
