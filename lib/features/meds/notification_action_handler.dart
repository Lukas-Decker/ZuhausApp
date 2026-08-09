import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import '../../core/scope/app_scope.dart';
import 'domain/medication_schedule.dart';
import 'meds_providers.dart';
import 'ui/dose_alarm_screen.dart';

/// Reagiert auf Aktionen aus Medikamenten-Benachrichtigungen
/// (Genommen / Snooze) und den Start aus einer Benachrichtigung.
///
/// Muss beobachtet werden (siehe AppShell), damit die Verarbeitung laeuft.
final notificationActionHandlerProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);

  final sub = service.actions.listen((action) => _handle(ref, service, action));
  ref.onDispose(sub.cancel);

  // Falls die App durch Antippen einer Benachrichtigung gestartet wurde.
  service.initialAction().then((action) {
    if (action != null) _handle(ref, service, action);
  });
});

Future<void> _handle(
  Ref ref,
  NotificationService service,
  NotificationAction action,
) async {
  final payload = action.payload;
  if (payload == null || !payload.startsWith('med:')) return;

  final rest = payload.substring(4);
  final parts = rest.split('|');
  final planId = parts.first;
  final scheduledFor = parts.length > 1 ? DateTime.tryParse(parts[1]) : null;
  if (scheduledFor == null) return;
  // Testlauf aus dem Pillen-Tab: dann schlummert die Erinnerung nur kurz.
  final isTest = parts.length > 2 && parts[2] == 'test';

  final repo = ref.read(medicationRepositoryProvider);
  final plan = await repo.getPlan(planId);
  if (plan == null) return;

  final scope = plan.scopeKind == ScopeKind.household.name
      ? AppScope.household(plan.scopeId, '')
      : AppScope.personal(plan.scopeId);
  final userId = ref.read(identityProvider).userId;
  final slotKey = '$planId@${scheduledFor.toIso8601String()}';

  switch (action.actionId) {
    case medTakenActionId:
      await repo.recordIntake(
        scope: scope,
        userId: userId,
        plan: plan,
        scheduledFor: scheduledFor,
        status: 'taken',
      );
      await service.cancel(notificationIdFromKey(slotKey));

    case medSnoozeActionId:
      final dose = medicationDoseLabel(plan.form, plan.dosage);
      await service.schedule(
        ScheduledReminder(
          id: notificationIdFromKey('snooze:$slotKey'),
          title: '$dose nehmen',
          body: 'Zeit für ${plan.name}',
          when: DateTime.now().add(
            isTest ? const Duration(seconds: 10) : const Duration(minutes: 15),
          ),
          payload: payload,
        ),
        channel: NotificationService.medicationChannel,
      );

    default:
      // Einfaches Antippen (auch aus einer Vollbild-Meldung ueber dem
      // Sperrbildschirm): die faellige Einnahme gross anzeigen, statt die App
      // dort zu oeffnen, wo sie zuletzt war.
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => DoseAlarmScreen(
            planId: planId,
            scheduledFor: scheduledFor,
            isTest: isTest,
          ),
          fullscreenDialog: true,
        ),
      );
  }
}
