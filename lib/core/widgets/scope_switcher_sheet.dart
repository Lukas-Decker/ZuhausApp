import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../providers.dart';
import '../scope/app_scope.dart';

/// Auswahl des aktiven Kontexts.
///
/// Die Einträge sind in ihrer jeweiligen Kontextfarbe gehalten, damit die
/// Zuordnung Farbe zu Kontext sofort gelernt wird.
class ScopeSwitcherSheet extends ConsumerWidget {
  const ScopeSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const ScopeSwitcherSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopes = ref.watch(availableScopesProvider);
    final active = ref.watch(activeScopeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Wo arbeitest du gerade?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Alles was du anlegst, landet im gewählten Kontext.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            for (final scope in scopes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ScopeTile(
                  scope: scope,
                  selected: scope == active,
                  onTap: () async {
                    await ref.read(activeScopeProvider.notifier).select(scope);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _createHousehold(context, ref),
              icon: const Icon(Icons.add_home_rounded),
              label: const Text('Haushalt erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createHousehold(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Neuer Haushalt'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'z.B. Familie Müller',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final identity = ref.read(identityProvider);
    final household = await ref.read(householdRepositoryProvider).create(
      name: trimmed,
      userId: identity.userId,
      displayName: identity.displayName,
    );
    await ref
        .read(activeScopeProvider.notifier)
        .select(AppScope.household(household.id, household.name));

    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({
    required this.scope,
    required this.selected,
    required this.onTap,
  });

  final AppScope scope;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ScopePalette.seedFor(scope.kind),
      brightness: Theme.of(context).brightness,
    );

    return Material(
      color: selected ? scheme.primary : scheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                ScopePalette.iconFor(scope.kind),
                color: selected ? scheme.onPrimary : scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scope.isPersonal ? 'Privat' : scope.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      scope.isPersonal
                          ? 'Nur auf deinen Geräten'
                          : 'Geteilt mit allen Mitgliedern',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            (selected
                                    ? scheme.onPrimary
                                    : scheme.onPrimaryContainer)
                                .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
