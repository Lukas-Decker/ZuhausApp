import '../../../core/diagnostics/debug_log.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/repositories/medication_repository.dart';
import '../domain/dose_schedule.dart';
import '../domain/medication_schedule.dart';

/// Plant die lokalen Einnahme-Erinnerungen für die kommenden Tage.
///
/// Weil das Betriebssystem nur eine begrenzte Zahl geplanter Alarme erlaubt,
/// planen wir ein rollierendes Fenster (Standard: 7 Tage) und erneuern es beim
/// App-Start und nach jeder Änderung an den Plänen.
class MedicationReminderScheduler {
  MedicationReminderScheduler({
    required this.repository,
    required this.notifications,
  });

  static const _horizonDays = 7;
  static const _maxReminders = 60;

  final MedicationRepository repository;
  final NotificationService notifications;

  /// Verwirft alle geplanten Erinnerungen und plant sie neu.
  ///
  /// [enabled] ist der globale Schalter aus den Einstellungen.
  Future<void> reschedule({required bool enabled}) async {
    if (!notifications.isSupported) return;

    // Nur die eigenen Erinnerungen verwerfen. Ein pauschales cancelAll() hat
    // frueher auch die Ablauf- und Tier-Erinnerungen mitgeloescht.
    await notifications.cancelWithPayloadPrefix('med:');
    if (!enabled) return;

    final plans = await repository.allActivePlans();
    if (plans.isEmpty) return;

    final now = DateTime.now();
    final reminders = <ScheduledReminder>[];

    for (var dayOffset = 0; dayOffset < _horizonDays; dayOffset++) {
      final day = now.add(Duration(days: dayOffset));
      for (final plan in plans) {
        for (final occ in DoseSchedule.forDay(plan, day)) {
          if (occ.scheduledFor.isBefore(now)) continue;
          reminders.add(_reminderFor(occ));
        }
      }
    }

    reminders.sort((a, b) => a.when.compareTo(b.when));
    for (final reminder in reminders.take(_maxReminders)) {
      await notifications.schedule(
        reminder,
        channel: NotificationService.medicationChannel,
      );
    }
    DebugLog.instance.add(
      'meds',
      'Erinnerungen geplant: ${reminders.take(_maxReminders).length} '
      '(aus ${plans.length} aktiven Plänen)',
    );
  }

  ScheduledReminder _reminderFor(DoseOccurrence occ) {
    // Menge und Form zusammen: "2 Tabletten nehmen" statt "Tablette nehmen".
    final dose = medicationDoseLabel(occ.plan.form, occ.plan.dosage);

    return ScheduledReminder(
      id: notificationIdFromKey(occ.slotKey),
      title: '$dose nehmen',
      body: 'Zeit für ${occ.plan.name}',
      when: occ.scheduledFor,
      // Plan und genauer Zeitpunkt, damit die Aktionen die richtige Einnahme
      // treffen: "med:<planId>|<scheduledForIso>".
      payload: 'med:${occ.plan.id}|${occ.scheduledFor.toIso8601String()}',
    );
  }
}
