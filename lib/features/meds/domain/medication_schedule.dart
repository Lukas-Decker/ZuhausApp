import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../core/i18n/app_texts.dart';
import '../../../l10n/app_localizations.dart';

/// Darreichungsformen mit Symbol.
///
/// [label] ist der Name der Form in der Oberfläche, [one] und [many] sind
/// die Wörter für eine Mengenangabe ("1 Tablette", "2 Tabletten").
const Map<String, ({String label, String one, String many, IconData icon})>
medicationForms = {
  'tablet': (
    label: 'Tablette',
    one: 'Tablette',
    many: 'Tabletten',
    icon: Icons.medication_rounded,
  ),
  'capsule': (
    label: 'Kapsel',
    one: 'Kapsel',
    many: 'Kapseln',
    icon: Icons.medication_liquid_rounded,
  ),
  'drop': (
    label: 'Tropfen',
    one: 'Tropfen',
    many: 'Tropfen',
    icon: Icons.water_drop_rounded,
  ),
  'spray': (
    label: 'Spray',
    one: 'Sprühstoß',
    many: 'Sprühstöße',
    icon: Icons.air_rounded,
  ),
  'injection': (
    label: 'Spritze',
    one: 'Spritze',
    many: 'Spritzen',
    icon: Icons.vaccines_rounded,
  ),
  'ointment': (
    label: 'Salbe',
    one: 'Anwendung',
    many: 'Anwendungen',
    icon: Icons.healing_rounded,
  ),
  'other': (
    label: 'Sonstiges',
    one: 'Einheit',
    many: 'Einheiten',
    icon: Icons.medical_services_rounded,
  ),
};

({String label, String one, String many, IconData icon}) medicationForm(
  String key,
) => medicationForms[key] ?? medicationForms['other']!;

/// Menge und Form als ein Text: "2 Tabletten", "1 Kapsel", "10 Tropfen".
///
/// Die Mehrzahlregeln stehen in den ARB-Dateien, damit sie je Sprache
/// stimmen. Ohne [l10n] (Dienste ohne BuildContext) gelten die Texte der
/// zuletzt geladenen Sprache.
///
/// Ohne Mengenangabe bleibt nur die Form ("Tablette"). Steht in der Dosis
/// schon eine eigene Einheit ("5 ml", "1 TL"), wird sie unverändert
/// übernommen: "5 ml Tropfen" wäre Unsinn.
String medicationDoseLabel(
  String formKey,
  String dosage, [
  AppLocalizations? l10n,
]) {
  final texts = l10n ?? AppTexts.current;
  final trimmed = dosage.trim();
  final amount = double.tryParse(trimmed.replaceAll(',', '.'));

  // Eigene Einheit oder Freitext: unveraendert lassen.
  if (trimmed.isNotEmpty && amount == null) return trimmed;

  final count = amount ?? 1;
  final label = switch (formKey) {
    'tablet' => texts.medsDoseTablet(count, trimmed),
    'capsule' => texts.medsDoseCapsule(count, trimmed),
    'drop' => texts.medsDoseDrop(count, trimmed),
    'spray' => texts.medsDoseSpray(count, trimmed),
    'injection' => texts.medsDoseInjection(count, trimmed),
    'ointment' => texts.medsDoseOintment(count, trimmed),
    _ => texts.medsDoseOther(count, trimmed),
  };
  // Ohne Menge bleibt ein fuehrendes Leerzeichen stehen.
  return label.trim();
}

/// Name der Darreichungsform in der Sprache der Oberfläche.
String medicationFormLabel(String formKey, [AppLocalizations? l10n]) {
  final texts = l10n ?? AppTexts.current;
  return switch (formKey) {
    'tablet' => texts.medsFormTablet,
    'capsule' => texts.medsFormCapsule,
    'drop' => texts.medsFormDrop,
    'spray' => texts.medsFormSpray,
    'injection' => texts.medsFormInjection,
    'ointment' => texts.medsFormOintment,
    _ => texts.medsFormOther,
  };
}

enum ScheduleType {
  daily('daily'),
  scheme('scheme'),
  interval('interval');

  const ScheduleType(this.key);

  final String key;

  String label([AppLocalizations? l10n]) {
    final texts = l10n ?? AppTexts.current;
    return switch (this) {
      ScheduleType.daily => texts.medsScheduleDaily,
      ScheduleType.scheme => texts.medsScheduleScheme,
      ScheduleType.interval => texts.medsScheduleInterval,
    };
  }

  static ScheduleType parse(String? value) => ScheduleType.values
      .firstWhere((s) => s.key == value, orElse: () => ScheduleType.daily);
}

/// Einnahmehinweise mit kurzer Erklärung hinter dem Fragezeichen.
enum IntakeHint {
  fasting('fasting'),
  withFood('with_food'),
  beforeFood('before_food'),
  afterFood('after_food'),
  upright('upright'),
  water('water'),
  noDairy('no_dairy'),
  noAlcohol('no_alcohol'),
  avoidSun('avoid_sun');

  const IntakeHint(this.key);

  final String key;

  String label([AppLocalizations? l10n]) {
    final texts = l10n ?? AppTexts.current;
    return switch (this) {
      IntakeHint.fasting => texts.medsHintFasting,
      IntakeHint.withFood => texts.medsHintWithFood,
      IntakeHint.beforeFood => texts.medsHintBeforeFood,
      IntakeHint.afterFood => texts.medsHintAfterFood,
      IntakeHint.upright => texts.medsHintUpright,
      IntakeHint.water => texts.medsHintWater,
      IntakeHint.noDairy => texts.medsHintNoDairy,
      IntakeHint.noAlcohol => texts.medsHintNoAlcohol,
      IntakeHint.avoidSun => texts.medsHintAvoidSun,
    };
  }

  /// Was der Hinweis bedeutet, in einem Satz.
  String explanation([AppLocalizations? l10n]) {
    final texts = l10n ?? AppTexts.current;
    return switch (this) {
      IntakeHint.fasting => texts.medsHintFastingInfo,
      IntakeHint.withFood => texts.medsHintWithFoodInfo,
      IntakeHint.beforeFood => texts.medsHintBeforeFoodInfo,
      IntakeHint.afterFood => texts.medsHintAfterFoodInfo,
      IntakeHint.upright => texts.medsHintUprightInfo,
      IntakeHint.water => texts.medsHintWaterInfo,
      IntakeHint.noDairy => texts.medsHintNoDairyInfo,
      IntakeHint.noAlcohol => texts.medsHintNoAlcoholInfo,
      IntakeHint.avoidSun => texts.medsHintAvoidSunInfo,
    };
  }

  /// Liest die gespeicherte Liste ("fasting,water"), unbekannte Schlüssel
  /// werden übergangen.
  static List<IntakeHint> parseAll(String csv) => csv
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map(
        (key) => IntakeHint.values.where((h) => h.key == key).firstOrNull,
      )
      .whereType<IntakeHint>()
      .toList();

  static String formatAll(Iterable<IntakeHint> hints) =>
      hints.map((h) => h.key).join(',');
}

/// Status eines Einnahmeereignisses.
enum IntakeStatus {
  taken('taken', 'Genommen', Icons.check_circle_rounded),
  skipped('skipped', 'Ausgelassen', Icons.cancel_rounded),
  postponed('postponed', 'Verschoben', Icons.snooze_rounded);

  const IntakeStatus(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static IntakeStatus parse(String? value) => IntakeStatus.values
      .firstWhere((s) => s.key == value, orElse: () => IntakeStatus.taken);
}

/// Hilfsfunktionen rund um die Uhrzeitenliste eines Plans.
abstract final class ScheduleTimes {
  static List<TimeOfDay> parse(String csv) {
    return csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(_parseTime)
        .whereType<TimeOfDay>()
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
  }

  static String format(List<TimeOfDay> times) {
    final sorted = [...times]
      ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    return sorted.map(formatTime).join(',');
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Einzelne Uhrzeit "HH:mm" lesen, `null` bei Unsinn.
  static TimeOfDay? parseTime(String value) => _parseTime(value);

  static TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }
}

/// Wochentage eines Plans. Leer bedeutet: jeden Tag.
abstract final class ScheduleWeekdays {
  static const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static Set<int> parse(String csv) => csv
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .where((d) => d >= 1 && d <= 7)
      .toSet();

  static String format(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted.join(',');
  }

  static bool includes(String csv, int weekday) {
    final days = parse(csv);
    return days.isEmpty || days.contains(weekday);
  }

  static String describe(String csv) {
    final days = parse(csv);
    if (days.isEmpty || days.length == 7) return 'Täglich';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return 'Werktags';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Wochenende';
    }
    final sorted = days.toList()..sort();
    return sorted.map((d) => labels[d - 1]).join(', ');
  }
}
