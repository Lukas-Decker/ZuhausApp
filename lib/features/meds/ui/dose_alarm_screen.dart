import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/scope/app_scope.dart';
import '../../../data/db/app_database.dart';
import '../domain/medication_schedule.dart';
import '../meds_providers.dart';

/// Vollbild-Ansicht einer faelligen Einnahme.
///
/// Wird geoeffnet, wenn eine Erinnerung angetippt wird - auch aus einer
/// Vollbild-Meldung ueber dem Sperrbildschirm. Bewusst gross und mit wenigen,
/// eindeutigen Aktionen, damit man sie halb wach bedienen kann.
class DoseAlarmScreen extends ConsumerStatefulWidget {
  const DoseAlarmScreen({
    super.key,
    required this.planId,
    required this.scheduledFor,
    this.isTest = false,
  });

  final String planId;
  final DateTime scheduledFor;

  /// Testlauf aus dem Pillen-Tab: dann schlummert die Erinnerung nur kurz,
  /// damit sich die Kette in einem Durchgang pruefen laesst.
  final bool isTest;

  @override
  ConsumerState<DoseAlarmScreen> createState() => _DoseAlarmScreenState();
}

class _DoseAlarmScreenState extends ConsumerState<DoseAlarmScreen> {
  Timer? _timeout;
  bool _alarming = false;
  late final NotificationService _notifications;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    // In dispose() ist ref nicht mehr benutzbar (Riverpod wirft dort), der
    // Dienst wird deshalb hier festgehalten. Ohne das lief das Aufraeumen am
    // Ende nie: die App blieb ueber dem Sperrbildschirm bedienbar.
    _notifications = ref.read(notificationServiceProvider);

    // Reagiert niemand, schliesst sich der Schirm von selbst: sonst leuchtet
    // das Telefon die ganze Nacht. Die Einnahme bleibt faellig.
    final seconds = settings.wakeTimeoutSeconds;
    if (seconds > 0) {
      _timeout = Timer(Duration(seconds: seconds), () {
        _stopAlarm();
        if (mounted) _close(context);
      });
    }

    if (settings.wakeScreenEnabled) {
      // Dieser eine Schirm darf ueber dem Sperrbildschirm stehen. Das Telefon
      // bleibt dabei gesperrt, und beim Schliessen wird es zurueckgenommen.
      _notifications.setShowWhenLocked(true);

      // Ton und Vibration steuert die App hier selbst, mit Alarm-Attributen:
      // nur so greifen sie auch bei stumm geschaltetem Telefon.
      final maxSeconds = seconds > 0 ? seconds : 120;
      if (settings.reminderVibrationEnabled) {
        _alarming = true;
        _notifications.startAlarmVibration(maxSeconds: maxSeconds);
      }
      if (settings.reminderSoundEnabled) {
        _alarming = true;
        _notifications.startAlarmSound(maxSeconds: maxSeconds);
      }
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _stopAlarm();
    // Nimmt das Sperrbildschirm-Recht zurueck UND geht bei gesperrtem Telefon
    // in den Hintergrund. Ohne den zweiten Teil bliebe die App bedienbar.
    _notifications.endAlarmPresentation();
    super.dispose();
  }

  /// Beendet Ton und Vibration; mehrfaches Aufrufen schadet nicht.
  void _stopAlarm() {
    if (!_alarming) return;
    _alarming = false;
    _notifications.stopAlarmVibration();
    _notifications.stopAlarmSound();
  }

  @override
  Widget build(BuildContext context) {
    final planId = widget.planId;
    final scheduledFor = widget.scheduledFor;
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
              isTest: widget.isTest,
              // Ton und Vibration enden mit dem Antippen, nicht erst wenn die
              // Buchung durch ist und sich der Schirm schliesst.
              onActionStarted: _stopAlarm,
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
    required this.onActionStarted,
    this.isTest = false,
  });

  final MedicationPlan plan;
  final DateTime scheduledFor;
  final VoidCallback onDone;

  /// Wird sofort beim Antippen einer Aktion aufgerufen (stoppt Ton/Vibration).
  final VoidCallback onActionStarted;

  final bool isTest;

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
                  label: Text(widget.isTest ? '10 Sek.' : '15 Min.'),
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
          // Kein "Später entscheiden": ein Wecker soll eine Entscheidung
          // verlangen, sonst haette man ihn nicht gestellt. Wer wirklich
          // nichts tun will, laesst ihn ablaufen.
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
    // Sofort still, nicht erst wenn die Buchung durch ist.
    widget.onActionStarted();
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
    widget.onActionStarted();
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
            when: DateTime.now().add(
              widget.isTest
                  ? const Duration(seconds: 10)
                  : const Duration(minutes: 15),
            ),
            payload:
                'med:${plan.id}|${widget.scheduledFor.toIso8601String()}'
                '${widget.isTest ? '|test' : ''}',
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
