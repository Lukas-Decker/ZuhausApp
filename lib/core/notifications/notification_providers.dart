import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import 'notification_service.dart';

/// Wird in `main()` nach der Initialisierung überschrieben.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('NotificationService nicht initialisiert'),
);

/// Stand der Systemrechte für Erinnerungen (Benachrichtigungen, exakte Alarme).
///
/// `ref.invalidate(notificationPermissionsProvider)` nach einer Anfrage neu
/// auswerten lassen.
final notificationPermissionsProvider =
    FutureProvider<
      ({
        bool notificationsAllowed,
        bool exactAlarmsAllowed,
        bool fullScreenAllowed,
      })
    >((ref) => ref.watch(notificationServiceProvider).checkPermissions());

/// Reicht Wecker-Modus, Timeout, Ton und Vibration aus den Einstellungen an
/// den Dienst durch, damit neue Erinnerungen entsprechend zugestellt werden.
/// In der AppShell beobachtet.
///
/// Wirkt auf neu geplante Erinnerungen: Android friert die Eigenschaften eines
/// Kanals beim Anlegen ein, deshalb traegt jede Kombination eine eigene
/// Kanal-Kennung.
final wakeScreenSyncProvider = Provider<void>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final service = ref.watch(notificationServiceProvider);
  service.wakeScreen = settings.wakeScreenEnabled;
  service.wakeTimeoutMinutes = settings.wakeTimeoutMinutes;
  service.soundEnabled = settings.reminderSoundEnabled;
  service.vibrationEnabled = settings.reminderVibrationEnabled;
});

/// Fragt beim Start einmalig die Benachrichtigungsberechtigung an, wenn sie
/// noch fehlt. Ohne sie kommen gar keine Erinnerungen an. In der AppShell
/// beobachtet.
final notificationPermissionRequestProvider = Provider<void>((ref) {
  Future.microtask(() async {
    final service = ref.read(notificationServiceProvider);
    final status = await service.checkPermissions();
    if (!status.notificationsAllowed) {
      await service.requestPermission();
      ref.invalidate(notificationPermissionsProvider);
    }
  });
});
