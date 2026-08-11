import 'package:flutter/material.dart';

/// Einheitlicher Leerzustand für alle Module.
///
/// Aufbau bewusst in zwei gleich hohen Hälften: Symbol und Überschrift sitzen
/// am unteren Rand der oberen Hälfte, alles Weitere beginnt am oberen Rand der
/// unteren. Dadurch stehen Symbol und Überschrift in jedem Modul an derselben
/// Stelle, unabhängig davon, wie lang der erklärende Satz ist oder ob es einen
/// Knopf gibt.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Meist ein [AddGhostTile]; steht direkt unter dem erklärenden Satz.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 24),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
