import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers.dart';
import '../../../core/scope/app_scope.dart';
import '../../../data/db/app_database.dart';
import '../domain/medication_schedule.dart';
import '../meds_providers.dart';

/// Vollbild-Ansicht einer faelligen Einnahme.
///
/// Wird geoeffnet, wenn eine Erinnerung angetippt wird - auch aus einer
/// Vollbild-Meldung ueber dem Sperrbildschirm. Bewusst gross und mit wenigen,
/// eindeutigen Aktionen, damit man sie halb wach bedienen kann.
class DoseAlarmScreen extends ConsumerWidget {
  const DoseAlarmScreen({
    super.key,
    required this.planId,
    required this.scheduledFor,
  });

  final String planId;
  final DateTime scheduledFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: FutureBuilder<MedicationPlan?>(
          future: ref.read(medicationRepositoryProvider).getPlan(planId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final plan = snapshot.data;
            if (plan == null) {
              return _Missing(onClose: () => _close(context));
            }
            return _Content(
              plan: plan,
              scheduledFor: scheduledFor,
              onDone: () => _close(context),
            );
          },
        ),
      ),
    );
  }

  void _close(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({
    required this.plan,
    required this.scheduledFor,
    required this.onDone,
  });

  final MedicationPlan plan;
  final DateTime scheduledFor;
  final VoidCallback onDone;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final form = medicationForm(plan.form);
    final scheme = Theme.of(context).colorScheme;
    final dosage = plan.dosage.trim();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(form.icon, size: 72, color: scheme.primary),
          const SizedBox(height: 24),
          Text(
            DateFormat('HH:mm', 'de').format(widget.scheduledFor),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w300,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (dosage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              dosage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: _busy ? null : () => _record('taken'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 64),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.check_rounded, size: 26),
            label: const Text('Genommen'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _snooze,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  icon: const Icon(Icons.snooze_rounded),
                  label: const Text('15 Min.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _record('skipped'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    foregroundColor: scheme.error,
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Ausgelassen'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : widget.onDone,
            child: const Text('Später entscheiden'),
          ),
        ],
      ),
    );
  }

  AppScope get _scope => widget.plan.scopeKind == ScopeKind.household.name
      ? AppScope.household(widget.plan.scopeId, '')
      : AppScope.personal(widget.plan.scopeId);

  String get _slotKey =>
      '${widget.plan.id}@${widget.scheduledFor.toIso8601String()}';

  Future<void> _record(String status) async {
    setState(() => _busy = true);
    await ref
        .read(medicationRepositoryProvider)
        .recordIntake(
          scope: _scope,
          userId: ref.read(identityProvider).userId,
          plan: widget.plan,
          scheduledFor: widget.scheduledFor,
          status: status,
        );
    await ref
        .read(notificationServiceProvider)
        .cancel(notificationIdFromKey(_slotKey));
    widget.onDone();
  }

  Future<void> _snooze() async {
    setState(() => _busy = true);
    final plan = widget.plan;
    final form = medicationForm(plan.form);
    final dosage = plan.dosage.trim();
    await ref
        .read(notificationServiceProvider)
        .schedule(
          ScheduledReminder(
            id: notificationIdFromKey('snooze:$_slotKey'),
            title: '${form.label} nehmen',
            body: dosage.isEmpty
                ? 'Zeit für ${plan.name}'
                : 'Zeit für ${plan.name}: $dosage',
            when: DateTime.now().add(const Duration(minutes: 15)),
            payload: 'med:${plan.id}|${widget.scheduledFor.toIso8601String()}',
          ),
          channel: NotificationService.medicationChannel,
        );
    widget.onDone();
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Dieser Plan existiert nicht mehr.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onClose, child: const Text('Schließen')),
          ],
        ),
      ),
    );
  }
}
