import 'package:drift/drift.dart';

import '../../core/scope/app_scope.dart';
import '../db/app_database.dart';
import '../db/tables/common.dart';

/// Eine Notiz zusammen mit ihren Checklistenpunkten (leer bei Freitext).
class NoteWithItems {
  const NoteWithItems({required this.note, required this.items});

  final Note note;
  final List<NoteChecklistItem> items;

  int get openCount => items.where((i) => !i.isDone).length;
  int get doneCount => items.where((i) => i.isDone).length;

  List<String> get tagList => note.tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
}

class NotesRepository {
  NotesRepository(this._db);

  final AppDatabase _db;

  /// Notizen des Kontexts, angeheftete zuerst, dann nach letzter Änderung.
  Stream<List<NoteWithItems>> watchNotes(AppScope scope, {String search = ''}) {
    final notesQuery = _db.select(_db.notes)
      ..where((n) => n.scopeKind.equals(scope.kind.name))
      ..where((n) => n.scopeId.equals(scope.id))
      ..where((n) => n.deletedAt.isNull())
      ..orderBy([
        (n) => OrderingTerm.desc(n.isPinned),
        (n) => OrderingTerm.desc(n.updatedAt),
      ]);

    final term = search.trim().toLowerCase();

    return notesQuery.watch().asyncMap((notes) async {
      final result = <NoteWithItems>[];
      for (final note in notes) {
        final items = note.isChecklist
            ? await (_db.select(_db.noteChecklistItems)
                    ..where((i) => i.noteId.equals(note.id))
                    ..where((i) => i.deletedAt.isNull())
                    ..orderBy([(i) => OrderingTerm.asc(i.position)]))
                  .get()
            : <NoteChecklistItem>[];

        final entry = NoteWithItems(note: note, items: items);
        if (term.isEmpty || _matches(entry, term)) result.add(entry);
      }
      return result;
    });
  }

  static bool _matches(NoteWithItems entry, String term) {
    if (entry.note.title.toLowerCase().contains(term)) return true;
    if (entry.note.body.toLowerCase().contains(term)) return true;
    if (entry.note.tags.toLowerCase().contains(term)) return true;
    return entry.items.any((i) => i.content.toLowerCase().contains(term));
  }

  Future<NoteWithItems?> getNote(String id) async {
    final note = await (_db.select(_db.notes)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
    if (note == null) return null;
    final items = await (_db.select(_db.noteChecklistItems)
          ..where((i) => i.noteId.equals(id))
          ..where((i) => i.deletedAt.isNull())
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
    return NoteWithItems(note: note, items: items);
  }

  Future<String> createNote({
    required AppScope scope,
    required String userId,
    bool isChecklist = false,
  }) async {
    final id = uuid.v4();
    await _db.into(_db.notes).insert(
      NotesCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        isChecklist: Value(isChecklist),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
    return id;
  }

  Future<void> updateNote({
    required String id,
    required String userId,
    String? title,
    String? body,
    bool? isChecklist,
    bool? isPinned,
    String? colorKey,
    String? tags,
  }) async {
    await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        title: title == null ? const Value.absent() : Value(title),
        body: body == null ? const Value.absent() : Value(body),
        isChecklist:
            isChecklist == null ? const Value.absent() : Value(isChecklist),
        isPinned: isPinned == null ? const Value.absent() : Value(isPinned),
        colorKey: colorKey == null ? const Value.absent() : Value(colorKey),
        tags: tags == null ? const Value.absent() : Value(tags),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> togglePin(String id, bool pinned, String userId) =>
      updateNote(id: id, userId: userId, isPinned: pinned);

  Future<void> deleteNote(String id, String userId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
        NotesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(_db.noteChecklistItems)
            ..where((i) => i.noteId.equals(id)))
          .write(
        NoteChecklistItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
    });
  }

  /// Löscht leere Notizen, damit ein versehentlich geöffneter Editor keine
  /// Karteileichen hinterlässt. Gibt true zurück, wenn gelöscht wurde.
  Future<bool> deleteIfEmpty(String id) async {
    final entry = await getNote(id);
    if (entry == null) return false;
    final note = entry.note;
    final hasText = note.title.trim().isNotEmpty || note.body.trim().isNotEmpty;
    final hasItems = entry.items.any((i) => i.content.trim().isNotEmpty);
    if (hasText || hasItems) return false;

    await (_db.delete(_db.noteChecklistItems)..where((i) => i.noteId.equals(id)))
        .go();
    await (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
    return true;
  }

  // --- Checklistenpunkte ---------------------------------------------------

  Future<String> addChecklistItem({
    required AppScope scope,
    required String noteId,
    required String userId,
    String text = '',
    int? position,
  }) async {
    final id = uuid.v4();
    final pos = position ??
        (await (_db.select(_db.noteChecklistItems)
                  ..where((i) => i.noteId.equals(noteId)))
                .get())
            .length;
    await _db.into(_db.noteChecklistItems).insert(
      NoteChecklistItemsCompanion.insert(
        id: Value(id),
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        noteId: noteId,
        content: text,
        position: Value(pos),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
    return id;
  }

  Future<void> updateChecklistItem({
    required String id,
    required String userId,
    String? text,
    bool? isDone,
    int? position,
  }) async {
    await (_db.update(_db.noteChecklistItems)..where((i) => i.id.equals(id)))
        .write(
      NoteChecklistItemsCompanion(
        content: text == null ? const Value.absent() : Value(text),
        isDone: isDone == null ? const Value.absent() : Value(isDone),
        position: position == null ? const Value.absent() : Value(position),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> deleteChecklistItem(String id) async {
    await (_db.delete(_db.noteChecklistItems)..where((i) => i.id.equals(id)))
        .go();
  }
}
