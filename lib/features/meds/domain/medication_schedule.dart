import 'package:flutter/material.dart';

/// Darreichungsformen mit Symbol.
const Map<String, ({String label, IconData icon})> medicationForms = {
  'tablet': (label: 'Tablette', icon: Icons.medication_rounded),
  'capsule': (label: 'Kapsel', icon: Icons.medication_liquid_rounded),
  'drop': (label: 'Tropfen', icon: Icons.water_drop_rounded),
  'spray': (label: 'Spray', icon: Icons.air_rounded),
  'injection': (label: 'Spritze', icon: Icons.vaccines_rounded),
  'ointment': (label: 'Salbe', icon: Icons.healing_rounded),
  'other': (label: 'Sonstiges', icon: Icons.medical_services_rounded),
};

({String label, IconData icon}) medicationForm(String key) =>
    medicationForms[key] ?? medicationForms['other']!;

enum ScheduleType {
  daily('daily', 'Feste Uhrzeiten'),
  interval('interval', 'Im Abstand');

  const ScheduleType(this.key, this.label);

  final String key;
  final String label;

  static ScheduleType parse(String? value) => ScheduleType.values
      .firstWhere((s) => s.key == value, orElse: () => ScheduleType.daily);
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
