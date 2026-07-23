import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/scope_switcher_sheet.dart';
import '../auth/auth_providers.dart';
import '../auth/ui/auth_screen.dart';
import '../household/household_actions.dart';
import '../household/ui/household_screen.dart';
import '../sync/sync_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final households = ref.watch(householdsProvider);
    final scope = ref.watch(activeScopeProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const _SectionHeader('Konto'),
          ListTile(
            leading: CircleAvatar(child: Text(identity.initials)),
            title: Text(identity.displayName),
            subtitle: Text(
              identity.isLinkedToAccount
                  ? 'Mit Konto verbunden'
                  : 'Lokal auf diesem Gerät, noch kein Konto',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editDisplayName(context, ref, identity.displayName),
          ),
          if (identity.isLinkedToAccount) ...[
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Abmelden'),
              subtitle: const Text(
                'Lokale Daten bleiben auf diesem Gerät erhalten.',
              ),
              onTap: () => _signOut(context, ref),
            ),
            const _SyncTile(),
          ] else
            ListTile(
              leading: const Icon(Icons.login_rounded),
              title: const Text('Anmelden oder Konto erstellen'),
              subtitle: Text(
                ref.watch(authConfiguredProvider)
                    ? 'Fuer Familie und Synchronisierung zwischen Geräten.'
                    : 'In dieser Version nicht verfügbar (Gastmodus).',
              ),
              onTap: () => AuthScreen.show(context),
            ),
          const Divider(),
          const _SectionHeader('Kontext'),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Aktiver Kontext'),
            subtitle: Text(scope.isPersonal ? 'Privat' : scope.label),
            onTap: () => ScopeSwitcherSheet.show(context),
          ),
          const Divider(),
          const _SectionHeader('Haushalte'),
          households.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text('Fehler: $error'),
            ),
            data: (list) => list.isEmpty
                ? const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Noch kein Haushalt'),
                    subtitle: Text(
                      '�ober den Kontext-Umschalter kannst du einen erstellen '
                      'oder beitreten.',
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in list)
                        ListTile(
                          leading: Icon(entry.role.icon),
                          title: Text(entry.household.name),
                          subtitle: Text(entry.role.label),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => HouseholdScreen.show(
                            context,
                            entry.household.id,
                          ),
                        ),
                    ],
                  ),
          ),
          if (ref.watch(currentUserProvider) != null)
            ListTile(
              leading: const Icon(Icons.group_add_rounded),
              title: const Text('Haushalt beitreten'),
              subtitle: const Text('Mit Einladungscode'),
              onTap: () => showJoinHouseholdDialog(context, ref),
            ),
          const Divider(),
          const _SectionHeader('Erinnerungen'),
          SwitchListTile(
            secondary: const Icon(Icons.medication_rounded),
            value: settings.medicationRemindersEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setMedicationRemindersEnabled,
            title: const Text('Medikamenten-Erinnerungen'),
            subtitle: const Text(
              'Pro Plan zusätzlich einzeln abschaltbar.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.pets_rounded),
            value: settings.petRemindersEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setPetRemindersEnabled,
            title: const Text('Tier-Erinnerungen'),
            subtitle: const Text('Fütterung, Arznei und Termine.'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event_busy_rounded),
            value: settings.expiryWarningsEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setExpiryWarningsEnabled,
            title: const Text('Ablaufwarnungen'),
            subtitle: Text(
              'Warnt ${settings.expiryWarningDays} Tage vorher. '
              'Pro Artikel zusätzlich einzeln abschaltbar.',
            ),
          ),
          const Divider(),
          const _SectionHeader('Datenschutz'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Produktdaten von Open Food Facts'),
            subtitle: Text(
              switch (settings.openFoodFactsConsent) {
                true =>
                  'Erlaubt. Beim Scan wird nur der Barcode übertragen.',
                false => 'Abgelehnt. Produkte werden selbst angelegt.',
                null => 'Noch nicht entschieden.',
              },
            ),
            trailing: Switch(
              value: settings.openFoodFactsConsent ?? false,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setOpenFoodFactsConsent,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Gesundheitsdaten (Pillen-Tracker)'),
            subtitle: Text(
              switch (settings.healthDataConsent) {
                true => 'Einwilligung erteilt (DSGVO Art. 9).',
                false || null => 'Noch nicht eingewilligt.',
              },
            ),
            trailing: Switch(
              value: settings.healthDataConsent ?? false,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setHealthDataConsent,
            ),
          ),
          const Divider(),
          const _SectionHeader('�ober'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MultiApp'),
            subtitle: Text('Version 0.9.2'),
          ),
        ],
      ),
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anzeigename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();

    final name = result?.trim() ?? '';
    if (name.isEmpty) return;
    await ref.read(identityProvider.notifier).setDisplayName(name);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text(
          'Du wirst vom Konto abgemeldet. Die Daten auf diesem Gerät bleiben '
          'erhalten und stehen im Gastmodus weiter zur Verfügung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authServiceProvider).signOut();
  }
}

/// Zeigt den Synchronisierungs-Status und erlaubt manuelles Abgleichen.
class _SyncTile extends ConsumerWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);

    final (icon, text) = switch (status.phase) {
      SyncPhase.syncing => (Icons.sync_rounded, 'Wird synchronisiert ...'),
      SyncPhase.error => (
        Icons.sync_problem_rounded,
        'Letzter Abgleich fehlgeschlagen',
      ),
      SyncPhase.offline => (Icons.cloud_off_rounded, 'Kein Konto'),
      SyncPhase.idle => (
        Icons.cloud_done_rounded,
        status.lastSyncedAt == null
            ? 'Bereit'
            : 'Zuletzt ${DateFormat('HH:mm', 'de').format(status.lastSyncedAt!)}',
      ),
    };

    return ListTile(
      leading: status.isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      title: const Text('Synchronisierung'),
      subtitle: Text(text),
      trailing: IconButton(
        tooltip: 'Jetzt abgleichen',
        onPressed: status.isSyncing
            ? null
            : () => ref.read(syncControllerProvider.notifier).syncNow(),
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
