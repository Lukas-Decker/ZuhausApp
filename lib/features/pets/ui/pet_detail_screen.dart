import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/sheet_insets.dart';
import '../../../core/providers.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/pet_repository.dart';
import '../domain/pet_types.dart';
import '../pets_providers.dart';
import 'pet_editor.dart';
import 'pet_health_editor.dart';
import 'pet_task_editor.dart';
import 'pet_weight_chart.dart';

class PetDetailScreen extends ConsumerWidget {
  const PetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(petProvider(petId));

    return pet.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Fehler: $error'))),
      data: (value) {
        if (value == null) return const Scaffold(body: SizedBox.shrink());
        return _PetDetail(pet: value);
      },
    );
  }
}

class _PetDetail extends ConsumerWidget {
  const _PetDetail({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species = petSpeciesInfo(pet.species);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pet.name),
          actions: [
            IconButton(
              tooltip: 'Bearbeiten',
              onPressed: () => PetEditor.show(context, pet: pet),
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _onMenu(context, ref, value),
              itemBuilder: (_) => const [
                PopupMenuItem(
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aufgaben'),
              Tab(text: 'Gesundheit'),
              Tab(text: 'Gewicht'),
            ],
          ),
        ),
        body: Column(
          children: [
            _PetHeader(pet: pet, icon: species.icon),
            Expanded(
              child: TabBarView(
                children: [
                  _TasksTab(pet: pet),
                  _HealthTab(pet: pet),
                  _WeightTab(pet: pet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String value) async {
    if (value != 'delete') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tier löschen?'),
        content: Text('"${pet.name}" und alle zugehörigen Daten werden entfernt.'),
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
      await ref
          .read(petRepositoryProvider)
          .deletePet(pet.id, ref.read(identityProvider).userId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _PetHeader extends StatelessWidget {
  const _PetHeader({required this.pet, required this.icon});

  final Pet pet;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = pet.photoPath;
    final hasPhoto = photo != null && File(photo).existsSync();
    final hasBreed = pet.breed != null && pet.breed!.isNotEmpty;
    final hasNote = pet.note != null && pet.note!.isNotEmpty;

    // Ohne Foto und ohne Zusatzangaben gibt es nichts zu zeigen: dann lieber
    // gar keinen Kopfbereich, statt Platz fuer Art-Icon und Artname zu opfern.
    if (!hasPhoto && !hasBreed && !hasNote && pet.birthday == null) {
      return const SizedBox.shrink();
    }

    final details = [
      if (hasBreed) pet.breed!,
      if (pet.birthday != null) _ageText(pet.birthday!),
      if (hasNote) pet.note!,
    ].join(' · ');

    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.secondaryContainer,
            backgroundImage: hasPhoto ? FileImage(File(photo)) : null,
            child: hasPhoto
                ? null
                : Icon(icon, size: 18, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static String _ageText(DateTime birthday) {
    final now = DateTime.now();
    var years = now.year - birthday.year;
    var months = now.month - birthday.month;
    if (now.day < birthday.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    final parts = <String>[
      if (years > 0) '$years ${years == 1 ? "Jahr" : "Jahre"}',
      if (months > 0) '$months ${months == 1 ? "Monat" : "Monate"}',
    ];
    final age = parts.isEmpty ? 'unter 1 Monat' : parts.join(', ');
    return '$age · geb. ${DateFormat('dd.MM.yyyy', 'de').format(birthday)}';
  }
}

// --- Tab: Aufgaben ----------------------------------------------------------

class _TasksTab extends ConsumerWidget {
  const _TasksTab({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(petTaskStatusProvider(pet.id));

    return Stack(
      children: [
        statuses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Fehler: $error')),
          data: (list) => list.isEmpty
              ? _emptyHint(context, 'Keine Tagesaufgaben. Füge welche hinzu.')
              : ListView(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 88 + systemBottomInset(context)),
                  children: [
                    for (final status in list)
                      _TaskRow(pet: pet, status: status),
                  ],
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'addTask',
            onPressed: () => PetTaskEditor.show(context, petId: pet.id),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.pet, required this.status});

  final Pet pet;
  final PetTaskStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = petTaskIcon(status.task.iconKey);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: status.isComplete ? scheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(icon.icon),
        title: Text(status.task.title),
        subtitle: _subtitle(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.doneToday > 0)
              IconButton(
                tooltip: 'Zurücknehmen',
                onPressed: () => ref
                    .read(petRepositoryProvider)
                    .undoTaskDone(
                      task: status.task,
                      userId: ref.read(identityProvider).userId,
                    ),
                icon: const Icon(Icons.undo_rounded),
              ),
            FilledButton(
              onPressed: status.isComplete ? null : () => _markDone(ref),
              child: Text(
                status.task.timesPerDay > 1
                    ? '${status.doneToday}/${status.task.timesPerDay}'
                    : 'Erledigt',
              ),
            ),
          ],
        ),
        onLongPress: () =>
            PetTaskEditor.show(context, petId: pet.id, task: status.task),
      ),
    );
  }

  Widget? _subtitle(BuildContext context) {
    if (status.lastDoneAt == null) {
      return status.task.consumesFood
          ? const Text('Zieht Futtervorrat ab')
          : null;
    }
    final time = DateFormat('HH:mm', 'de').format(status.lastDoneAt!);
    final by = status.lastDoneBy;
    return Text(
      by == null ? 'Zuletzt um $time' : 'Zuletzt $time von $by',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  void _markDone(WidgetRef ref) {
    ref
        .read(petRepositoryProvider)
        .markTaskDone(
          scope: ref.read(activeScopeProvider),
          task: status.task,
          userId: ref.read(identityProvider).userId,
          doneByName: ref.read(identityProvider).displayName,
        );
  }
}

// --- Tab: Gesundheit --------------------------------------------------------

class _HealthTab extends ConsumerWidget {
  const _HealthTab({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(petHealthProvider(pet.id));

    return Stack(
      children: [
        entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Fehler: $error')),
          data: (list) => list.isEmpty
              ? _emptyHint(
                  context,
                  'Keine Einträge. Erfasse Impfungen, Arznei oder Termine.',
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 88 + systemBottomInset(context)),
                  children: [
                    for (final entry in list)
                      _HealthRow(pet: pet, entry: entry),
                  ],
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'addHealth',
            onPressed: () => PetHealthEditor.show(context, petId: pet.id),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _HealthRow extends ConsumerWidget {
  const _HealthRow({required this.pet, required this.entry});

  final Pet pet;
  final PetHealthEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = PetHealthKind.parse(entry.kind);
    final scheme = Theme.of(context).colorScheme;
    final due = entry.dueAt;
    final now = DateTime.now();
    final daysUntil = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    final Color accent;
    if (entry.isDone) {
      accent = scheme.onSurfaceVariant;
    } else if (daysUntil < 0) {
      accent = scheme.error;
    } else if (daysUntil <= entry.reminderLeadDays) {
      accent = scheme.tertiary;
    } else {
      accent = scheme.onSurfaceVariant;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(kind.icon, color: entry.isDone ? scheme.onSurfaceVariant : null),
        title: Text(
          entry.title,
          style: entry.isDone
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${kind.label} · ${_dueText(due, daysUntil, entry.isDone)}',
              style: TextStyle(color: accent),
            ),
            if (entry.note != null && entry.note!.isNotEmpty)
              Text(entry.note!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        isThreeLine: entry.note != null && entry.note!.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: entry.isDone,
              onChanged: (value) => ref
                  .read(petRepositoryProvider)
                  .setHealthDone(
                    entry.id,
                    value ?? false,
                    ref.read(identityProvider).userId,
                  ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await PetHealthEditor.show(context, petId: pet.id, entry: entry);
                } else if (value == 'delete') {
                  await ref
                      .read(petRepositoryProvider)
                      .deleteHealthEntry(
                        entry.id,
                        ref.read(identityProvider).userId,
                      );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                PopupMenuItem(value: 'delete', child: Text('Löschen')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _dueText(DateTime due, int daysUntil, bool done) {
    final date = DateFormat('dd.MM.yyyy', 'de').format(due);
    if (done) return 'erledigt';
    return switch (daysUntil) {
      < 0 => 'überfällig seit $date',
      0 => 'heute fällig',
      1 => 'morgen fällig',
      _ => 'am $date (in $daysUntil Tagen)',
    };
  }
}

// --- Tab: Gewicht -----------------------------------------------------------

class _WeightTab extends ConsumerWidget {
  const _WeightTab({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(petWeightsProvider(pet.id));

    return Stack(
      children: [
        weights.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Fehler: $error')),
          data: (list) => list.isEmpty
              ? _emptyHint(context, 'Noch keine Messungen. Trage ein Gewicht ein.')
              : ListView(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 88 + systemBottomInset(context)),
                  children: [
                    PetWeightChart(entries: list),
                    const SizedBox(height: 8),
                    for (final entry in list.reversed)
                      Dismissible(
                        key: ValueKey(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: const Icon(Icons.delete_outline_rounded),
                        ),
                        onDismissed: (_) =>
                            ref.read(petRepositoryProvider).deleteWeight(entry.id),
                        child: ListTile(
                          leading: const Icon(Icons.monitor_weight_outlined),
                          title: Text('${_fmt(entry.weightKg)} kg'),
                          subtitle: Text(
                            DateFormat('dd.MM.yyyy', 'de').format(entry.measuredAt),
                          ),
                          trailing: entry.note == null
                              ? null
                              : Text(entry.note!),
                        ),
                      ),
                  ],
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'addWeight',
            onPressed: () => _addWeight(context, ref),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  Future<void> _addWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gewicht eintragen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Gewicht',
            suffixText: 'kg',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(
            double.tryParse(value.replaceAll(',', '.')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result <= 0) return;
    await ref
        .read(petRepositoryProvider)
        .addWeight(
          scope: ref.read(activeScopeProvider),
          petId: pet.id,
          userId: ref.read(identityProvider).userId,
          weightKg: result,
        );
  }
}

Widget _emptyHint(BuildContext context, String text) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
