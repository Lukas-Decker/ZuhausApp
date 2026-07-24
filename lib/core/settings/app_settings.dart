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
    required this.medicationRemindersEnabled,
    required this.petRemindersEnabled,
    required this.healthDataConsent,
    required this.familyPushEnabled,
    required this.medEscalationEnabled,
    required this.petOverdueEnabled,
    required this.appLockEnabled,
    required this.retentionDays,
    required this.privacyAccepted,
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

  /// Globaler Schalter für Medikamenten-Erinnerungen. Zusätzlich hat jeder
  /// Plan einen eigenen Schalter.
  final bool medicationRemindersEnabled;

  /// Globaler Schalter für Tier-Erinnerungen.
  final bool petRemindersEnabled;

  /// Einwilligung in die Verarbeitung von Gesundheitsdaten (DSGVO Art. 9),
  /// nötig bevor der Pillen-Tracker genutzt wird. `null` = noch nicht gefragt.
  final bool? healthDataConsent;

  /// Empfang von Familien-Ereignissen als Benachrichtigung.
  final bool familyPushEnabled;

  /// Eskalation nicht bestätigter Einnahmen an die Betreuungsperson.
  final bool medEscalationEnabled;

  /// Meldung überfälliger Tier-Aufgaben an den Haushalt.
  final bool petOverdueEnabled;

  /// Biometrisches App-Schloss (Windows Hello / Fingerabdruck / Gesicht).
  final bool appLockEnabled;

  /// Aufbewahrungsfrist in Tagen: geloeschte Datensaetze und alte
  /// Audit-Eintraege werden danach endgueltig entfernt. 0 bedeutet: nie.
  final int retentionDays;

  /// Ob der Datenschutz-Hinweis beim ersten Start bestaetigt wurde.
  final bool privacyAccepted;

  AppSettings copyWith({
    Object? openFoodFactsConsent = _unset,
    bool? expiryWarningsEnabled,
    int? expiryWarningDays,
    bool? medicationRemindersEnabled,
    bool? petRemindersEnabled,
    Object? healthDataConsent = _unset,
    bool? familyPushEnabled,
    bool? medEscalationEnabled,
    bool? petOverdueEnabled,
    bool? appLockEnabled,
    int? retentionDays,
    bool? privacyAccepted,
  }) => AppSettings(
    openFoodFactsConsent: openFoodFactsConsent == _unset
        ? this.openFoodFactsConsent
        : openFoodFactsConsent as bool?,
    expiryWarningsEnabled: expiryWarningsEnabled ?? this.expiryWarningsEnabled,
    expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
    medicationRemindersEnabled:
        medicationRemindersEnabled ?? this.medicationRemindersEnabled,
    petRemindersEnabled: petRemindersEnabled ?? this.petRemindersEnabled,
    healthDataConsent: healthDataConsent == _unset
        ? this.healthDataConsent
        : healthDataConsent as bool?,
    familyPushEnabled: familyPushEnabled ?? this.familyPushEnabled,
    medEscalationEnabled: medEscalationEnabled ?? this.medEscalationEnabled,
    petOverdueEnabled: petOverdueEnabled ?? this.petOverdueEnabled,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    retentionDays: retentionDays ?? this.retentionDays,
    privacyAccepted: privacyAccepted ?? this.privacyAccepted,
  );

  static const Object _unset = Object();
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _keyOffConsent = 'consent.openfoodfacts';
  static const _keyHealthConsent = 'consent.healthdata';
  static const _keyExpiryEnabled = 'reminder.expiry.enabled';
  static const _keyExpiryDays = 'reminder.expiry.days';
  static const _keyMedsEnabled = 'reminder.medication.enabled';
  static const _keyPetsEnabled = 'reminder.pet.enabled';
  static const _keyFamilyPush = 'reminder.family.enabled';
  static const _keyMedEscalation = 'reminder.med.escalation';
  static const _keyPetOverdue = 'reminder.pet.overdue';
  static const _keyAppLock = 'security.applock.enabled';
  static const _keyRetentionDays = 'privacy.retention.days';
  static const _keyPrivacyAccepted = 'privacy.accepted';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      openFoodFactsConsent: prefs.getBool(_keyOffConsent),
      expiryWarningsEnabled: prefs.getBool(_keyExpiryEnabled) ?? true,
      expiryWarningDays: prefs.getInt(_keyExpiryDays) ?? 5,
      medicationRemindersEnabled: prefs.getBool(_keyMedsEnabled) ?? true,
      petRemindersEnabled: prefs.getBool(_keyPetsEnabled) ?? true,
      healthDataConsent: prefs.getBool(_keyHealthConsent),
      familyPushEnabled: prefs.getBool(_keyFamilyPush) ?? true,
      medEscalationEnabled: prefs.getBool(_keyMedEscalation) ?? true,
      petOverdueEnabled: prefs.getBool(_keyPetOverdue) ?? true,
      appLockEnabled: prefs.getBool(_keyAppLock) ?? false,
      retentionDays: prefs.getInt(_keyRetentionDays) ?? 90,
      privacyAccepted: prefs.getBool(_keyPrivacyAccepted) ?? false,
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

  Future<void> setHealthDataConsent(bool granted) async {
    await _prefs.setBool(_keyHealthConsent, granted);
    state = state.copyWith(healthDataConsent: granted);
  }

  Future<void> setExpiryWarningsEnabled(bool enabled) async {
    await _prefs.setBool(_keyExpiryEnabled, enabled);
    state = state.copyWith(expiryWarningsEnabled: enabled);
  }

  Future<void> setExpiryWarningDays(int days) async {
    await _prefs.setInt(_keyExpiryDays, days);
    state = state.copyWith(expiryWarningDays: days);
  }

  Future<void> setMedicationRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyMedsEnabled, enabled);
    state = state.copyWith(medicationRemindersEnabled: enabled);
  }

  Future<void> setPetRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyPetsEnabled, enabled);
    state = state.copyWith(petRemindersEnabled: enabled);
  }

  Future<void> setFamilyPushEnabled(bool enabled) async {
    await _prefs.setBool(_keyFamilyPush, enabled);
    state = state.copyWith(familyPushEnabled: enabled);
  }

  Future<void> setMedEscalationEnabled(bool enabled) async {
    await _prefs.setBool(_keyMedEscalation, enabled);
    state = state.copyWith(medEscalationEnabled: enabled);
  }

  Future<void> setPetOverdueEnabled(bool enabled) async {
    await _prefs.setBool(_keyPetOverdue, enabled);
    state = state.copyWith(petOverdueEnabled: enabled);
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _prefs.setBool(_keyAppLock, enabled);
    state = state.copyWith(appLockEnabled: enabled);
  }

  Future<void> setRetentionDays(int days) async {
    await _prefs.setInt(_keyRetentionDays, days);
    state = state.copyWith(retentionDays: days);
  }

  Future<void> setPrivacyAccepted(bool accepted) async {
    await _prefs.setBool(_keyPrivacyAccepted, accepted);
    state = state.copyWith(privacyAccepted: accepted);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );
