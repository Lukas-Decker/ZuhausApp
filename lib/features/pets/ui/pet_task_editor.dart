import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/db/app_database.dart';
import '../domain/pet_types.dart';
import '../pets_providers.dart';

/// Formular für eine wiederkehrende Tagesaufgabe.
class PetTaskEditor extends ConsumerStatefulWidget {
  const PetTaskEditor({super.key, required this.petId, this.task});

  final String petId;
  final PetTask? task;

  static Future<void> show(
    BuildContext context, {
    required String petId,
    PetTask? task,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => PetTaskEditor(petId: petId, task: task),
    );
  }

  @override
  ConsumerState<PetTaskEditor> createState() => _PetTaskEditorState();
}

class _PetTaskEditorState extends ConsumerState<PetTaskEditor> {
  late final TextEditingController _title;
  late String _iconKey;
  late int _timesPerDay;
  late bool _consumesFood;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _iconKey = task?.iconKey ?? 'food';
    _timesPerDay = task?.timesPerDay ?? 1;
    _consumesFood = task?.consumesFood ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Aufgabe bearbeiten' : 'Aufgabe hinzufügen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _title,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Titel'),
              ),
              const SizedBox(height: 16),
              const Text('Symbol'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in petTaskIcons.entries)
                    _IconChoice(
                      icon: entry.value.icon,
                      selected: _iconKey == entry.key,
                      onTap: () => setState(() => _iconKey = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('Wie oft pro Tag')),
                  IconButton.filledTonal(
                    onPressed: _timesPerDay <= 1
                        ? null
                        : () => setState(() => _timesPerDay--),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_timesPerDay',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _timesPerDay >= 12
                        ? null
                        : () => setState(() => _timesPerDay++),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _consumesFood,
                onChanged: (value) => setState(() => _consumesFood = value),
                title: const Text('Zieht Futtervorrat ab'),
                subtitle: const Text(
                  'Beim Erledigen sinkt der verknüpfte Vorrat des Tieres.',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_isEdit ? 'Speichern' : 'Anlegen'),
              ),
              if (_isEdit)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Aufgabe löschen'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    await ref
        .read(petRepositoryProvider)
        .upsertTask(
          id: widget.task?.id,
          scope: ref.read(activeScopeProvider),
          petId: widget.petId,
          userId: ref.read(identityProvider).userId,
          title: title,
          iconKey: _iconKey,
          timesPerDay: _timesPerDay,
          consumesFood: _consumesFood,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(petRepositoryProvider)
        .deleteTask(widget.task!.id, ref.read(identityProvider).userId);
    if (mounted) Navigator.of(context).pop();
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onTap,
      isSelected: selected,
      style: IconButton.styleFrom(
        backgroundColor: selected ? scheme.primary : null,
        foregroundColor: selected ? scheme.onPrimary : null,
      ),
      icon: Icon(icon),
    );
  }
}
