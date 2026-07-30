import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/add_ghost_tile.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/pet_repository.dart';
import '../domain/pet_types.dart';
import '../pets_providers.dart';
import 'pet_detail_screen.dart';
import 'pet_editor.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);

    return ModuleScaffold(
      title: 'Tiere',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PetEditor.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tier'),
      ),
      body: pets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Fehler',
          message: '$error',
        ),
        data: (list) => list.isEmpty
            ? Column(
                children: [
                  const Expanded(
                    child: EmptyState(
                      icon: Icons.pets_outlined,
                      title: 'Noch keine Tiere',
                      message:
                          'Lege ein Tier an, um Fütterung, Arznei und Gewicht '
                          'zu verfolgen.',
                    ),
                  ),
                  AddGhostTile(
                    label: 'Tier hinzufügen',
                    onTap: () => PetEditor.show(context),
                  ),
                  const SizedBox(height: 96),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                itemCount: list.length + 1,
                itemBuilder: (context, index) => index == list.length
                    ? AddGhostTile(
                        label: 'Tier hinzufügen',
                        onTap: () => PetEditor.show(context),
                      )
                    : _PetCard(pet: list[index]),
              ),
      ),
    );
  }
}

class _PetCard extends ConsumerWidget {
  const _PetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species = petSpeciesInfo(pet.species);
    final tasks = ref.watch(petTaskStatusProvider(pet.id));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PetDetailScreen(petId: pet.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _PetAvatar(pet: pet, icon: species.icon, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [species.label, if (pet.breed != null) pet.breed!]
                          .join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    tasks.maybeWhen(
                      data: (list) => _TaskSummary(statuses: list),
                      orElse: () => const SizedBox(height: 4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kompakte Chips für die heutigen Aufgaben, direkt abhakbar.
class _TaskSummary extends ConsumerWidget {
  const _TaskSummary({required this.statuses});

  final List<PetTaskStatus> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (statuses.isEmpty) {
      return Text(
        'Keine Tagesaufgaben',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final status in statuses)
          _TaskChip(status: status),
      ],
    );
  }
}

class _TaskChip extends ConsumerWidget {
  const _TaskChip({required this.status});

  final PetTaskStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = petTaskIcon(status.task.iconKey);
    final scheme = Theme.of(context).colorScheme;
    final done = status.isComplete;

    return ActionChip(
      avatar: Icon(
        done ? Icons.check_circle_rounded : icon.icon,
        size: 18,
        color: done ? scheme.onPrimary : scheme.onSurfaceVariant,
      ),
      label: Text(
        status.task.timesPerDay > 1
            ? '${status.task.title} ${status.doneToday}/${status.task.timesPerDay}'
            : status.task.title,
        style: TextStyle(color: done ? scheme.onPrimary : null),
      ),
      backgroundColor: done ? scheme.primary : null,
      onPressed: () => _quickToggle(context, ref),
    );
  }

  Future<void> _quickToggle(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(petRepositoryProvider);
    final identity = ref.read(identityProvider);
    final scope = ref.read(activeScopeProvider);

    if (status.isComplete) {
      await repo.undoTaskDone(task: status.task, userId: identity.userId);
    } else {
      await repo.markTaskDone(
        scope: scope,
        task: status.task,
        userId: identity.userId,
        doneByName: identity.displayName,
      );
      if (status.lastDoneBy != null &&
          status.lastDoneBy != identity.displayName &&
          context.mounted) {
        // Hinweis, falls jemand anderes die Aufgabe heute schon gemacht hat.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${status.task.title}: heute schon von ${status.lastDoneBy} erledigt.',
            ),
          ),
        );
      }
    }
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet, required this.icon, this.radius = 24});

  final Pet pet;
  final IconData icon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = pet.photoPath;
    if (photo != null && File(photo).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photo)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.secondaryContainer,
      child: Icon(icon, color: scheme.onSecondaryContainer),
    );
  }
}
