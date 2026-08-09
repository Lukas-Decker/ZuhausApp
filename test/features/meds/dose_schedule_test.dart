import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/features/meds/domain/dose_schedule.dart';
import 'package:multiapp/features/meds/domain/dose_slots.dart';
import 'package:multiapp/features/meds/domain/medication_schedule.dart';

MedicationPlan _plan({
  String scheduleType = 'daily',
  String times = '08:00,20:00',
  String doses = '',
  String intakeHints = '',
  String weekdays = '',
  int intervalHours = 8,
  DateTime? startDate,
  DateTime? endDate,
  bool isActive = true,
}) {
  final now = DateTime(2026, 1, 1);
  return MedicationPlan(
    id: 'p1',
    scopeKind: 'personal',
    scopeId: 'u1',
    name: 'Test',
    dosage: '1',
    form: 'tablet',
    scheduleType: scheduleType,
    times: times,
    doses: doses,
    intakeHints: intakeHints,
    weekdays: weekdays,
    intervalHours: intervalHours,
    startDate: startDate,
    endDate: endDate,
    dosePerIntake: 1,
    remindersEnabled: true,
    sharedWithHousehold: false,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
    isDirty: false,
  );
}

void main() {
  group('DoseSchedule daily', () {
    test('erzeugt einen Termin je Uhrzeit', () {
      final day = DateTime(2026, 7, 22); // Mittwoch
      final doses = DoseSchedule.forDay(_plan(times: '08:00,20:00'), day);
      expect(doses, hasLength(2));
      expect(doses[0].scheduledFor.hour, 8);
      expect(doses[1].scheduledFor.hour, 20);
    });

    test('Termine sind nach Uhrzeit sortiert, egal wie eingegeben', () {
      final doses = DoseSchedule.forDay(
        _plan(times: '20:00,08:00,12:00'),
        DateTime(2026, 7, 22),
      );
      expect(
        doses.map((d) => d.scheduledFor.hour),
        [8, 12, 20],
      );
    });

    test('respektiert Wochentage', () {
      final monday = DateTime(2026, 7, 20);
      final saturday = DateTime(2026, 7, 25);
      final plan = _plan(weekdays: '1,2,3,4,5'); // werktags
      expect(DoseSchedule.forDay(plan, monday), isNotEmpty);
      expect(DoseSchedule.forDay(plan, saturday), isEmpty);
    });

    test('leere Wochentage bedeuten täglich', () {
      final sunday = DateTime(2026, 7, 26);
      expect(DoseSchedule.forDay(_plan(weekdays: ''), sunday), isNotEmpty);
    });
  });

  group('DoseSchedule Kur-Zeitraum', () {
    test('vor Beginn keine Termine', () {
      final plan = _plan(startDate: DateTime(2026, 7, 23));
      expect(DoseSchedule.forDay(plan, DateTime(2026, 7, 22)), isEmpty);
      expect(DoseSchedule.forDay(plan, DateTime(2026, 7, 23)), isNotEmpty);
    });

    test('nach Kur-Ende keine Termine', () {
      final plan = _plan(endDate: DateTime(2026, 7, 22));
      expect(DoseSchedule.forDay(plan, DateTime(2026, 7, 22)), isNotEmpty);
      expect(DoseSchedule.forDay(plan, DateTime(2026, 7, 23)), isEmpty);
    });
  });

  group('DoseSchedule interval', () {
    test('alle 8 Stunden ab Mitternacht ergibt drei Termine', () {
      final plan = _plan(scheduleType: 'interval', intervalHours: 8);
      final doses = DoseSchedule.forDay(plan, DateTime(2026, 7, 22));
      expect(doses, hasLength(3));
      expect(doses.map((d) => d.scheduledFor.hour), [0, 8, 16]);
    });

    test('Anker ist der Kurbeginn', () {
      final plan = _plan(
        scheduleType: 'interval',
        intervalHours: 12,
        startDate: DateTime(2026, 7, 22, 6),
      );
      final doses = DoseSchedule.forDay(plan, DateTime(2026, 7, 22));
      expect(doses.map((d) => d.scheduledFor.hour), [6, 18]);
    });
  });

  test('inaktiver Plan liefert nie Termine', () {
    expect(
      DoseSchedule.forDay(_plan(isActive: false), DateTime(2026, 7, 22)),
      isEmpty,
    );
  });

  group('ScheduleWeekdays.describe', () {
    test('gängige Muster', () {
      expect(ScheduleWeekdays.describe(''), 'Täglich');
      expect(ScheduleWeekdays.describe('1,2,3,4,5,6,7'), 'Täglich');
      expect(ScheduleWeekdays.describe('1,2,3,4,5'), 'Werktags');
      expect(ScheduleWeekdays.describe('6,7'), 'Wochenende');
      expect(ScheduleWeekdays.describe('1,3'), 'Mo, Mi');
    });
  });

  group('ScheduleTimes', () {
    test('parst und formatiert robust', () {
      expect(ScheduleTimes.parse('08:00, 20:00'), hasLength(2));
      expect(ScheduleTimes.parse('25:00,08:00'), hasLength(1));
      expect(
        ScheduleTimes.format(const [
          TimeOfDay(hour: 20, minute: 0),
          TimeOfDay(hour: 8, minute: 5),
        ]),
        '08:05,20:00',
      );
    });
  });

  group('Tageszeiten-Schema', () {
    test('erinnert nur zu den Zeiten mit einer Menge', () {
      final plan = _plan(
        scheduleType: 'scheme',
        times: '08:00,12:00,18:00,22:00',
        doses: '1,0,2,0',
      );
      final occurrences = DoseSchedule.forDay(plan, DateTime(2026, 3, 2));

      expect(occurrences.map((o) => o.scheduledFor.hour), [8, 18]);
      expect(occurrences.map((o) => o.amount), ['1', '2']);
    });

    test('amountAt findet die Menge der Tageszeit', () {
      final plan = _plan(
        scheduleType: 'scheme',
        times: '08:00,12:00,18:00,22:00',
        doses: '1,0,2,0',
      );
      expect(DoseScheme.amountAt(plan, DateTime(2026, 3, 2, 18)), '2');
      // Uhrzeit ohne Eintrag faellt auf die Menge des Plans zurueck.
      expect(DoseScheme.amountAt(plan, DateTime(2026, 3, 2, 9)), '1');
    });
  });

  group('medicationDoseLabel', () {
    test('setzt die Mehrzahl nach der Menge', () {
      expect(medicationDoseLabel('tablet', '1'), '1 Tablette');
      expect(medicationDoseLabel('tablet', '2'), '2 Tabletten');
      expect(medicationDoseLabel('capsule', '3'), '3 Kapseln');
      // Tropfen heissen in beiden Faellen gleich.
      expect(medicationDoseLabel('drop', '10'), '10 Tropfen');
    });

    test('laesst eine eigene Einheit unangetastet', () {
      expect(medicationDoseLabel('drop', '5 ml'), '5 ml');
      expect(medicationDoseLabel('tablet', 'nach Bedarf'), 'nach Bedarf');
    });

    test('ohne Menge bleibt nur die Form', () {
      expect(medicationDoseLabel('tablet', '  '), 'Tablette');
    });
  });
}
