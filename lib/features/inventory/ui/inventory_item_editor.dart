import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../data/db/app_database.dart';
import '../data/open_food_facts_service.dart';
import '../domain/measurement_unit.dart';
import '../domain/storage_icons.dart';
import '../inventory_providers.dart';

/// Formular zum Anlegen und Bearbeiten eines Vorrats.
class InventoryItemEditor extends ConsumerStatefulWidget {
  const InventoryItemEditor({super.key, this.item, this.prefill, this.barcode});

  /// Beim Bearbeiten gesetzt.
  final InventoryItem? item;

  /// Aus der Produktdatenbank übernommene Werte.
  final ProductLookupResult? prefill;

  /// Gescannter Code, auch wenn kein Produkt gefunden wurde.
  final String? barcode;

  static Future<bool?> show(
    BuildContext context, {
    InventoryItem? item,
    ProductLookupResult? prefill,
    String? barcode,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) =>
          InventoryItemEditor(item: item, prefill: prefill, barcode: barcode),
    );
  }

  @override
  ConsumerState<InventoryItemEditor> createState() =>
      _InventoryItemEditorState();
}

class _InventoryItemEditorState extends ConsumerState<InventoryItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _minQuantity;
  late final TextEditingController _note;

  late MeasurementUnit _unit;
  String? _locationId;
  DateTime? _expiresAt;
  late bool _remindOnExpiry;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final prefill = widget.prefill;

    _name = TextEditingController(text: item?.name ?? prefill?.name ?? '');
    _quantity = TextEditingController(
      text: _formatNumber(item?.quantity ?? prefill?.quantity ?? 1),
    );
    _minQuantity = TextEditingController(
      text: item?.minQuantity == null ? '' : _formatNumber(item!.minQuantity!),
    );
    _note = TextEditingController(text: item?.note ?? '');
    _unit = MeasurementUnit.parse(item?.unit ?? prefill?.unit.name);
    _locationId = item?.locationId;
    _expiresAt = item?.expiresAt;
    _remindOnExpiry = item?.remindOnExpiry ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _minQuantity.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString().replaceAll('.', ',');

  static double? _parseNumber(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(activeScopeProvider);
    final locations = ref.watch(storageLocationsProvider).value ?? const [];
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Vorrat bearbeiten' : 'Vorrat hinzufügen',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const ScopeChip(),
                  ],
                ),
                if (widget.barcode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.barcode!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  autofocus: !_isEdit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Bezeichnung'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Bitte einen Namen angeben'
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
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
                DropdownButtonFormField<String?>(
                  initialValue: _locationId,
                  decoration: const InputDecoration(labelText: 'Ort'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Ohne Ort'),
                    ),
                    for (final location in locations)
                      DropdownMenuItem<String?>(
                        value: location.id,
                        child: Row(
                          children: [
                            Icon(storageIconFor(location.iconKey), size: 18),
                            const SizedBox(width: 8),
                            Text(location.name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _locationId = value),
                ),
                const SizedBox(height: 12),
                _ExpiryField(
                  value: _expiresAt,
                  onChanged: (value) => setState(() => _expiresAt = value),
                ),
                if (_expiresAt != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _remindOnExpiry,
                    onChanged: (value) =>
                        setState(() => _remindOnExpiry = value),
                    title: const Text('Vor Ablauf erinnern'),
                    subtitle: const Text(
                      'Gilt nur für diesen Artikel. Global abschaltbar in den '
                      'Einstellungen.',
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minQuantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mindestbestand (optional)',
                    helperText: 'Darunter gilt der Vorrat als knapp.',
                  ),
                ),
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
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isEdit
                        ? 'Speichern'
                        : scopeActionLabel(scope, verb: 'Hinzufügen'),
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _saving ? null : _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Aus dem Inventar löschen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vorrat löschen?'),
        content: Text('"${widget.item!.name}" wird aus dem Inventar entfernt.'),
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
    if (confirmed != true) return;

    await ref
        .read(inventoryRepositoryProvider)
        .deleteItem(widget.item!.id, ref.read(identityProvider).userId);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final scope = ref.read(activeScopeProvider);
    final userId = ref.read(identityProvider).userId;
    final repository = ref.read(inventoryRepositoryProvider);

    final quantity = _parseNumber(_quantity.text) ?? 1;
    final minQuantity = _minQuantity.text.trim().isEmpty
        ? null
        : _parseNumber(_minQuantity.text);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    if (_isEdit) {
      await repository.updateItem(
        id: widget.item!.id,
        userId: userId,
        name: _name.text.trim(),
        quantity: quantity,
        unit: _unit.name,
        locationId: Value(_locationId),
        expiresAt: Value(_expiresAt),
        minQuantity: Value(minQuantity),
        note: Value(note),
        remindOnExpiry: _remindOnExpiry,
      );
    } else {
      String? productId;
      final prefill = widget.prefill;
      if (prefill != null) {
        productId = await repository.saveProduct(
          scope: scope,
          userId: userId,
          name: prefill.name,
          barcode: prefill.barcode,
          brand: prefill.brand,
          imageUrl: prefill.imageUrl,
          category: prefill.category,
          unit: prefill.unit.name,
          defaultQuantity: prefill.quantity,
          source: 'openfoodfacts',
        );
      } else if (widget.barcode != null) {
        // Unbekannter Code: als eigenes Produkt im Kontext merken, damit der
        // nächste Scan ihn ohne Netz erkennt.
        productId = await repository.saveProduct(
          scope: scope,
          userId: userId,
          name: _name.text.trim(),
          barcode: widget.barcode,
          unit: _unit.name,
          defaultQuantity: quantity,
        );
      }

      await repository.addItem(
        scope: scope,
        userId: userId,
        name: _name.text.trim(),
        quantity: quantity,
        unit: _unit.name,
        barcode: widget.barcode,
        productId: productId,
        locationId: _locationId,
        expiresAt: _expiresAt,
        minQuantity: minQuantity,
        note: note,
        remindOnExpiry: _remindOnExpiry,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }
}

class _ExpiryField extends StatelessWidget {
  const _ExpiryField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? 'Kein Datum'
        : DateFormat('dd.MM.yyyy', 'de').format(value!);

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Haltbar bis'),
      child: Row(
        children: [
          Expanded(child: Text(formatted)),
          if (value != null)
            IconButton(
              tooltip: 'Datum entfernen',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear_rounded),
            ),
          IconButton(
            tooltip: 'Datum wählen',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now.add(const Duration(days: 7)),
                firstDate: DateTime(now.year - 1),
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
