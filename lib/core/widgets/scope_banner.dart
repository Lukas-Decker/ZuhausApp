import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../providers.dart';
import '../scope/app_scope.dart';
import 'scope_switcher_sheet.dart';

/// Dauerhaft sichtbare Leiste, die den aktiven Kontext anzeigt.
///
/// Bewusst kräftig eingefärbt und nicht ausblendbar: Nutzer lesen Hinweise
/// nicht, aber sie sehen Farbe. Ein Tipp darauf öffnet den Umschalter.
class ScopeBanner extends ConsumerWidget implements PreferredSizeWidget {
  const ScopeBanner({super.key});

  static const double height = 46;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(activeScopeProvider);
    final scheme = Theme.of(context).colorScheme;
    final isPersonal = scope.isPersonal;

    return Material(
      color: scheme.primary,
      child: InkWell(
        onTap: () => ScopeSwitcherSheet.show(context),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  ScopePalette.iconFor(scope.kind),
                  color: scheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  ScopePalette.badgeFor(scope.kind),
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPersonal ? 'Nur für dich sichtbar' : scope.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.swap_horiz_rounded, color: scheme.onPrimary, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Wechseln',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kleiner Kontext-Chip für Dialoge und Formulare.
///
/// Wird überall dort eingesetzt, wo etwas angelegt wird, damit der Zielort
/// auch im Formular selbst noch einmal auftaucht.
class ScopeChip extends ConsumerWidget {
  const ScopeChip({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(activeScopeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap ?? () => ScopeSwitcherSheet.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ScopePalette.iconFor(scope.kind),
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  scope.isPersonal ? 'Privat' : scope.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Beschriftung für Aktionsbuttons, damit das Ziel im Klartext dasteht.
String scopeActionLabel(AppScope scope, {String verb = 'Hinzufügen'}) =>
    scope.isPersonal ? '$verb (privat)' : '$verb zu ${scope.label}';
