import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/inventory/ui/inventory_screen.dart';
import '../features/notes/ui/notes_screen.dart';
import '../features/placeholder/module_placeholder.dart';
import '../features/settings/settings_screen.dart';
import '../features/shopping/ui/shopping_screen.dart';
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
        _branch(AppModule.inventory, const InventoryScreen()),
        _branch(AppModule.shopping, const ShoppingScreen()),
        _branch(AppModule.notes, const NotesScreen()),
        _branch(
          AppModule.meds,
          const ModulePlaceholder(
            title: 'Pillen',
            icon: Icons.medication_rounded,
            plannedVersion: 'v0.5',
            description:
                'Medikamentenpläne mit Erinnerung, Einnahme-Protokoll und '
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
                'Fütterung, Arznei, Tierarzttermine und Gewichtsverlauf '
                'für alle Tiere im Haushalt.',
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
