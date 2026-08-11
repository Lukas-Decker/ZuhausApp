import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/inventory/ui/inventory_screen.dart';
import '../features/meds/ui/meds_screen.dart';
import '../features/notes/ui/notes_screen.dart';
import '../features/pets/ui/pets_screen.dart';
import '../features/prospekte/ui/brochure_viewer_screen.dart';
import '../features/prospekte/ui/prospekte_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shopping/ui/shopping_screen.dart';
import 'navigation.dart';
import 'shell.dart';

/// Navigator-Schluessel der App, auch fuer Deep-Link-Dialoge nutzbar.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Jedes Modul bekommt einen eigenen Navigations-Zweig, damit der
/// Navigationsverlauf beim Wechsel zwischen Modulen erhalten bleibt.
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppModule.inventory.path,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        _branch(AppModule.inventory, const InventoryScreen()),
        _branch(
          AppModule.shopping,
          const ShoppingScreen(),
          routes: [
            // Prospekte haengen als Unterseite am Einkauf-Modul, damit die
            // Navigationsleiste bei fuenf Modulen bleibt.
            GoRoute(
              path: 'prospekte',
              builder: (context, state) => const ProspekteScreen(),
              routes: [
                GoRoute(
                  path: 'ansicht',
                  builder: (context, state) => BrochureViewerScreen(
                    brochureRef: state.uri.queryParameters['id'] ?? '',
                    initialPage: int.tryParse(
                      state.uri.queryParameters['seite'] ?? '',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        _branch(AppModule.notes, const NotesScreen()),
        _branch(AppModule.meds, const MedsScreen()),
        _branch(AppModule.pets, const PetsScreen()),
      ],
    ),
    GoRoute(
      path: settingsPath,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

StatefulShellBranch _branch(
  AppModule module,
  Widget child, {
  List<RouteBase> routes = const [],
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: module.path,
        builder: (context, state) => child,
        routes: routes,
      ),
    ],
  );
}
