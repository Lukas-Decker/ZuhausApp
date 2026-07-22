import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/scope_banner.dart';

/// Platzhalter fuer Module, die in einer spaeteren Ausbaustufe kommen.
///
/// Zeigt bereits den aktiven Kontext, damit die Kontextlogik von Anfang an
/// ueberall sichtbar ist.
class ModulePlaceholder extends ConsumerWidget {
  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.plannedVersion,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String plannedVersion;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(activeScopeProvider);

    return ModuleScaffold(
      title: title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Aktiver Kontext: '),
                const ScopeChip(),
              ],
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: icon,
              title: '$title folgt in $plannedVersion',
              message: '$description\n\nAktuell ausgewaehlt: '
                  '${scope.isPersonal ? "Privat" : scope.label}',
            ),
          ),
        ],
      ),
    );
  }
}
