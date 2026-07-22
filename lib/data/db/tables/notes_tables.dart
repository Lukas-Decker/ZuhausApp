import 'package:drift/drift.dart';

import 'common.dart';

/// Eine Notiz oder Checkliste.
///
/// Ist [isChecklist] false, zaehlt nur [body] als Freitext. Ist es true,
/// stehen die einzelnen Punkte in [NoteChecklistItems].
class Notes extends Table with SyncedRecord {
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();

  BoolColumn get isChecklist => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// Schluessel aus [noteColors].
  TextColumn get colorKey => text().withDefault(const Constant('default'))();

  /// Kommagetrennte Tags, klein geschrieben. Fuer eine einfache Suche reicht
  /// das; eine eigene Tag-Tabelle waere hier ueberdimensioniert.
  TextColumn get tags => text().withDefault(const Constant(''))();
}

/// Ein Punkt in einer Checklisten-Notiz.
class NoteChecklistItems extends Table with SyncedRecord {
  TextColumn get noteId => text().references(Notes, #id)();

  // Spaltenname in der DB bleibt "content"; ein Getter namens `text` wuerde
  // die Drift-Hilfsfunktion text() verdecken.
  TextColumn get content => text().withLength(min: 0, max: 400)();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
}
