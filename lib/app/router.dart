import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/placeholder/module_placeholder.dart';
import '../features/settings/settings_screen.dart';
import 'navigation.dart';
import 'shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Jedes Modul bekommt einen eigenen Navigations-Zweig, damit der
/// Navigationsverlauf beim Wechsel zwischen Modulen erhalten bleibt.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppModule.inventory.path,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        _branch(
          AppModule.inventory,
          const ModulePlaceholder(
            title: 'Inventar',
            icon: Icons.kitchen_rounded,
            plannedVersion: 'v0.2',
            description:
                'Vorraete mit Barcode oder manuell erfassen, inklusive '
                'Mindestbestand und Ablaufdatum.',
          ),
        ),
        _branch(
          AppModule.shopping,
          const ModulePlaceholder(
            title: 'Einkauf',
            icon: Icons.shopping_cart_rounded,
            plannedVersion: 'v0.3',
            description:
                'Einkaufslisten, die sich beim Abhaken direkt ins Inventar '
                'uebertragen lassen.',
          ),
        ),
        _branch(
          AppModule.notes,
          const ModulePlaceholder(
            title: 'Notizen',
            icon: Icons.sticky_note_2_rounded,
            plannedVersion: 'v0.4',
            description:
                'Notizen und Checklisten mit Anheften, Farben und Suche.',
          ),
        ),
        _branch(
          AppModule.meds,
          const ModulePlaceholder(
            title: 'Pillen',
            icon: Icons.medication_rounded,
            plannedVersion: 'v0.5',
            description:
                'Medikamentenplaene mit Erinnerung, Einnahme-Protokoll und '
                'optionaler Betreuer-Freigabe.',
          ),
        ),
        _branch(
          AppModule.pets,
          const ModulePlaceholder(
            title: 'Tiere',
            icon: Icons.pets_rounded,
            plannedVersion: 'v0.6',
            description:
                'Fuetterung, Arznei, Tierarzttermine und Gewichtsverlauf '
                'fuer alle Tiere im Haushalt.',
          ),
        ),
      ],
    ),
    GoRoute(
      path: settingsPath,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

StatefulShellBranch _branch(AppModule module, Widget child) {
  return StatefulShellBranch(
    routes: [
      GoRoute(path: module.path, builder: (context, state) => child),
    ],
  );
}
