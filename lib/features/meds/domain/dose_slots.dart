import 'package:flutter/material.dart';

import '../../../core/i18n/app_texts.dart';
import '../../../data/db/app_database.dart';
import '../../../l10n/app_localizations.dart';
import 'medication_schedule.dart';

/// Die vier Tageszeiten des klassischen Schemas ("1-0-1").
///
/// Beim Zeitplan-Modus `scheme` stehen in `times` immer alle vier Uhrzeiten
/// in genau dieser Reihenfolge, und in `doses` die zugehörigen Mengen. Eine
/// Menge von 0 (oder leer) bedeutet: zu dieser Tageszeit nichts einnehmen.
enum DoseSlot {
  morning(TimeOfDay(hour: 8, minute: 0), Icons.wb_twilight_rounded),
  noon(TimeOfDay(hour: 12, minute: 0), Icons.wb_sunny_rounded),
  evening(TimeOfDay(hour: 18, minute: 0), Icons.wb_twighlight),
  night(TimeOfDay(hour: 22, minute: 0), Icons.bedtime_rounded);

  const DoseSlot(this.defaultTime, this.icon);

  final TimeOfDay defaultTime;
  final IconData icon;

  String label([AppLocalizations? l10n]) {
    final texts = l10n ?? AppTexts.current;
    return switch (this) {
      DoseSlot.morning => texts.medsSlotMorning,
      DoseSlot.noon => texts.medsSlotNoon,
      DoseSlot.evening => texts.medsSlotEvening,
      DoseSlot.night => texts.medsSlotNight,
    };
  }
}

/// Ein Eintrag des Schemas: Tageszeit, Uhrzeit und Menge.
@immutable
class DoseSlotEntry {
  const DoseSlotEntry({
    required this.slot,
    required this.time,
    required this.amount,
  });

  final DoseSlot slot;
  final TimeOfDay time;

  /// Menge als Text, wie sie der Nutzer eingegeben hat. Leer oder "0"
  /// bedeutet: zu dieser Tageszeit keine Einnahme.
  final String amount;

  bool get isActive {
    final trimmed = amount.trim();
    if (trimmed.isEmpty) return false;
    final value = double.tryParse(trimmed.replaceAll(',', '.'));
    // Freitext ohne Zahl zaehlt als aktiv ("1 Beutel").
    return value == null || value > 0;
  }

  DoseSlotEntry copyWith({TimeOfDay? time, String? amount}) => DoseSlotEntry(
    slot: slot,
    time: time ?? this.time,
    amount: amount ?? this.amount,
  );
}

/// Liest und schreibt das Schema aus den Plan-Spalten `times` und `doses`.
abstract final class DoseScheme {
  /// Alle vier Tageszeiten eines Plans, auch die ohne Einnahme.
  static List<DoseSlotEntry> parse(String times, String doses) {
    final timeList = times.split(',').map((s) => s.trim()).toList();
    final doseList = doses.split(',').map((s) => s.trim()).toList();

    return [
      for (final (index, slot) in DoseSlot.values.indexed)
        DoseSlotEntry(
          slot: slot,
          time: index < timeList.length
              ? (ScheduleTimes.parseTime(timeList[index]) ?? slot.defaultTime)
              : slot.defaultTime,
          amount: index < doseList.length ? doseList[index] : '',
        ),
    ];
  }

  /// Uhrzeiten-CSV in fester Reihenfolge der Tageszeiten.
  static String formatTimes(List<DoseSlotEntry> entries) =>
      entries.map((e) => ScheduleTimes.formatTime(e.time)).join(',');

  /// Mengen-CSV, gleiche Reihenfolge.
  static String formatDoses(List<DoseSlotEntry> entries) =>
      entries.map((e) => e.isActive ? e.amount.trim() : '0').join(',');

  /// Kurzform des Schemas: "1-0-2-0".
  static String pattern(List<DoseSlotEntry> entries) =>
      entries.map((e) => e.isActive ? e.amount.trim() : '0').join('-');

  /// Nur die Uhrzeiten, an denen wirklich etwas ansteht.
  static String activeTimes(List<DoseSlotEntry> entries) => entries
      .where((e) => e.isActive)
      .map((e) => ScheduleTimes.formatTime(e.time))
      .join(', ');

  /// Die Menge, die zu einem Zeitpunkt gehört.
  ///
  /// Für alle anderen Zeitplan-Arten (und wenn nichts hinterlegt ist) gilt
  /// die Menge des Plans.
  static String amountAt(MedicationPlan plan, DateTime moment) {
    if (ScheduleType.parse(plan.scheduleType) != ScheduleType.scheme) {
      return plan.dosage;
    }
    final entries = parse(plan.times, plan.doses);
    for (final entry in entries) {
      if (entry.time.hour == moment.hour && entry.time.minute == moment.minute) {
        return entry.isActive ? entry.amount.trim() : plan.dosage;
      }
    }
    return plan.dosage;
  }
}
