import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/deeplink/windows_deeplink.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers.dart';
import 'data/db/app_database.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Deutsche Datums- und Zahlenformate für intl bereitstellen.
  await initializeDateFormatting('de');

  final prefs = await SharedPreferences.getInstance();
  final database = AppDatabase();

  final notifications = NotificationService();
  await notifications.init();

  // Supabase nur starten, wenn Zugangsdaten vorliegen; sonst Gastmodus.
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Der oeffentliche Schluessel des Projekts (im Dashboard "anon"/
      // "publishable key").
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    // Custom-URL-Schema bei Windows registrieren, damit OAuth-Rueckwege und
    // Passwort-Reset auch auf dem Desktop in die App zurueckkommen.
    await registerWindowsDeepLinkScheme();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(database),
        notificationServiceProvider.overrideWithValue(notifications),
        authServiceProvider.overrideWithValue(AuthService.resolve()),
      ],
      child: const MultiApp(),
    ),
  );
}
