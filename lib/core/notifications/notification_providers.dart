import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// Wird in `main()` nach der Initialisierung überschrieben.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('NotificationService nicht initialisiert'),
);
