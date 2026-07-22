import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/notes_repository.dart';
import '../domain/note_color.dart';
import '../notes_providers.dart';

/// Editor für eine Notiz oder Checkliste.
///
/// Speichert automatisch mit kurzer Verzögerung, damit nichts verloren geht.
/// Beim Verlassen wird eine komplett leere Notiz wieder entfernt.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tags = TextEditingController();
  final _newItem = TextEditingController();

  Timer? _debounce;
  bool _loaded = false;
  NoteColor _color = NoteColor.defaultColor;
  bool _pinned = false;
  bool _isChecklist = false;

  String get _userId => ref.read(identityProvider).userId;
  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _title.addListener(_scheduleSave);
    _body.addListener(_scheduleSave);
    _tags.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _flush();
    _cleanupIfEmpty();
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    _newItem.dispose();
    super.dispose();
  }

  void _hydrate(Note note) {
    if (_loaded) return;
    _title.text = note.title;
    _body.text = note.body;
    _tags.text = note.tags;
    _color = NoteColor.parse(note.colorKey);
    _pinned = note.isPinned;
    _isChecklist = note.isChecklist;
    _loaded = true;
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flush);
  }

  void _flush() {
    if (!_loaded) return;
    _repo.updateNote(
      id: widget.noteId,
      userId: _userId,
      title: _title.text.trim(),
      body: _body.text,
      tags: _normalizeTags(_tags.text),
    );
  }

  static String _normalizeTags(String raw) => raw
      .split(RegExp(r'[,\s]+'))
      .map((t) => t.trim().replaceAll('#', '').toLowerCase())
      .where((t) => t.isNotEmpty)
      .toSet()
      .join(',');

  void _cleanupIfEmpty() {
    // Nach dem Verlassen im Hintergrund prüfen; Fehler hier sind unkritisch.
    _repo.deleteIfEmpty(widget.noteId);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(noteProvider(widget.noteId));

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Fehler: $error'))),
      data: (entry) {
        if (entry == null) {
          // Notiz existiert nicht mehr (z.B. als leer verworfen).
          return const Scaffold(body: SizedBox.shrink());
        }
        _hydrate(entry.note);
        return _buildEditor(context, entry);
      },
    );
  }

  Widget _buildEditor(BuildContext context, NoteWithItems entry) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _color.background(scheme),
      appBar: AppBar(
        backgroundColor: _color.background(scheme),
        title: const ScopeChip(),
        actions: [
          IconButton(
            tooltip: _pinned ? 'Loslösen' : 'Anheften',
            onPressed: () {
              setState(() => _pinned = !_pinned);
              _repo.togglePin(widget.noteId, _pinned, _userId);
            },
            icon: Icon(
              _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            ),
          ),
          _ColorMenu(
            selected: _color,
            onSelected: (color) {
              setState(() => _color = color);
              _repo.updateNote(
                id: widget.noteId,
                userId: _userId,
                colorKey: color.key,
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _onMenu(context, value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'convert',
                child: Row(
                  children: [
                    Icon(
                      _isChecklist
                          ? Icons.notes_rounded
                          : Icons.checklist_rounded,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isChecklist
                          ? 'In Notiz umwandeln'
                          : 'In Checkliste umwandeln',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded),
                    SizedBox(width: 12),
                    Text('Löschen'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
              hintText: 'Titel',
            ),
          ),
          if (_isChecklist)
            _ChecklistEditor(
              noteId: widget.noteId,
              items: entry.items,
              newItemController: _newItem,
            )
          else
            TextField(
              controller: _body,
              maxLines: null,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                hintText: 'Text',
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.tag_rounded),
              hintText: 'Tags, mit Komma getrennt',
              filled: false,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Geändert ${DateFormat('dd.MM.yyyy, HH:mm', 'de').format(entry.note.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    switch (value) {
      case 'convert':
        setState(() => _isChecklist = !_isChecklist);
        await _repo.updateNote(
          id: widget.noteId,
          userId: _userId,
          isChecklist: _isChecklist,
        );
        // Beim Umschalten auf Checkliste einen ersten Punkt aus dem Text
        // anbieten, falls die Liste leer ist.
        if (_isChecklist) {
          final entry = await _repo.getNote(widget.noteId);
          if (entry != null && entry.items.isEmpty && _body.text.trim().isNotEmpty) {
            for (final line in _body.text.split('\n')) {
              if (line.trim().isEmpty) continue;
              await _repo.addChecklistItem(
                scope: ref.read(activeScopeProvider),
                noteId: widget.noteId,
                userId: _userId,
                text: line.trim(),
              );
            }
          }
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Notiz löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          _loaded = false; // verhindert erneutes Speichern beim dispose
          await _repo.deleteNote(widget.noteId, _userId);
          if (context.mounted) Navigator.of(context).pop();
        }
    }
  }
}

class _ColorMenu extends StatelessWidget {
  const _ColorMenu({required this.selected, required this.onSelected});

  final NoteColor selected;
  final ValueChanged<NoteColor> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NoteColor>(
      tooltip: 'Farbe',
      icon: const Icon(Icons.palette_outlined),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final color in NoteColor.values)
          PopupMenuItem(
            value: color,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.seed ?? Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(color.label),
                if (color == selected) ...[
                  const Spacer(),
                  const Icon(Icons.check_rounded, size: 18),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ChecklistEditor extends ConsumerWidget {
  const _ChecklistEditor({
    required this.noteId,
    required this.items,
    required this.newItemController,
  });

  final String noteId;
  final List<NoteChecklistItem> items;
  final TextEditingController newItemController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    final userId = ref.read(identityProvider).userId;

    return Column(
      children: [
        for (final item in items)
          _ChecklistRow(
            key: ValueKey(item.id),
            item: item,
            onToggle: (done) => repo.updateChecklistItem(
              id: item.id,
              userId: userId,
              isDone: done,
            ),
            onChanged: (text) => repo.updateChecklistItem(
              id: item.id,
              userId: userId,
              text: text,
            ),
            onDelete: () => repo.deleteChecklistItem(item.id),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.add_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: newItemController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: 'Punkt hinzufügen',
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isEmpty) return;
                    await repo.addChecklistItem(
                      scope: ref.read(activeScopeProvider),
                      noteId: noteId,
                      userId: userId,
                      text: value.trim(),
                    );
                    newItemController.clear();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatefulWidget {
  const _ChecklistRow({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onChanged,
    required this.onDelete,
  });

  final NoteChecklistItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.item.content,
  );
  Timer? _debounce;

  @override
  void didUpdateWidget(_ChecklistRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Übernimmt Änderungen von anderen Geräten, ohne die Eingabe zu stören.
    if (widget.item.content != _controller.text &&
        !_controller.selection.isValid) {
      _controller.text = widget.item.content;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Checkbox(
          value: widget.item.isDone,
          onChanged: (value) => widget.onToggle(value ?? false),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(
              decoration:
                  widget.item.isDone ? TextDecoration.lineThrough : null,
              color: widget.item.isDone ? scheme.onSurfaceVariant : null,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
              isDense: true,
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 500),
                () => widget.onChanged(value),
              );
            },
          ),
        ),
        IconButton(
          tooltip: 'Punkt entfernen',
          onPressed: widget.onDelete,
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ],
    );
  }
}
