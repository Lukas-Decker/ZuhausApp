import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';

/// Geräteweite Einstellungen und erteilte Einwilligungen.
@immutable
class AppSettings {
  const AppSettings({
    required this.openFoodFactsConsent,
    required this.expiryWarningsEnabled,
    required this.expiryWarningDays,
  });

  /// `null` bedeutet: noch nicht gefragt.
  ///
  /// Die Produktabfrage bei Open Food Facts überträgt den Barcode an einen
  /// Dritten und braucht deshalb eine eigene, widerrufbare Einwilligung.
  final bool? openFoodFactsConsent;

  /// Globaler Schalter für Ablaufwarnungen. Pro Artikel gibt es zusätzlich
  /// einen eigenen Schalter.
  final bool expiryWarningsEnabled;

  /// Wie viele Tage vorher gewarnt wird.
  final int expiryWarningDays;

  AppSettings copyWith({
    Object? openFoodFactsConsent = _unset,
    bool? expiryWarningsEnabled,
    int? expiryWarningDays,
  }) => AppSettings(
    openFoodFactsConsent: openFoodFactsConsent == _unset
        ? this.openFoodFactsConsent
        : openFoodFactsConsent as bool?,
    expiryWarningsEnabled: expiryWarningsEnabled ?? this.expiryWarningsEnabled,
    expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
  );

  static const Object _unset = Object();
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _keyOffConsent = 'consent.openfoodfacts';
  static const _keyExpiryEnabled = 'reminder.expiry.enabled';
  static const _keyExpiryDays = 'reminder.expiry.days';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      openFoodFactsConsent: prefs.getBool(_keyOffConsent),
      expiryWarningsEnabled: prefs.getBool(_keyExpiryEnabled) ?? true,
      expiryWarningDays: prefs.getInt(_keyExpiryDays) ?? 5,
    );
  }

  Future<void> setOpenFoodFactsConsent(bool granted) async {
    await _prefs.setBool(_keyOffConsent, granted);
    state = state.copyWith(openFoodFactsConsent: granted);
  }

  /// Setzt die Einwilligung zurück, sodass beim nächsten Scan erneut gefragt wird.
  Future<void> resetOpenFoodFactsConsent() async {
    await _prefs.remove(_keyOffConsent);
    state = state.copyWith(openFoodFactsConsent: null);
  }

  Future<void> setExpiryWarningsEnabled(bool enabled) async {
    await _prefs.setBool(_keyExpiryEnabled, enabled);
    state = state.copyWith(expiryWarningsEnabled: enabled);
  }

  Future<void> setExpiryWarningDays(int days) async {
    await _prefs.setInt(_keyExpiryDays, days);
    state = state.copyWith(expiryWarningDays: days);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
