import 'package:drift/drift.dart';

import 'common.dart';
import 'inventory_tables.dart';

/// Ein Tier im Haushalt oder im privaten Bereich.
class Pets extends Table with SyncedRecord {
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Schluessel aus [petSpecies], z.B. dog, cat, bird.
  TextColumn get species => text().withDefault(const Constant('other'))();
  TextColumn get breed => text().nullable()();
  DateTimeColumn get birthday => dateTime().nullable()();

  /// Pfad zu einem lokal gespeicherten Foto.
  TextColumn get photoPath => text().nullable()();

  /// Optional mit einem Futter-Vorrat aus dem Inventar verknuepft, der beim
  /// Fuettern heruntergezaehlt wird.
  TextColumn get foodInventoryItemId =>
      text().nullable().references(InventoryItems, #id)();

  /// Menge, die eine Fuetterung vom Futtervorrat abzieht.
  RealColumn get foodPortion => real().nullable()();

  TextColumn get note => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// Eine wiederkehrende Tagesaufgabe, z.B. Fuettern, Gassi, Wasser, Katzenklo.
class PetTasks extends Table with SyncedRecord {
  TextColumn get petId => text().references(Pets, #id)();
  TextColumn get title => text().withLength(min: 1, max: 80)();

  /// Schluessel aus [petTaskIcons].
  TextColumn get iconKey => text().withDefault(const Constant('paw'))();

  /// Wie oft pro Tag die Aufgabe ansteht (z.B. 2x fuettern).
  IntColumn get timesPerDay => integer().withDefault(const Constant(1))();

  /// Zieht diese Aufgabe beim Erledigen den Futtervorrat ab?
  BoolColumn get consumesFood => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Ein Erledigungs-Eintrag fuer eine Tagesaufgabe.
///
/// Haelt fest, wer wann erledigt hat, damit nicht doppelt gefuettert wird.
class PetTaskLogs extends Table with SyncedRecord {
  TextColumn get taskId => text().references(PetTasks, #id)();
  TextColumn get petId => text().references(Pets, #id)();

  /// Kalendertag der Erledigung (Mitternacht), fuer die Tageszaehlung.
  DateTimeColumn get day => dateTime()();
  DateTimeColumn get doneAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get doneByName => text().nullable()();
}

/// Gesundheitsereignis: Medikament, Impfung, Entwurmung, Tierarzttermin.
class PetHealthEntries extends Table with SyncedRecord {
  TextColumn get petId => text().references(Pets, #id)();

  /// 'medication', 'vaccination', 'deworming', 'vet', 'other'.
  TextColumn get kind => text().withDefault(const Constant('other'))();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get note => text().nullable()();

  /// Termin oder Zeitpunkt der Massnahme.
  DateTimeColumn get dueAt => dateTime()();

  /// Naechste Faelligkeit (z.B. Auffrischung), fuer Vorlauf-Erinnerung.
  DateTimeColumn get nextDueAt => dateTime().nullable()();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();

  /// Tage Vorlauf fuer die Erinnerung.
  IntColumn get reminderLeadDays => integer().withDefault(const Constant(2))();
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
}

/// Ein Gewichtseintrag fuer den Verlauf.
class PetWeightEntries extends Table with SyncedRecord {
  TextColumn get petId => text().references(Pets, #id)();
  DateTimeColumn get measuredAt => dateTime()();

  /// Gewicht in Kilogramm.
  RealColumn get weightKg => real()();
  TextColumn get note => text().nullable()();
}
