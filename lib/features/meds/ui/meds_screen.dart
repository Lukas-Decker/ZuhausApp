import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/medication_repository.dart';
import '../domain/medication_schedule.dart';
import '../meds_providers.dart';
import 'medication_plan_editor.dart';

class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(
      appSettingsProvider.select((s) => s.healthDataConsent),
    );

    // Erinnerungen im Hintergrund aktuell halten, solange dieser Screen lebt.
    ref.watch(medicationReminderSyncProvider);

    if (consent != true) {
      return const ModuleScaffold(
        title: 'Pillen',
        body: _HealthConsentGate(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: ModuleScaffold(
        title: 'Pillen',
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Heute'),
            Tab(text: 'Pläne'),
          ],
        ),
        floatingActionButton: AddFab(
          onPressed: () => MedicationPlanEditor.show(context),
          label: 'Medikament',
        ),
        body: const TabBarView(
          children: [_DayTab(), _PlansTab()],
        ),
      ),
    );
  }
}

// --- Einwilligung -----------------------------------------------------------

class _HealthConsentGate extends ConsumerWidget {
  const _HealthConsentGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.health_and_safety_rounded, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Gesundheitsdaten',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Der Pillen-Tracker verarbeitet Gesundheitsdaten (DSGVO Art. 9). '
                'Diese liegen standardmäßig nur in deinem privaten Bereich und '
                'werden erst nach ausdrücklicher Freigabe pro Plan mit anderen '
                'geteilt.\n\n'
                'Die Daten bleiben lokal auf deinem Gerät, bis du Konto und '
                'Synchronisierung einrichtest. Du kannst die Einwilligung '
                'jederzeit in den Einstellungen widerrufen.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .setHealthDataConsent(true);
                  // Bei Zustimmung gleich die Benachrichtigungsberechtigung holen.
                  await ref
                      .read(notificationServiceProvider)
                      .requestPermission();
                },
                child: const Text('Einwilligen und starten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Tagesansicht -----------------------------------------------------------

class _DayTab extends ConsumerWidget {
  const _DayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedMedDayProvider);
    final doses = ref.watch(medDayProvider);

    return Column(
      children: [
        _DayNavigator(day: day),
        Expanded(
          child: doses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Fehler',
              message: '$error',
            ),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: Icons.medication_outlined,
                    title: 'Nichts fällig',
                    message: 'An diesem Tag steht keine Einnahme an.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: list.length,
                    itemBuilder: (context, index) =>
                        _DoseTile(status: list[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DayNavigator extends ConsumerWidget {
  const _DayNavigator({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final isToday =
        day.year == today.year && day.month == today.month && day.day == today.day;
    final label = isToday
        ? 'Heute'
        : DateFormat('EEEE, dd.MM.', 'de').format(day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                ref.read(selectedMedDayProvider.notifier).shift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: TextButton(
                onPressed: isToday
                    ? null
                    : () => ref.read(selectedMedDayProvider.notifier).today(),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(selectedMedDayProvider.notifier).shift(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _DoseTile extends ConsumerWidget {
  const _DoseTile({required this.status});

  final DoseStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = status.occurrence.plan;
    final form = medicationForm(plan.form);
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(status.occurrence.scheduledFor);
    final logStatus =
        status.log == null ? null : IntakeStatus.parse(status.log!.status);

    final (bg, fg) = switch (logStatus) {
      IntakeStatus.taken => (scheme.primaryContainer, scheme.onPrimaryContainer),
      IntakeStatus.skipped => (scheme.errorContainer, scheme.onErrorContainer),
      IntakeStatus.postponed => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      null => (scheme.surfaceContainerLow, scheme.onSurface),
    };

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      color: bg,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linke Seite: Inhalt oben, "Genommen" als volle Leiste unten.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.surface,
                          child: Icon(form.icon, color: scheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: fg,
                                ),
                              ),
                              Text(
                                [
                                  ScheduleTimes.formatTime(time),
                                  if (plan.dosage.trim().isNotEmpty)
                                    plan.dosage.trim(),
                                ].join(' · '),
                                style: TextStyle(
                                  color: fg.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (logStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(logStatus.icon, color: fg),
                          ),
                      ],
                    ),
                  ),
                  Material(
                    color: scheme.primary,
                    child: InkWell(
                      onTap: () => _record(ref, IntakeStatus.taken),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: scheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Genommen',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rechte Leiste: Snooze oben, Auslassen unten.
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SideAction(
                      icon: Icons.snooze_rounded,
                      tooltip: 'Später',
                      color: fg,
                      onTap: () => _record(ref, IntakeStatus.postponed),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: _SideAction(
                      icon: Icons.cancel_outlined,
                      tooltip: 'Ausgelassen',
                      color: fg,
                      onTap: () => _record(ref, IntakeStatus.skipped),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _record(WidgetRef ref, IntakeStatus status) {
    ref
        .read(medicationRepositoryProvider)
        .recordIntake(
          scope: ref.read(activeScopeProvider),
          userId: ref.read(identityProvider).userId,
          plan: this.status.occurrence.plan,
          scheduledFor: this.status.occurrence.scheduledFor,
          status: status.key,
        );
  }
}

/// Ein Icon-Knopf in der rechten Leiste der Dosis-Karte (Snooze/Auslassen).
class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Center(child: Icon(icon, color: color)),
        ),
      ),
    );
  }
}

// --- Planliste --------------------------------------------------------------

class _PlansTab extends ConsumerWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(medicationPlansProvider);

    return plans.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          EmptyState(icon: Icons.error_outline, title: 'Fehler', message: '$error'),
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.medication_outlined,
              title: 'Noch keine Pläne',
              message: 'Lege dein erstes Medikament mit Einnahmezeiten an.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _PlanTile(plan: list[index]),
            ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = medicationForm(plan.form);
    final scheme = Theme.of(context).colorScheme;

    final schedule = ScheduleType.parse(plan.scheduleType) == ScheduleType.daily
        ? '${ScheduleWeekdays.describe(plan.weekdays)} · '
              '${ScheduleTimes.parse(plan.times).map(ScheduleTimes.formatTime).join(", ")}'
        : 'Alle ${plan.intervalHours} h';

    final lowStock = plan.stockCount != null &&
        plan.stockThreshold != null &&
        plan.stockCount! <= plan.stockThreshold!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: plan.isActive
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        child: Icon(form.icon),
      ),
      title: Text(
        plan.name,
        style: TextStyle(
          decoration: plan.isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(schedule),
          Row(
            children: [
              if (!plan.remindersEnabled)
                _Tag(
                  icon: Icons.notifications_off_rounded,
                  text: 'Ohne Erinnerung',
                  color: scheme.onSurfaceVariant,
                ),
              if (plan.stockCount != null)
                _Tag(
                  icon: Icons.inventory_2_outlined,
                  text: 'Vorrat: ${_fmt(plan.stockCount!)}',
                  color: lowStock ? scheme.error : scheme.onSurfaceVariant,
                ),
              if (plan.sharedWithHousehold)
                _Tag(
                  icon: Icons.groups_rounded,
                  text: 'Geteilt',
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _onMenu(context, ref, value),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: const Row(
              children: [
                Icon(Icons.edit_outlined),
                SizedBox(width: 12),
                Text('Bearbeiten'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(plan.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
                const SizedBox(width: 12),
                Text(plan.isActive ? 'Pausieren' : 'Fortsetzen'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded),
                SizedBox(width: 12),
                Text('Löschen'),
              ],
            ),
          ),
        ],
      ),
      onTap: () => MedicationPlanEditor.show(context, plan: plan),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final repo = ref.read(medicationRepositoryProvider);
    final userId = ref.read(identityProvider).userId;
    switch (value) {
      case 'edit':
        await MedicationPlanEditor.show(context, plan: plan);
      case 'toggle':
        await repo.setActive(plan.id, !plan.isActive, userId);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Plan löschen?'),
            content: Text('"${plan.name}" und der Einnahmeverlauf werden entfernt.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        if (confirmed == true) await repo.deletePlan(plan.id, userId);
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
