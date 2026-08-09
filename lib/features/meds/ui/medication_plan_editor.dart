import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_texts.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../core/widgets/sheet_insets.dart';
import '../../../data/db/app_database.dart';
import '../domain/medication_schedule.dart';
import '../meds_providers.dart';

/// Formular zum Anlegen und Bearbeiten eines Medikamentenplans.
class MedicationPlanEditor extends ConsumerStatefulWidget {
  const MedicationPlanEditor({super.key, this.plan});

  final MedicationPlan? plan;

  static Future<bool?> show(BuildContext context, {MedicationPlan? plan}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => MedicationPlanEditor(plan: plan),
    );
  }

  @override
  ConsumerState<MedicationPlanEditor> createState() =>
      _MedicationPlanEditorState();
}

class _MedicationPlanEditorState extends ConsumerState<MedicationPlanEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _note;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;

  late String _form;
  late ScheduleType _scheduleType;
  late List<TimeOfDay> _times;
  late Set<int> _weekdays;
  late int _intervalHours;
  DateTime? _startDate;
  DateTime? _endDate;
  late bool _remindersEnabled;
  late bool _sharedWithHousehold;

  bool get _isEdit => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _name = TextEditingController(text: plan?.name ?? '');
    _dosage = TextEditingController(text: plan?.dosage ?? '');
    _note = TextEditingController(text: plan?.note ?? '');
    _stock = TextEditingController(
      text: plan?.stockCount == null ? '' : _fmt(plan!.stockCount!),
    );
    _threshold = TextEditingController(
      text: plan?.stockThreshold == null ? '' : _fmt(plan!.stockThreshold!),
    );
    _form = plan?.form ?? 'tablet';
    _scheduleType = ScheduleType.parse(plan?.scheduleType);
    _times = plan == null
        ? [const TimeOfDay(hour: 8, minute: 0)]
        : ScheduleTimes.parse(plan.times);
    if (_times.isEmpty) _times = [const TimeOfDay(hour: 8, minute: 0)];
    _weekdays = plan == null ? {} : ScheduleWeekdays.parse(plan.weekdays);
    _intervalHours = plan?.intervalHours ?? 8;
    _startDate = plan?.startDate;
    _endDate = plan?.endDate;
    _remindersEnabled = plan?.remindersEnabled ?? true;
    _sharedWithHousehold = plan?.sharedWithHousehold ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _note.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
  static double? _parse(String raw) =>
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
                        _isEdit ? 'Plan bearbeiten' : 'Medikament hinzufügen',
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
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'z.B. Ibuprofen 400',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Bitte Name angeben' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _form,
                        decoration: const InputDecoration(labelText: 'Form'),
                        items: [
                          for (final entry in medicationForms.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Icon(entry.value.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    medicationFormLabel(entry.key, context.l10n),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _form = value ?? _form),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dosage,
                        decoration: const InputDecoration(
                          labelText: 'Dosis',
                          hintText: '1 Tablette',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ScheduleSection(
                  type: _scheduleType,
                  onTypeChanged: (t) => setState(() => _scheduleType = t),
                  times: _times,
                  onTimesChanged: (t) => setState(() => _times = t),
                  weekdays: _weekdays,
                  onWeekdaysChanged: (w) => setState(() => _weekdays = w),
                  intervalHours: _intervalHours,
                  onIntervalChanged: (h) => setState(() => _intervalHours = h),
                ),
                const SizedBox(height: 20),
                _DateRow(
                  label: 'Beginn (optional)',
                  value: _startDate,
                  onChanged: (d) => setState(() => _startDate = d),
                ),
                _DateRow(
                  label: 'Kur-Ende (optional)',
                  value: _endDate,
                  onChanged: (d) => setState(() => _endDate = d),
                ),
                const SizedBox(height: 20),
                Text('Vorrat', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(labelText: 'Bestand'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _threshold,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Warnschwelle',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Der Bestand sinkt bei jeder Einnahme; bei der Warnschwelle '
                  'wird er knapp.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                    hintText: 'z.B. zu den Mahlzeiten',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _remindersEnabled,
                  onChanged: (v) => setState(() => _remindersEnabled = v),
                  title: const Text('An Einnahme erinnern'),
                  subtitle: const Text(
                    'Nur für diesen Plan. Global abschaltbar in den '
                    'Einstellungen.',
                  ),
                ),
                if (scope.isHousehold)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _sharedWithHousehold,
                    onChanged: (v) => setState(() => _sharedWithHousehold = v),
                    title: const Text('Mit dem Haushalt teilen'),
                    subtitle: const Text(
                      'Gesundheitsdaten sind sonst nur für dich sichtbar.',
                    ),
                  ),
                const SizedBox(height: 20),
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
    if (_scheduleType == ScheduleType.daily && _times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens eine Uhrzeit angeben.')),
      );
      return;
    }

    await ref
        .read(medicationRepositoryProvider)
        .upsertPlan(
          id: widget.plan?.id,
          scope: ref.read(activeScopeProvider),
          userId: ref.read(identityProvider).userId,
          name: _name.text.trim(),
          dosage: _dosage.text.trim(),
          form: _form,
          scheduleType: _scheduleType.key,
          times: ScheduleTimes.format(_times),
          weekdays: ScheduleWeekdays.format(_weekdays),
          intervalHours: _intervalHours,
          startDate: _startDate,
          endDate: _endDate,
          stockCount: _parse(_stock.text),
          stockThreshold: _parse(_threshold.text),
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          remindersEnabled: _remindersEnabled,
          sharedWithHousehold: _sharedWithHousehold,
          isActive: widget.plan?.isActive ?? true,
        );

    if (mounted) Navigator.of(context).pop(true);
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.type,
    required this.onTypeChanged,
    required this.times,
    required this.onTimesChanged,
    required this.weekdays,
    required this.onWeekdaysChanged,
    required this.intervalHours,
    required this.onIntervalChanged,
  });

  final ScheduleType type;
  final ValueChanged<ScheduleType> onTypeChanged;
  final List<TimeOfDay> times;
  final ValueChanged<List<TimeOfDay>> onTimesChanged;
  final Set<int> weekdays;
  final ValueChanged<Set<int>> onWeekdaysChanged;
  final int intervalHours;
  final ValueChanged<int> onIntervalChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Einnahme', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ScheduleType>(
          segments: [
            for (final t in ScheduleType.values)
              ButtonSegment(value: t, label: Text(t.label)),
          ],
          selected: {type},
          onSelectionChanged: (s) => onTypeChanged(s.first),
        ),
        const SizedBox(height: 12),
        if (type == ScheduleType.daily) ...[
          _TimesEditor(times: times, onChanged: onTimesChanged),
          const SizedBox(height: 12),
          _WeekdayPicker(selected: weekdays, onChanged: onWeekdaysChanged),
        ] else
          Row(
            children: [
              const Text('Alle '),
              DropdownButton<int>(
                value: intervalHours,
                items: [
                  for (final h in const [4, 6, 8, 12, 24])
                    DropdownMenuItem(value: h, child: Text('$h')),
                ],
                onChanged: (h) => onIntervalChanged(h ?? intervalHours),
              ),
              const Text(' Stunden'),
            ],
          ),
      ],
    );
  }
}

