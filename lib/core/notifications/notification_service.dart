import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../app_info.dart';
import '../diagnostics/debug_log.dart';

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

/// Reaktion auf eine Benachrichtigung (Tippen oder Aktions-Button).
class NotificationAction {
  const NotificationAction({this.actionId, this.payload});

  /// z.B. [medTaken] oder [medSnooze]; `null` beim einfachen Antippen.
  final String? actionId;
  final String? payload;
}

/// Aktions-Kennungen der Medikamenten-Benachrichtigung.
const medTakenActionId = 'med_taken';
const medSnoozeActionId = 'med_snooze';
const _medCategoryId = 'med_reminder';

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
  static const _familyChannelId = 'family_events';

  /// Anhang fuer die Wecker-Varianten der Kanaele (siehe [_detailsFor]).
  ///
  /// Frueher '_wake'. Der Kanal hat seit v0.22 zusaetzlich die Ausnahme von
  /// "Bitte nicht stoeren", und Android uebernimmt Aenderungen an einem
  /// bestehenden Kanal nicht: nur eine neue Kennung greift. Die alten
  /// '_wake'-Kanaele bleiben ungenutzt in den Systemeinstellungen stehen.
  static const _wakeChannelSuffix = '_alarm';

  /// Kanal zur nativen Seite (Statusabfrage fuer Vollbild-Meldungen).
  static const _wakeChannel = MethodChannel('de.lukas.multiapp/wake');

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _supported = false;

  final StreamController<NotificationAction> _actions =
      StreamController<NotificationAction>.broadcast();

  /// Strom der Benutzer-Reaktionen auf Benachrichtigungen.
  Stream<NotificationAction> get actions => _actions.stream;

  bool get isSupported => _supported;

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
      final darwinInit = DarwinInitializationSettings(
        notificationCategories: [
          DarwinNotificationCategory(
            _medCategoryId,
            actions: [
              DarwinNotificationAction.plain(medTakenActionId, 'Genommen'),
              DarwinNotificationAction.plain(medSnoozeActionId, 'Snooze'),
            ],
          ),
        ],
      );
      const linuxInit = LinuxInitializationSettings(
        defaultActionName: 'Öffnen',
      );
      const windowsInit = WindowsInitializationSettings(
        appName: appName,
        appUserModelId: 'de.lukas.multiapp',
        guid: 'a3f1c2d4-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
      );

      await _plugin.initialize(
        settings: InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
          linux: linuxInit,
          windows: windowsInit,
        ),
        onDidReceiveNotificationResponse: _onResponse,
      );

      _supported = true;
      DebugLog.instance.add(
        'notifications',
        'Bereit, Zeitzone ${tz.local.name}',
      );
    } catch (error, stack) {
      // Scheitert das hier, bleibt die App still: keine einzige Erinnerung.
      // Deshalb prominent ins Protokoll.
      DebugLog.instance.error(
        'notifications',
        'Initialisierung fehlgeschlagen - es kommen KEINE Erinnerungen an',
        error: error,
        stack: stack,
      );
      _supported = false;
    }
    _ready = true;
  }

  void _onResponse(NotificationResponse response) {
    _actions.add(
      NotificationAction(
        actionId: response.actionId,
        payload: response.payload,
      ),
    );
  }

  /// Wurde die App durch Antippen einer Benachrichtigung gestartet, liefert
  /// dies die zugehoerige Aktion (damit der Aufrufer navigieren kann).
  Future<NotificationAction?> initialAction() async {
    if (!_supported) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response != null) {
        return NotificationAction(
          actionId: response.actionId,
          payload: response.payload,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Aktueller Stand der Android-Systemrechte fuer Erinnerungen.
  ///
  /// [notificationsAllowed] ist die POST_NOTIFICATIONS-Berechtigung (Android
  /// 13+), [exactAlarmsAllowed] das Recht "Alarme & Erinnerungen" (Android
  /// 12+). Ohne letzteres kommen zeitgenaue Erinnerungen nicht an.
  /// [dndBypassAllowed] erlaubt die Ausnahme von "Bitte nicht stören".
  Future<
    ({
      bool notificationsAllowed,
      bool exactAlarmsAllowed,
      bool fullScreenAllowed,
      bool dndBypassAllowed,
    })
  >
  checkPermissions() async {
    if (!_supported) {
      return (
        notificationsAllowed: false,
        exactAlarmsAllowed: false,
        fullScreenAllowed: false,
        dndBypassAllowed: false,
      );
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return (
          notificationsAllowed: await android.areNotificationsEnabled() ?? false,
          exactAlarmsAllowed:
              await android.canScheduleExactNotifications() ?? true,
          fullScreenAllowed: await canUseFullScreenIntent(),
          dndBypassAllowed: await canBypassDnd(),
        );
      }
      // Andere Plattformen kennen diese Trennung nicht.
      return (
        notificationsAllowed: true,
        exactAlarmsAllowed: true,
        fullScreenAllowed: true,
        dndBypassAllowed: true,
      );
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Rechte konnten nicht geprueft werden',
        error: error,
      );
      return (
        notificationsAllowed: false,
        exactAlarmsAllowed: false,
        fullScreenAllowed: false,
        dndBypassAllowed: false,
      );
    }
  }

  /// Oeffnet die Android-Systemseite "Alarme & Erinnerungen".
  Future<void> requestExactAlarms() async {
    if (!_supported) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    } catch (error) {
      debugPrint('requestExactAlarms fehlgeschlagen: $error');
    }
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
    } catch (error, stack) {
      DebugLog.instance.error(
        'notifications',
        'Planen fehlgeschlagen: ${reminder.title}',
        error: error,
        stack: stack,
      );
    }
  }

  /// Zeigt eine Benachrichtigung sofort (z.B. Familien-Ereignis).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String channel = _familyChannelId,
    String? payload,
  }) async {
    if (!_supported) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _detailsFor(channel),
        payload: payload,
      );
    } catch (error) {
      debugPrint('show fehlgeschlagen: $error');
    }
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Alle beim System vorgemerkten Erinnerungen (Diagnose).
  Future<List<PendingNotificationRequest>> pending() async {
    if (!_supported) return const [];
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (error) {
      debugPrint('pending fehlgeschlagen: $error');
      return const [];
    }
  }

  /// Loescht nur Erinnerungen, deren Payload mit [prefix] beginnt.
  ///
  /// Ersetzt das fruehere pauschale [cancelAll] in den Planern: sonst
  /// entfernt der eine Planer die Erinnerungen aller anderen.
  Future<void> cancelWithPayloadPrefix(String prefix) async {
    if (!_supported) return;
    try {
      for (final request in await _plugin.pendingNotificationRequests()) {
        if (request.payload?.startsWith(prefix) ?? false) {
          await _plugin.cancel(id: request.id);
        }
      }
    } catch (error) {
      debugPrint('cancelWithPayloadPrefix fehlgeschlagen: $error');
    }
  }

  /// Name der erkannten Zeitzone (Diagnose). Stimmt sie nicht, laufen alle
  /// geplanten Zeiten falsch.
  String get timeZoneName => _supported ? tz.local.name : 'unbekannt';

  /// Erinnerungen wie ein Wecker zustellen: Bildschirm aufwecken, ueber dem
  /// Sperrbildschirm anzeigen. Wird aus den Einstellungen gesetzt.
  bool wakeScreen = false;

  /// Sekunden, nach denen eine Wecker-Meldung von selbst verschwindet.
  /// 0 heisst: bleibt liegen, bis jemand reagiert.
  int wakeTimeoutSeconds = 120;

  /// Ob Erinnerungen einen Ton abspielen bzw. vibrieren.
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  /// Ob Android die Ausnahme von "Bitte nicht stören" akzeptiert.
  ///
  /// Ohne die Freigabe wird das Kennzeichen am Kanal ignoriert. Weil ein
  /// einmal angelegter Kanal nicht mehr nachträglich geändert werden kann,
  /// steckt der Zustand in der Kanal-Kennung: nach dem Erteilen entsteht ein
  /// neuer Kanal, der die Ausnahme wirklich hat.
  bool dndBypassAllowed = false;

  /// Kraeftiges Muster fuer den Wecker-Modus: lange Stoesse mit Pausen,
  /// deutlich hartnaeckiger als das kurze Standard-Zucken.
  static final Int64List _alarmVibration = Int64List.fromList(const [
    0,
    800,
    400,
    800,
    400,
    800,
    400,
    1200,
  ]);

  /// Fragt die Android-Sonderberechtigung fuer Vollbild-Meldungen an
  /// (ab Android 14 noetig, davor automatisch erteilt).
  Future<bool> requestFullScreenIntentPermission() async {
    if (!_supported) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true;
      await android.requestFullScreenIntentPermission();
      // Der Rueckgabewert der Anfrage sagt nur, dass die Systemseite geoeffnet
      // wurde. Den echten Stand liefert erst die Abfrage danach.
      return canUseFullScreenIntent();
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Vollbild-Berechtigung nicht anfragbar',
        error: error,
      );
      return false;
    }
  }

  /// Ob die App eine Ausnahme von "Bitte nicht stören" setzen darf.
  ///
  /// Ohne diese Freigabe ignoriert Android das Kennzeichen am Kanal: die
  /// Wecker-Erinnerung bliebe im Nicht-stören-Modus still.
  Future<bool> canBypassDnd() async {
    if (!_platformSupported || !Platform.isAndroid) return false;
    try {
      return await _wakeChannel.invokeMethod<bool>('canBypassDnd') ?? false;
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Nicht-stoeren-Status nicht abfragbar',
        error: error,
      );
      return false;
    }
  }

  /// Öffnet die Systemseite, auf der die Nicht-stören-Ausnahme erteilt wird.
  Future<void> openDndAccessSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('openDndAccessSettings');
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Nicht-stoeren-Einstellung nicht zu oeffnen',
        error: error,
      );
    }
  }

  /// Lässt das Gerät im Wecker-Muster vibrieren, unabhängig davon, ob die
  /// Vibration für Benachrichtigungen abgeschaltet ist.
  ///
  /// [maxSeconds] ist eine harte Obergrenze auf der nativen Seite: bleibt
  /// [stopAlarmVibration] aus, hört es trotzdem auf.
  Future<void> startAlarmVibration({int maxSeconds = 120}) async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('startAlarmVibration', {
        'maxMillis': maxSeconds.clamp(5, 15 * 60) * 1000,
      });
    } catch (error) {
      DebugLog.instance.warn('notifications', 'Vibration', error: error);
    }
  }

  /// Erlaubt der App, über dem Sperrbildschirm zu erscheinen.
  ///
  /// Nur für den Wecker-Schirm einer fälligen Einnahme gedacht und danach
  /// sofort wieder zurückzunehmen: sonst wäre die ganze App bei gesperrtem
  /// Telefon bedienbar.
  Future<void> setShowWhenLocked(bool allow) async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('setShowWhenLocked', {
        'allow': allow,
      });
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Sperrbildschirm-Anzeige nicht umschaltbar',
        error: error,
      );
    }
  }

  /// Beendet die Wecker-Anzeige: nimmt das Sperrbildschirm-Recht zurück und
  /// schickt die App bei gesperrtem Telefon in den Hintergrund.
  ///
  /// Ohne das Zweite bliebe die App bedienbar, sobald sie einmal über der
  /// Sperre stand: das Recht steuert nur, ob sie erscheinen darf.
  Future<void> endAlarmPresentation() async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('endAlarmPresentation');
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Wecker-Anzeige nicht beendbar',
        error: error,
      );
    }
  }

  Future<void> stopAlarmVibration() async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('stopAlarmVibration');
    } catch (_) {}
  }

  /// Spielt den Weckerton des Geräts über den Alarm-Kanal ab.
  ///
  /// Der Ton der Benachrichtigung selbst bleibt bei stummem Telefon still,
  /// weil Android ihn dem Benachrichtigungskanal zuordnet. Hier spielt die
  /// App ihn selbst, mit denselben Attributen wie ein Wecker.
  Future<void> startAlarmSound({int maxSeconds = 120}) async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('startAlarmSound', {
        'maxMillis': maxSeconds.clamp(5, 15 * 60) * 1000,
      });
    } catch (error) {
      DebugLog.instance.warn('notifications', 'Weckerton', error: error);
    }
  }

  Future<void> stopAlarmSound() async {
    if (!Platform.isAndroid) return;
    try {
      await _wakeChannel.invokeMethod<void>('stopAlarmSound');
    } catch (_) {}
  }

  /// Ob Vollbild-Meldungen (Bildschirm aufwecken) erlaubt sind.
  ///
  /// Fragt nativ nach; ab Android 14 muss der Nutzer das eigens freigeben.
  Future<bool> canUseFullScreenIntent() async {
    if (!_platformSupported || !Platform.isAndroid) return false;
    try {
      final result = await _wakeChannel.invokeMethod<bool>(
        'canUseFullScreenIntent',
      );
      return result ?? false;
    } catch (error) {
      DebugLog.instance.warn(
        'notifications',
        'Vollbild-Status nicht abfragbar',
        error: error,
      );
      return false;
    }
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
      _familyChannelId => ('Familie', 'Ereignisse aus deinem Haushalt'),
      _ => ('Medikamenten-Erinnerungen', 'Einnahme-Erinnerungen'),
    };

    final isMed = channel == _medicationChannelId;

    // Android friert die Einstellungen eines Kanals beim Anlegen ein. Jede
    // Kombination bekommt deshalb einen eigenen Kanal, sonst bliebe die
    // urspruengliche Wichtigkeit bzw. Ton/Vibration bestehen.
    final wake = wakeScreen;
    final bypassDnd = wake && dndBypassAllowed;
    final variants = [
      if (bypassDnd) 'Wecker, auch bei Nicht stören' else if (wake) 'Wecker',
      if (!soundEnabled) 'ohne Ton',
      if (!vibrationEnabled) 'ohne Vibration',
    ];
    final channelId = [
      channel,
      if (wake) _wakeChannelSuffix,
      if (bypassDnd) '_dnd',
      if (!soundEnabled) '_ns',
      if (!vibrationEnabled) '_nv',
    ].join();
    final channelName = variants.isEmpty
        ? name
        : '$name (${variants.join(', ')})';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: description,
        importance: wake ? Importance.max : Importance.high,
        priority: wake ? Priority.max : Priority.high,
        category: wake
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        // Weckt den Bildschirm und zeigt die Meldung ueber dem Sperrbildschirm.
        fullScreenIntent: wake,
        // Wecker gehen auch durch "Bitte nicht stoeren", sofern die Freigabe
        // dafuer vorliegt.
        channelBypassDnd: bypassDnd,
        visibility: wake ? NotificationVisibility.public : null,
        // Damit der Wecker nicht endlos leuchtet: Android nimmt die Meldung
        // nach dieser Zeit selbst wieder weg.
        timeoutAfter: wake && wakeTimeoutSeconds > 0
            ? wakeTimeoutSeconds * 1000
            : null,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        vibrationPattern: vibrationEnabled && wake ? _alarmVibration : null,
        audioAttributesUsage: wake
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        actions: isMed
            ? const [
                AndroidNotificationAction(medTakenActionId, 'Genommen'),
                AndroidNotificationAction(medSnoozeActionId, 'Snooze'),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: isMed ? _medCategoryId : null,
      ),
      macOS: DarwinNotificationDetails(
        categoryIdentifier: isMed ? _medCategoryId : null,
      ),
      linux: LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  void dispose() {
    _actions.close();
  }

  static const medicationChannel = _medicationChannelId;
  static const petChannel = _petChannelId;
  static const inventoryChannel = _inventoryChannelId;
  static const familyChannel = _familyChannelId;
}

/// Wandelt einen Schlüssel stabil in eine 31-Bit-Notification-ID um.
int notificationIdFromKey(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}
