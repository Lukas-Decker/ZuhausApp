import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../core/widgets/sheet_insets.dart';
import '../../../data/db/app_database.dart';
import '../../inventory/domain/measurement_unit.dart';
import '../domain/shopping_category.dart';
import '../shopping_providers.dart';

/// Formular für einen Einkaufsposten mit Menge, Warengruppe und Notiz.
class ShoppingItemEditor extends ConsumerStatefulWidget {
  const ShoppingItemEditor({
    super.key,
    required this.listId,
    this.item,
    this.initialName,
  });

  final String listId;
  final ShoppingItem? item;
  final String? initialName;

  static Future<bool?> show(
    BuildContext context, {
    required String listId,
    ShoppingItem? item,
    String? initialName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => ShoppingItemEditor(
        listId: listId,
        item: item,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<ShoppingItemEditor> createState() => _ShoppingItemEditorState();
}

class _ShoppingItemEditorState extends ConsumerState<ShoppingItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _note;

  late MeasurementUnit _unit;
  late ShoppingCategory _category;
  bool _categoryTouched = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? widget.initialName ?? '')
      ..addListener(_guessCategory);
    _quantity = TextEditingController(
      text: _formatNumber(item?.quantity ?? 1),
    );
    _note = TextEditingController(text: item?.note ?? '');
    _unit = MeasurementUnit.parse(item?.unit);
    _category = item != null
        ? ShoppingCategory.parse(item.category)
        : ShoppingCategory.guess(widget.initialName ?? '');
    _categoryTouched = item != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Solange die Warengruppe nicht von Hand gesetzt wurde, folgt sie dem Namen.
  void _guessCategory() {
    if (_categoryTouched) return;
    final guessed = ShoppingCategory.guess(_name.text);
    if (guessed != _category) setState(() => _category = guessed);
  }

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString().replaceAll('.', ',');

  static double? _parseNumber(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(activeScopeProvider);
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Posten bearbeiten' : 'Posten hinzufügen',
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
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Was?'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Bitte etwas eingeben'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(labelText: 'Menge'),
                        validator: (value) => _parseNumber(value ?? '') == null
                            ? 'Zahl eingeben'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<MeasurementUnit>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Einheit'),
                        items: [
                          for (final unit in MeasurementUnit.values)
                            DropdownMenuItem(
                              value: unit,
                              child: Text(unit.label),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _unit = value ?? _unit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ShoppingCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Warengruppe'),
                  items: [
                    for (final category in ShoppingCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(category.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _category = value ?? _category;
                    _categoryTouched = true;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                    hintText: 'z.B. Marke oder Größe',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    _isEdit
                        ? 'Speichern'
                        : scopeActionLabel(scope, verb: 'Auf die Liste'),
                  ),
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

    final userId = ref.read(identityProvider).userId;
    final repository = ref.read(shoppingRepositoryProvider);
    final quantity = _parseNumber(_quantity.text) ?? 1;
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    if (_isEdit) {
      await repository.updateItem(
        id: widget.item!.id,
        userId: userId,
        name: _name.text.trim(),
        quantity: quantity,
        unit: _unit.name,
        category: _category.name,
        note: Value(note),
      );
    } else {
      await repository.addItem(
        scope: ref.read(activeScopeProvider),
        listId: widget.listId,
        userId: userId,
        name: _name.text.trim(),
        quantity: quantity,
        unit: _unit.name,
        category: _category.name,
        note: note,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }
}
