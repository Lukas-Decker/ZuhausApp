import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/medication_repository.dart';
import 'data/medication_reminder_scheduler.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepository(ref.watch(databaseProvider)),
);

final medicationReminderSchedulerProvider =
    Provider<MedicationReminderScheduler>(
      (ref) => MedicationReminderScheduler(
        repository: ref.watch(medicationRepositoryProvider),
        notifications: ref.watch(notificationServiceProvider),
      ),
    );

/// Der aktuell im Tracker betrachtete Tag.
class SelectedMedDayController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);
  void today() => select(DateTime.now());
  void shift(int days) => select(state.add(Duration(days: days)));
}

final selectedMedDayProvider =
    NotifierProvider<SelectedMedDayController, DateTime>(
      SelectedMedDayController.new,
    );

final medicationPlansProvider = StreamProvider<List<MedicationPlan>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  return ref.watch(medicationRepositoryProvider).watchPlans(scope);
});

/// Fälligkeiten des ausgewählten Tages mit ihrem Log-Status.
final medDayProvider = StreamProvider<List<DoseStatus>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  final day = ref.watch(selectedMedDayProvider);
  return ref.watch(medicationRepositoryProvider).watchDay(scope, day);
});

/// Plant die Erinnerungen neu, sobald sich Pläne oder der globale Schalter
/// ändern. Läuft als Seiteneffekt eines beobachteten Providers.
final medicationReminderSyncProvider = Provider<void>((ref) {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.medicationRemindersEnabled),
  );
  // Auf Planänderungen reagieren (Inhalt egal, nur der Trigger zählt).
  ref.watch(medicationPlansProvider);

  // Der Wecker-Modus steckt in den Zustelldetails: beim Umschalten muss neu
  // geplant werden, sonst behalten vorgemerkte Erinnerungen die alte Art.
  final wake = ref.watch(
    appSettingsProvider.select((s) => s.wakeScreenEnabled),
  );
  ref.watch(notificationServiceProvider).wakeScreen = wake;

  final scheduler = ref.watch(medicationReminderSchedulerProvider);
  scheduler.reschedule(enabled: enabled);
});
