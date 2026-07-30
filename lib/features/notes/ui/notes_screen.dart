import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../data/repositories/notes_repository.dart';
import '../domain/note_color.dart';
import '../notes_providers.dart';
import 'note_editor_screen.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final search = ref.watch(notesSearchProvider);

    return ModuleScaffold(
      title: 'Notizen',
      body: Column(
        children: [
          _SearchBar(search: search),
          Expanded(
            child: notes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Fehler',
                message: '$error',
              ),
              data: (list) => list.isEmpty
                  ? _empty(search)
                  : _NotesGrid(notes: list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String search) {
    if (search.isNotEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Nichts gefunden',
        message: 'Keine Notiz passt zu deiner Suche.',
      );
    }
    return const EmptyState(
      icon: Icons.sticky_note_2_outlined,
      title: 'Noch keine Notizen',
      message: 'Erstelle eine Notiz oder eine Checkliste.',
    );
  }

}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar({required this.search});

  final String search;

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final _controller = TextEditingController(text: widget.search);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Notizen durchsuchen',
          suffixIcon: widget.search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    ref.read(notesSearchProvider.notifier).clear();
                  },
                ),
        ),
        onChanged: ref.read(notesSearchProvider.notifier).set,
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes});

  final List<NoteWithItems> notes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 260).floor().clamp(1, 5);
        return MasonryGrid(columns: columns, notes: notes);
      },
    );
  }
}

/// Einfaches versetztes Raster ("Masonry") über gleichmäßig gefüllte Spalten.
class MasonryGrid extends StatelessWidget {
  const MasonryGrid({super.key, required this.columns, required this.notes});

  final int columns;
  final List<NoteWithItems> notes;

  @override
  Widget build(BuildContext context) {
    final buckets = List.generate(columns, (_) => <NoteWithItems>[]);
    for (var i = 0; i < notes.length; i++) {
      buckets[i % columns].add(notes[i]);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final bucket in buckets)
            Expanded(
              child: Column(
                children: [
                  for (final entry in bucket)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: NoteCard(entry: entry),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class NoteCard extends ConsumerWidget {
  const NoteCard({super.key, required this.entry});

  final NoteWithItems entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = entry.note;
    final color = NoteColor.parse(note.colorKey);
    final scheme = Theme.of(context).colorScheme;
    final hasTitle = note.title.trim().isNotEmpty;

    return Material(
      color: color.background(scheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.border(scheme)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteEditorScreen(noteId: note.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (hasTitle)
                    Expanded(
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    const Spacer(),
                  if (note.isPinned)
                    Icon(Icons.push_pin_rounded, size: 16, color: scheme.primary),
                ],
              ),
              if (hasTitle) const SizedBox(height: 6),
              if (note.isChecklist)
                _ChecklistPreview(entry: entry)
              else if (note.body.trim().isNotEmpty)
                Text(
                  note.body,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (entry.tagList.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in entry.tagList)
                      _TagChip(tag: tag),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistPreview extends StatelessWidget {
  const _ChecklistPreview({required this.entry});

  final NoteWithItems entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = entry.items.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in preview)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.isDone
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: item.isDone ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.content.isEmpty ? '(leer)' : item.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration:
                          item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (entry.items.length > preview.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${entry.items.length - preview.length} weitere',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (entry.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${entry.doneCount}/${entry.items.length} erledigt',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer),
      ),
    );
  }
}
