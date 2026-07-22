import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(databaseProvider)),
);

class NotesSearchController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

final notesSearchProvider =
    NotifierProvider<NotesSearchController, String>(NotesSearchController.new);

final notesProvider = StreamProvider<List<NoteWithItems>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  final search = ref.watch(notesSearchProvider);
  return ref.watch(notesRepositoryProvider).watchNotes(scope, search: search);
});

/// Live-Ansicht einer einzelnen Notiz für den Editor.
final noteProvider = StreamProvider.family<NoteWithItems?, String>((ref, id) {
  final scope = ref.watch(activeScopeProvider);
  return ref
      .watch(notesRepositoryProvider)
      .watchNotes(scope)
      .map(
        (notes) => notes.where((n) => n.note.id == id).firstOrNull,
      );
});
