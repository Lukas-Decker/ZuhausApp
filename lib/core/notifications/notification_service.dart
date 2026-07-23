import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Eine geplante lokale Erinnerung.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.payload,
  });

  /// Stabile, geräteweit eindeutige Zahl (aus einem String-Schlüssel abgeleitet).
  final int id;
  final String title;
  final String body;
  final DateTime when;
  final String? payload;
}

/// Kapselt lokale Benachrichtigungen und blendet Plattformunterschiede aus.
///
/// Erinnerungen werden auf dem Gerät geplant und funktionieren offline. Wo das
/// Betriebssystem keine geplanten Benachrichtigungen unterstützt (z.B. reine
/// Testumgebung), degradiert der Dienst still zu No-ops.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _medicationChannelId = 'medication_reminders';
  static const _petChannelId = 'pet_reminders';
  static const _inventoryChannelId = 'inventory_reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _supported = false;

  bool get isSupported => _supported;

  /// Auf welchen Plattformen geplante Benachrichtigungen unterstuetzt werden.
  static bool get _platformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isWindows;
  }

  Future<void> init() async {
    if (_ready || !_platformSupported) {
      _ready = true;
      return;
    }

    try {
      tzdata.initializeTimeZones();
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const linuxInit = LinuxInitializationSettings(
        defaultActionName: 'Öffnen',
      );
      const windowsInit = WindowsInitializationSettings(
        appName: 'MultiApp',
        appUserModelId: 'de.lukas.multiapp',
        guid: 'a3f1c2d4-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
      );

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
          linux: linuxInit,
          windows: windowsInit,
        ),
      );

      _supported = true;
    } catch (error, stack) {
      debugPrint('NotificationService init fehlgeschlagen: $error\n$stack');
      _supported = false;
    }
    _ready = true;
  }

  /// Fragt (auf Android/iOS) die Benachrichtigungsberechtigung an.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
        return granted ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      return true;
    } catch (error) {
      debugPrint('requestPermission fehlgeschlagen: $error');
      return false;
    }
  }

  Future<void> schedule(
    ScheduledReminder reminder, {
    String channel = _medicationChannelId,
  }) async {
    if (!_supported) return;
    if (reminder.when.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        notificationDetails: _detailsFor(channel),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: reminder.payload,
      );
    } catch (error) {
      debugPrint('schedule fehlgeschlagen: $error');
    }
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Entfernt alle geplanten Erinnerungen. Vor jedem Neuplanen aufgerufen,
  /// damit sich keine veralteten Termine ansammeln.
  Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  NotificationDetails _detailsFor(String channel) {
    final (name, description) = switch (channel) {
      _petChannelId => ('Tier-Erinnerungen', 'Fütterung, Arznei, Termine'),
      _inventoryChannelId => ('Vorrats-Warnungen', 'Ablaufende Lebensmittel'),
      _ => ('Medikamenten-Erinnerungen', 'Einnahme-Erinnerungen'),
    };

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        name,
        channelDescription: description,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  static const medicationChannel = _medicationChannelId;
  static const petChannel = _petChannelId;
  static const inventoryChannel = _inventoryChannelId;
}

/// Wandelt einen Schlüssel stabil in eine 31-Bit-Notification-ID um.
int notificationIdFromKey(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}
