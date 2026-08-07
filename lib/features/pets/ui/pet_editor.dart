import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../core/widgets/sheet_insets.dart';
import '../../../data/db/app_database.dart';
import '../../inventory/domain/measurement_unit.dart';
import '../../inventory/inventory_providers.dart';
import '../domain/pet_types.dart';
import '../pets_providers.dart';

/// Formular zum Anlegen und Bearbeiten eines Tieres.
class PetEditor extends ConsumerStatefulWidget {
  const PetEditor({super.key, this.pet});

  final Pet? pet;

  static Future<bool?> show(BuildContext context, {Pet? pet}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => PetEditor(pet: pet),
    );
  }

  @override
  ConsumerState<PetEditor> createState() => _PetEditorState();
}

class _PetEditorState extends ConsumerState<PetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _note;
  late final TextEditingController _portion;

  late String _species;
  DateTime? _birthday;
  String? _foodItemId;

  bool get _isEdit => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _name = TextEditingController(text: pet?.name ?? '');
    _breed = TextEditingController(text: pet?.breed ?? '');
    _note = TextEditingController(text: pet?.note ?? '');
    _portion = TextEditingController(
      text: pet?.foodPortion == null ? '' : _fmt(pet!.foodPortion!),
    );
    _species = pet?.species ?? 'dog';
    _birthday = pet?.birthday;
    _foodItemId = pet?.foodInventoryItemId;
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _note.dispose();
    _portion.dispose();
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
  static double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final bottomInset = sheetBottomInset(context);
    final inventory = ref.watch(inventoryItemsProvider).value ?? const [];

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Tier bearbeiten' : 'Tier hinzufügen',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const ScopeChip(),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  autofocus: !_isEdit,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Bitte Name angeben' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _species,
                  decoration: const InputDecoration(labelText: 'Tierart'),
                  items: [
                    for (final entry in petSpecies.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(entry.value.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(entry.value.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _species = value ?? _species),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _breed,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Rasse (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                _BirthdayRow(
                  value: _birthday,
                  onChanged: (d) => setState(() => _birthday = d),
                ),
                const SizedBox(height: 20),
                Text(
                  'Futtervorrat',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _foodItemId,
                  decoration: const InputDecoration(
                    labelText: 'Verknüpfter Vorrat (optional)',
                    helperText: 'Wird beim Füttern heruntergezählt.',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Keiner'),
                    ),
                    for (final entry in inventory)
                      DropdownMenuItem<String?>(
                        value: entry.item.id,
                        child: Text(
                          entry.item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _foodItemId = value),
                ),
                if (_foodItemId != null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _portion,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Portion je Fütterung',
                      helperText: _portionHelper(inventory),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isEdit ? 'Speichern' : 'Anlegen'),
                ),
                if (!_isEdit)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Typische Tagesaufgaben werden automatisch angelegt und '
                      'lassen sich danach anpassen.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _portionHelper(List inventory) {
    for (final entry in inventory) {
      if (entry.item.id == _foodItemId) {
        final unit = MeasurementUnit.parse(entry.item.unit);
        return 'Einheit: ${unit.label}';
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final scope = ref.read(activeScopeProvider);
    final userId = ref.read(identityProvider).userId;
    final repo = ref.read(petRepositoryProvider);

    final petId = await repo.upsertPet(
      id: widget.pet?.id,
      scope: scope,
      userId: userId,
      name: _name.text.trim(),
      species: _species,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      birthday: _birthday,
      foodInventoryItemId: Value(_foodItemId),
      foodPortion: Value(_foodItemId == null ? null : _parse(_portion.text)),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );

    if (!_isEdit) {
      final defaults = petDefaultTasks[_species] ?? petDefaultTasks['other']!;
      await repo.seedDefaultTasks(
        scope: scope,
        petId: petId,
        userId: userId,
        tasks: defaults,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Geburtstag (optional)'),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value == null
                  ? 'Kein Datum'
                  : DateFormat('dd.MM.yyyy', 'de').format(value!),
            ),
          ),
          if (value != null)
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear_rounded),
            ),
          IconButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime(now.year - 2),
                firstDate: DateTime(now.year - 40),
                lastDate: now,
              );
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.cake_rounded),
          ),
        ],
      ),
    );
  }
}
