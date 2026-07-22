import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/household/household_role.dart';
import 'package:multiapp/core/providers.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/household_repository.dart';
import 'package:multiapp/core/widgets/scope_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Baut eine Haushalts-Zeile ohne Datenbank, nur fuer den Test.
HouseholdWithRole _household(String id, String name) => HouseholdWithRole(
  household: Household(
    id: id,
    name: name,
    ownerUserId: 'u1',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    isDirty: false,
  ),
  role: HouseholdRole.owner,
);

Future<Widget> _boot({List<HouseholdWithRole> households = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      householdsProvider.overrideWith((ref) => Stream.value(households)),
    ],
    child: const MaterialApp(home: Scaffold(body: ScopeBanner())),
  );
}

void main() {
  testWidgets('Banner zeigt standardmaessig den privaten Kontext', (
    tester,
  ) async {
    await tester.pumpWidget(await _boot());
    await tester.pumpAndSettle();

    expect(find.text('PRIVAT'), findsOneWidget);
    expect(find.text('Nur fuer dich sichtbar'), findsOneWidget);
    expect(find.text('Wechseln'), findsOneWidget);
  });

  testWidgets('Umschalten auf den Haushalt aendert den Banner', (tester) async {
    await tester.pumpWidget(
      await _boot(households: [_household('h1', 'Familie Mueller')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wechseln'));
    await tester.pumpAndSettle();

    expect(find.text('Wo arbeitest du gerade?'), findsOneWidget);

    await tester.tap(find.text('Familie Mueller'));
    await tester.pumpAndSettle();

    expect(find.text('HAUSHALT'), findsOneWidget);
    expect(find.text('Familie Mueller'), findsOneWidget);
    expect(find.text('PRIVAT'), findsNothing);
  });
}