class _TimesEditor extends StatelessWidget {
  const _TimesEditor({required this.times, required this.onChanged});

  final List<TimeOfDay> times;
  final ValueChanged<List<TimeOfDay>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final time in times)
          InputChip(
            label: Text(ScheduleTimes.formatTime(time)),
            onDeleted: times.length <= 1
                ? null
                : () => onChanged(
                    [...times]..remove(time),
                  ),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                onChanged([
                  for (final t in times) t == time ? picked : t,
                ]);
              }
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Uhrzeit'),
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 12, minute: 0),
            );
            if (picked != null) onChanged([...times, picked]);
          },
        ),
      ],
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(ScheduleWeekdays.labels[day - 1]),
            selected: selected.isEmpty || selected.contains(day),
            onSelected: (value) {
              final next = selected.isEmpty
                  ? {1, 2, 3, 4, 5, 6, 7}
                  : {...selected};
              if (value) {
                next.add(day);
              } else {
                next.remove(day);
              }
              // Alle sieben ausgewählt wird als "täglich" (leer) gespeichert.
              onChanged(next.length == 7 ? {} : next);
            },
          ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (value != null) ...[
            Text(DateFormat('dd.MM.yyyy', 'de').format(value!)),
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
          TextButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) onChanged(picked);
            },
            child: Text(value == null ? 'Wählen' : 'Ändern'),
          ),
        ],
      ),
    );
  }
}
