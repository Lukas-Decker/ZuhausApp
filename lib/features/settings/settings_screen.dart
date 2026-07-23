import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/scope_switcher_sheet.dart';

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
                      'Über den Kontext-Umschalter kannst du einen erstellen.',
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in list)
                        ListTile(
                          leading: Icon(entry.role.icon),
                          title: Text(entry.household.name),
                          subtitle: Text(entry.role.label),
                        ),
                    ],
                  ),
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
          const _SectionHeader('Über'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MultiApp'),
            subtitle: Text('Version 0.6.1'),
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
