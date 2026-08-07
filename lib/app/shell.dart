import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications/notification_providers.dart';
import '../core/widgets/scope_banner.dart';
import '../features/family/family_providers.dart';
import '../features/household/household_providers.dart';
import '../features/inventory/inventory_providers.dart';
import '../features/meds/meds_providers.dart';
import '../features/meds/notification_action_handler.dart';
import '../features/pets/pets_providers.dart';
import '../features/privacy/privacy_providers.dart';
import '../features/push/push_providers.dart';
import '../features/sync/sync_providers.dart';
import '../features/update/ui/update_prompt.dart';
import '../features/update/update_providers.dart';
import 'navigation.dart';

/// Rahmen der App: Kontextbanner ganz oben, darunter die Navigation.
///
/// Schmale Fenster bekommen eine untere Leiste, breite eine seitliche Schiene.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const double _railBreakpoint = 700;
  static const double _extendedRailBreakpoint = 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= _railBreakpoint;

    // Haelt den lokalen Haushalts-Cache mit dem Server im Takt.
    ref.watch(householdSyncProvider);
    // Haelt die Modul-Inhalte mit dem Server im Takt.
    ref.watch(syncControllerProvider);
    // Verarbeitet Aktionen aus Benachrichtigungen (Genommen/Snooze).
    ref.watch(notificationActionHandlerProvider);
    // Haelt die taegliche Ablauf-Sammelbenachrichtigung aktuell.
    ref.watch(expiryNotificationSyncProvider);
    // Plant die Medikamenten-Erinnerungen. Lief frueher nur, solange der
    // Pillen-Tab offen war: nach einem Neustart ohne Besuch dort wurde nichts
    // geplant.
    ref.watch(medicationReminderSyncProvider);
    // Empfaengt Familien-Ereignisse und prueft auf meldenswerte Situationen.
    ref.watch(familyEventListenerProvider);
    ref.watch(familyEventCheckerProvider);
    // Bereinigt abgelaufene Grabsteine und alte Audit-Eintraege beim Start.
    ref.watch(retentionRunnerProvider);
    // Registriert FCM fuer Push bei geschlossener App (nur Android).
    ref.watch(fcmInitProvider);
    // Korrigiert einmalig alte Aufgaben-Titel ohne Umlaute.
    ref.watch(petTaskTitleRepairProvider);
    // Holt die Android-Benachrichtigungsberechtigung, falls sie noch fehlt.
    ref.watch(notificationPermissionRequestProvider);
    // Haelt den Wecker-Modus der Erinnerungen aktuell.
    ref.watch(wakeScreenSyncProvider);
    // Sieht beim Start und alle sechs Stunden nach neuen Versionen.
    ref.watch(updateAutoCheckProvider);

    // Beim Tab-Wechsel einen Abgleich anstossen.
    void onNavigate() =>
        ref.read(syncControllerProvider.notifier).syncNow();

    return Scaffold(
      // Die Tastatur-Anpassung uebernimmt allein das innere ModuleScaffold;
      // sonst rechnen beide Scaffolds die Tastaturhoehe an und das Eingabefeld
      // rutscht hinter die Kopfzeile.
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const SafeArea(bottom: false, child: ScopeBanner()),
          // Zeigt den Update-Hinweis, sobald eine Pruefung faellig war.
          const UpdatePrompt(),
          // Der Kontextbanner hat die Statusleiste oben bereits abgedeckt.
          // Ohne dieses removeTop wuerde die Modul-Kopfzeile die Statusleisten-
          // Hoehe ein zweites Mal reservieren (leerer Streifen ueber dem Titel).
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: useRail
                  ? Row(
                      children: [
                        _ModuleRail(
                          navigationShell: navigationShell,
                          extended: width >= _extendedRailBreakpoint,
                          onNavigate: onNavigate,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: navigationShell),
                      ],
                    )
                  : navigationShell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : _ModuleBottomBar(
              navigationShell: navigationShell,
              onNavigate: onNavigate,
            ),
    );
  }
}

class _ModuleBottomBar extends StatelessWidget {
  const _ModuleBottomBar({
    required this.navigationShell,
    required this.onNavigate,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        onNavigate();
        navigationShell.goBranch(index, initialLocation: false);
      },
      destinations: [
        for (final module in AppModule.values)
          NavigationDestination(
            icon: Icon(module.icon),
            selectedIcon: Icon(module.selectedIcon),
            label: module.label,
          ),
      ],
    );
  }
}

class _ModuleRail extends StatelessWidget {
  const _ModuleRail({
    required this.navigationShell,
    required this.extended,
    required this.onNavigate,
  });

  final StatefulNavigationShell navigationShell;
  final bool extended;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                onNavigate();
                navigationShell.goBranch(index, initialLocation: false);
              },
              destinations: [
                for (final module in AppModule.values)
                  NavigationRailDestination(
                    icon: Icon(module.icon),
                    selectedIcon: Icon(module.selectedIcon),
                    label: Text(module.label),
                  ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Einstellungen',
                      onPressed: () => context.push(settingsPath),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
