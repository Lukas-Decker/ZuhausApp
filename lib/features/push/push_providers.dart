import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_providers.dart';
import '../auth/auth_providers.dart';
import 'fcm_service.dart';

final fcmServiceProvider = Provider<FcmService>(
  (ref) => FcmService(ref.watch(notificationServiceProvider)),
);

/// Initialisiert FCM, sobald ein Nutzer angemeldet ist (nur Android; der Dienst
/// prueft die Plattform selbst). In der AppShell beobachtet.
final fcmInitProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  Future.microtask(() => ref.read(fcmServiceProvider).init());
});
