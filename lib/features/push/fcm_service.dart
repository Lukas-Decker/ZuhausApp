import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/notification_service.dart';

/// Hintergrund-Handler fuer FCM. Muss eine Top-Level-Funktion sein.
///
/// Bei "notification"-Nachrichten zeigt Android die Meldung selbst im
/// System-Tray an - hier ist nichts weiter zu tun. Der Handler muss aber
/// existieren und registriert sein, damit die Zustellung bei geschlossener App
/// funktioniert.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Bindet Firebase Cloud Messaging fuer echten Push bei geschlossener App an
/// (nur Android; Desktop bleibt beim Realtime-Weg).
///
/// Firebase ist optional: ohne google-services.json schlaegt die
/// Initialisierung fehl und der Dienst bleibt still, ohne die App zu stoeren.
class FcmService {
  FcmService(this._notifications);

  final NotificationService _notifications;
  bool _started = false;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (_started || !_supported) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (error) {
      // Keine google-services.json / Firebase nicht eingerichtet.
      debugPrint('[fcm] Firebase nicht konfiguriert, Push inaktiv: $error');
      return;
    }
    _started = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Im Vordergrund zeigt Android nichts von selbst: eigene lokale Meldung.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? 'MultiApp',
        body: notification.body ?? '',
      );
    });

    await _registerToken(await messaging.getToken());
    messaging.onTokenRefresh.listen(_registerToken);
  }

  /// Meldet den Geraete-Token beim Server an, damit die Edge Function ihn zum
  /// Senden findet.
  Future<void> _registerToken(String? token) async {
    if (token == null) return;
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;
    try {
      await client.rpc(
        'upsert_device_token',
        params: {'_token': token, '_platform': 'android'},
      );
    } catch (error) {
      debugPrint('[fcm] Token-Registrierung fehlgeschlagen: $error');
    }
  }

  /// Entfernt den Token bei der Abmeldung, damit keine Pushes mehr an dieses
  /// Geraet gehen.
  Future<void> deleteToken() async {
    if (!_supported || !_started) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client.rpc(
          'delete_device_token',
          params: {'_token': token},
        );
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('[fcm] Token-Abmeldung fehlgeschlagen: $error');
    }
  }
}
