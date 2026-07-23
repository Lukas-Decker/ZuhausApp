import '../../../core/notifications/notification_service.dart';
import '../../../data/repositories/inventory_repository.dart';

/// Plant die taegliche Sammelbenachrichtigung fuer bald ablaufende Vorraete.
///
/// Da lokale Benachrichtigungen ihren Text nicht erst beim Ausloesen berechnen,
/// wird der aktuelle Stand jeweils fuer den naechsten Morgen (09:00) geplant und
/// bei jeder Aenderung neu gesetzt.
class ExpiryNotificationScheduler {
  ExpiryNotificationScheduler({
    required this.inventory,
    required this.notifications,
  });

  static final int _notificationId = notificationIdFromKey('inventory-expiry');
  static const int _hour = 9;

  final InventoryRepository inventory;
  final NotificationService notifications;

  Future<void> reschedule({
    required bool enabled,
    required int warningDays,
  }) async {
    if (!notifications.isSupported) return;

    await notifications.cancel(_notificationId);
    if (!enabled) return;

    final items = await inventory.expiringSoon(warningDays);
    if (items.isEmpty) return;

    final names = items.take(4).map((i) => i.name).join(', ');
    final more = items.length > 4 ? ' und ${items.length - 4} weitere' : '';
    final count = items.length;
    final body = count == 1
        ? 'Ein Lebensmittel läuft bald ab: $names'
        : '$count Lebensmittel laufen bald ab: $names$more';

    await notifications.schedule(
      ScheduledReminder(
        id: _notificationId,
        title: 'Ablaufende Vorräte',
        body: body,
        when: _nextMorning(),
        payload: 'inventory:expiry',
      ),
      channel: NotificationService.inventoryChannel,
    );
  }

  static DateTime _nextMorning() {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, _hour);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }
}
