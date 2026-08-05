import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    FutureProvider<({bool notificationsAllowed, bool exactAlarmsAllowed})>(
      (ref) => ref.watch(notificationServiceProvider).checkPermissions(),
    );

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
