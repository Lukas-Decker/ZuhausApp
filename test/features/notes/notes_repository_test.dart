import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/notes_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late NotesRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = NotesRepository(db);
  });

  tearDown(() => db.close());

  test('neue Notiz ist zunächst leer und im Kontext sichtbar', () async {
    final id = await repository.createNote(
      scope: personalScope,
      userId: testUserId,
    );
    final entry = await repository.getNote(id);
    expect(entry, isNotNull);
    expect(entry!.note.title, '');
    expect(entry.note.isChecklist, isFalse);
  });

  test('Kontexte sind getrennt', () async {
    await repository.createNote(scope: personalScope, userId: testUserId);
    await repository.updateNote(
      id: await repository.createNote(
        scope: householdScope,
        userId: testUserId,
      ),
      userId: testUserId,
      title: 'Haushaltsnotiz',
    );

    final personal = await repository.watchNotes(personalScope).first;
    final household = await repository.watchNotes(householdScope).first;
    expect(personal, hasLength(1));
    expect(household, hasLength(1));
    expect(household.single.note.title, 'Haushaltsnotiz');
  });

  test('angeheftete Notizen stehen oben', () async {
    final a = await repository.createNote(
      scope: personalScope,
      userId: testUserId,
    );
    await repository.updateNote(id: a, userId: testUserId, title: 'A');
    final b = await repository.createNote(
      scope: personalScope,
      userId: testUserId,
    );
    await repository.updateNote(id: b, userId: testUserId, title: 'B');

    await repository.togglePin(a, true, testUserId);

    final notes = await repository.watchNotes(personalScope).first;
    expect(notes.first.note.id, a);
  });

  group('Suche', () {
    Future<void> seed() async {
      final note = await repository.createNote(
        scope: personalScope,
        userId: testUserId,
      );
      await repository.updateNote(
        id: note,
        userId: testUserId,
        title: 'Einkauf Baumarkt',
        body: 'Schrauben und Duebel',
        tags: 'heimwerken,projekt',
      );
      final list = await repository.createNote(
        scope: personalScope,
        userId: testUserId,
        isChecklist: true,
      );
      await repository.updateNote(
        id: list,
        userId: testUserId,
        title: 'Packliste',
      );
      await repository.addChecklistItem(
        scope: personalScope,
        noteId: list,
        userId: testUserId,
        text: 'Zahnbuerste',
      );
    }

    test('findet über Titel', () async {
      await seed();
      final result = await repository.watchNotes(
        personalScope,
        search: 'baumarkt',
      ).first;
      expect(result, hasLength(1));
    });

    test('findet über Tag', () async {
      await seed();
      final result = await repository.watchNotes(
        personalScope,
        search: 'heimwerken',
      ).first;
      expect(result, hasLength(1));
    });

    test('findet über Checklistenpunkt', () async {
      await seed();
      final result = await repository.watchNotes(
        personalScope,
        search: 'zahnb',
      ).first;
      expect(result.single.note.title, 'Packliste');
    });
  });

  group('Checkliste', () {
    test('Punkte behalten ihre Reihenfolge', () async {
      final id = await repository.createNote(
        scope: personalScope,
        userId: testUserId,
        isChecklist: true,
      );
      for (final text in ['Erster', 'Zweiter', 'Dritter']) {
        await repository.addChecklistItem(
          scope: personalScope,
          noteId: id,
          userId: testUserId,
          text: text,
        );
      }
      final entry = await repository.getNote(id);
      expect(
        entry!.items.map((i) => i.content),
        ['Erster', 'Zweiter', 'Dritter'],
      );
    });

    test('offene und erledigte Punkte werden gezählt', () async {
      final id = await repository.createNote(
        scope: personalScope,
        userId: testUserId,
        isChecklist: true,
      );
      final first = await repository.addChecklistItem(
        scope: personalScope,
        noteId: id,
        userId: testUserId,
        text: 'A',
      );
      await repository.addChecklistItem(
        scope: personalScope,
        noteId: id,
        userId: testUserId,
        text: 'B',
      );
      await repository.updateChecklistItem(
        id: first,
        userId: testUserId,
        isDone: true,
      );

      final entry = await repository.getNote(id);
      expect(entry!.doneCount, 1);
      expect(entry.openCount, 1);
    });
  });

  group('deleteIfEmpty', () {
    test('löscht eine komplett leere Notiz', () async {
      final id = await repository.createNote(
        scope: personalScope,
        userId: testUserId,
      );
      expect(await repository.deleteIfEmpty(id), isTrue);
      expect(await repository.getNote(id), isNull);
    });

    test('behält eine Notiz mit Inhalt', () async {
      final id = await repository.createNote(
        scope: personalScope,
        userId: testUserId,
      );
      await repository.updateNote(id: id, userId: testUserId, body: 'Hallo');
      expect(await repository.deleteIfEmpty(id), isFalse);
      expect(await repository.getNote(id), isNotNull);
    });
  });

  test('deleteNote ist ein Soft-Delete', () async {
    final id = await repository.createNote(
      scope: personalScope,
      userId: testUserId,
    );
    await repository.updateNote(id: id, userId: testUserId, title: 'Weg');
    await repository.deleteNote(id, testUserId);

    expect(await repository.watchNotes(personalScope).first, isEmpty);
    final row = await repository.getNote(id);
    expect(row!.note.deletedAt, isNotNull);
  });
}
