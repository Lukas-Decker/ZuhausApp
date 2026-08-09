import 'package:drift/drift.dart';

import 'common.dart';

/// Ein Medikamenten- oder Einnahmeplan.
///
/// Pläne liegen standardmäßig im privaten Kontext (Gesundheitsdaten,
/// DSGVO Art. 9). Über [sharedWithHousehold] oder [caregiverUserId] können sie
/// gezielt und widerruflich freigegeben werden.
class MedicationPlans extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Freitext zur Dosis, z.B. "1 Tablette" oder "10 Tropfen".
  TextColumn get dosage => text().withDefault(const Constant(''))();

  /// Schlüssel aus [medicationForms], z.B. tablet, drop, spray.
  TextColumn get form => text().withDefault(const Constant('tablet'))();

  /// 'daily' (feste Uhrzeiten an Wochentagen), 'scheme' (Morgens/Mittags/
  /// Abends/Nachts mit eigener Menge) oder 'interval' (alle N Stunden).
  TextColumn get scheduleType => text().withDefault(const Constant('daily'))();

  /// Bei 'daily' und 'scheme': Uhrzeiten als CSV "HH:mm", z.B. "08:00,20:00".
  ///
  /// Bei 'scheme' stehen hier immer alle vier Tageszeiten in fester
  /// Reihenfolge (morgens, mittags, abends, nachts).
  TextColumn get times => text().withDefault(const Constant('08:00'))();

  /// Bei 'scheme': Menge je Uhrzeit als CSV, gleiche Reihenfolge wie [times],
  /// z.B. "1,0,1,0" für das klassische 1-0-1. Eine 0 bedeutet: zu dieser
  /// Tageszeit keine Einnahme. Leer heißt: überall die Menge aus [dosage].
  TextColumn get doses => text().withDefault(const Constant(''))();

  /// Einnahmehinweise als CSV von Schlüsseln, z.B. "fasting,water".
  /// Die Texte dazu stehen übersetzt in den ARB-Dateien.
  TextColumn get intakeHints => text().withDefault(const Constant(''))();

  /// Bei 'daily': aktive Wochentage als CSV 1-7 (Mo-So), leer = alle Tage.
  TextColumn get weekdays => text().withDefault(const Constant(''))();

  /// Bei 'interval': Abstand in Stunden.
  IntColumn get intervalHours => integer().withDefault(const Constant(8))();

  DateTimeColumn get startDate => dateTime().nullable()();

  /// Ende einer Kur; danach werden keine Erinnerungen mehr geplant.
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Aktueller Vorrat in Einheiten der Dosis.
  RealColumn get stockCount => real().nullable()();
  RealColumn get stockThreshold => real().nullable()();

  /// Menge, die eine Einnahme vom Vorrat abzieht.
  RealColumn get dosePerIntake => real().withDefault(const Constant(1))();

  TextColumn get note => text().nullable()();

  /// Erinnerungen für genau diesen Plan. Zusätzlich gibt es einen globalen
  /// Schalter für alle Medikamenten-Erinnerungen.
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Freigabe an alle Haushaltsmitglieder.
  BoolColumn get sharedWithHousehold =>
      boolean().withDefault(const Constant(false))();

  /// Optionale Betreuungsperson, die Einnahmen sieht und ab v0.10 bei
  /// verpassten Einnahmen benachrichtigt wird.
  TextColumn get caregiverUserId => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Ein einzelnes geplantes oder erfolgtes Einnahmeereignis.
class MedicationLogs extends Table with SyncedRecord {
  TextColumn get planId => text().references(MedicationPlans, #id)();

  /// Geplanter Zeitpunkt der Einnahme.
  DateTimeColumn get scheduledFor => dateTime()();

  /// 'taken', 'skipped' oder 'postponed'.
  TextColumn get status => text().withDefault(const Constant('taken'))();

  DateTimeColumn get actedAt => dateTime().nullable()();
  RealColumn get dose => real().nullable()();
}
