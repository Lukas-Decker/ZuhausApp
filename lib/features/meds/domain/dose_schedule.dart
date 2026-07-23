import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';
import 'medication_schedule.dart';

/// Ein konkreter, an einem Tag fälliger Einnahmezeitpunkt eines Plans.
@immutable
class DoseOccurrence {
  const DoseOccurrence({required this.plan, required this.scheduledFor});

  final MedicationPlan plan;
  final DateTime scheduledFor;

  /// Stabile Kennung für Log-Abgleich und Notification-ID.
  String get slotKey =>
      '${plan.id}@${scheduledFor.toIso8601String()}';
}

/// Berechnet aus den Plänen, wann welche Einnahme fällig ist.
///
/// Rein funktional und ohne Datenbank, damit die Regeln (Wochentage, Kur-Ende,
/// Intervall) testbar bleiben.
abstract final class DoseSchedule {
  /// Alle Fälligkeiten eines Plans an einem bestimmten Kalendertag.
  static List<DoseOccurrence> forDay(MedicationPlan plan, DateTime day) {
    if (!plan.isActive) return const [];

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (plan.startDate != null &&
        dayStart.isBefore(_dateOnly(plan.startDate!))) {
      return const [];
    }
    if (plan.endDate != null && dayStart.isAfter(_dateOnly(plan.endDate!))) {
      return const [];
    }

    return switch (ScheduleType.parse(plan.scheduleType)) {
      ScheduleType.daily => _dailyForDay(plan, dayStart),
      ScheduleType.interval => _intervalForDay(plan, dayStart, dayEnd),
    };
  }

  static List<DoseOccurrence> _dailyForDay(
    MedicationPlan plan,
    DateTime dayStart,
  ) {
    if (!ScheduleWeekdays.includes(plan.weekdays, dayStart.weekday)) {
      return const [];
    }
    return ScheduleTimes.parse(plan.times)
        .map(
          (t) => DoseOccurrence(
            plan: plan,
            scheduledFor: DateTime(
              dayStart.year,
              dayStart.month,
              dayStart.day,
              t.hour,
              t.minute,
            ),
          ),
        )
        .toList();
  }

  static List<DoseOccurrence> _intervalForDay(
    MedicationPlan plan,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final interval = Duration(hours: plan.intervalHours.clamp(1, 24));
    // Anker ist der Beginn der Kur oder, falls unbekannt, Mitternacht.
    var cursor = plan.startDate ?? dayStart;
    if (cursor.isAfter(dayStart)) {
      // Kur beginnt heute mitten am Tag.
    } else {
      // Vom Anker in Intervallschritten bis in den Tag springen.
      final diff = dayStart.difference(cursor);
      final steps = (diff.inMinutes / interval.inMinutes).floor();
      cursor = cursor.add(interval * steps);
    }

    final occurrences = <DoseOccurrence>[];
    while (cursor.isBefore(dayEnd)) {
      if (!cursor.isBefore(dayStart)) {
        occurrences.add(
          DoseOccurrence(plan: plan, scheduledFor: cursor),
        );
      }
      cursor = cursor.add(interval);
    }
    return occurrences;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
