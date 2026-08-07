import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/sheet_insets.dart';
import '../../../data/db/app_database.dart';
import '../domain/pet_types.dart';
import '../pets_providers.dart';

/// Formular für ein Gesundheitsereignis (Arznei, Impfung, Termin ...).
class PetHealthEditor extends ConsumerStatefulWidget {
  const PetHealthEditor({super.key, required this.petId, this.entry});

  final String petId;
  final PetHealthEntry? entry;

  static Future<void> show(
    BuildContext context, {
    required String petId,
    PetHealthEntry? entry,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => PetHealthEditor(petId: petId, entry: entry),
    );
  }

  @override
  ConsumerState<PetHealthEditor> createState() => _PetHealthEditorState();
}

class _PetHealthEditorState extends ConsumerState<PetHealthEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;

  late PetHealthKind _kind;
  late DateTime _dueAt;
  DateTime? _nextDueAt;
  late int _leadDays;
  late bool _reminders;

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _note = TextEditingController(text: entry?.note ?? '');
    _kind = PetHealthKind.parse(entry?.kind);
    _dueAt = entry?.dueAt ?? DateTime.now();
    _nextDueAt = entry?.nextDueAt;
    _leadDays = entry?.reminderLeadDays ?? 2;
    _reminders = entry?.remindersEnabled ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = sheetBottomInset(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit ? 'Eintrag bearbeiten' : 'Gesundheitseintrag',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<PetHealthKind>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Art'),
                  items: [
                    for (final kind in PetHealthKind.values)
                      DropdownMenuItem(
                        value: kind,
                        child: Row(
                          children: [
                            Icon(kind.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(kind.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _kind = value ?? _kind),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  autofocus: !_isEdit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    hintText: 'z.B. Tollwut-Impfung',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Bitte Titel angeben' : null,
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Fällig am',
                  value: _dueAt,
                  onChanged: (d) => setState(() => _dueAt = d ?? _dueAt),
                  allowClear: false,
                ),
                _DateField(
                  label: 'Nächste Fälligkeit (optional)',
                  value: _nextDueAt,
                  onChanged: (d) => setState(() => _nextDueAt = d),
                  allowClear: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Notiz (optional)'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reminders,
                  onChanged: (value) => setState(() => _reminders = value),
                  title: const Text('Vorlauf-Erinnerung'),
                  subtitle: Text('$_leadDays Tage vorher'),
                ),
                if (_reminders)
                  Slider(
                    value: _leadDays.toDouble(),
                    min: 0,
                    max: 14,
                    divisions: 14,
                    label: '$_leadDays Tage',
                    onChanged: (value) =>
                        setState(() => _leadDays = value.round()),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isEdit ? 'Speichern' : 'Anlegen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(petRepositoryProvider)
        .upsertHealthEntry(
          id: widget.entry?.id,
          scope: ref.read(activeScopeProvider),
          petId: widget.petId,
          userId: ref.read(identityProvider).userId,
          kind: _kind.key,
          title: _title.text.trim(),
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          dueAt: _dueAt,
          nextDueAt: _nextDueAt,
          reminderLeadDays: _leadDays,
          remindersEnabled: _reminders,
        );
    if (mounted) Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.allowClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null
                  ? 'Kein Datum'
                  : DateFormat('dd.MM.yyyy', 'de').format(value!),
            ),
          ),
          if (value != null && allowClear)
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear_rounded),
            ),
          IconButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 10),
              );
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.event_rounded),
          ),
        ],
      ),
    );
  }
}
