import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/pet_repository.dart';
import '../inventory/inventory_providers.dart';

final petRepositoryProvider = Provider<PetRepository>(
  (ref) => PetRepository(
    ref.watch(databaseProvider),
    ref.watch(inventoryRepositoryProvider),
  ),
);

final petsProvider = StreamProvider<List<Pet>>((ref) {
  final scope = ref.watch(activeScopeProvider);
  return ref.watch(petRepositoryProvider).watchPets(scope);
});

/// Korrigiert einmalig alte Aufgaben-Titel ohne Umlaute. In der AppShell
/// beobachtet, laeuft beim Start.
final petTaskTitleRepairProvider = Provider<void>((ref) {
  final userId = ref.watch(identityProvider).userId;
  Future.microtask(
    () => ref.read(petRepositoryProvider).fixLegacyTaskTitles(userId),
  );
});

final petProvider = StreamProvider.family<Pet?, String>((ref, id) {
  return ref.watch(petRepositoryProvider).watchPet(id);
});

/// Tagesaufgaben eines Tieres mit heutigem Stand.
final petTaskStatusProvider =
    StreamProvider.family<List<PetTaskStatus>, String>((ref, petId) {
      final today = DateTime.now();
      return ref
          .watch(petRepositoryProvider)
          .watchTaskStatus(petId, today);
    });

final petHealthProvider =
    StreamProvider.family<List<PetHealthEntry>, String>((ref, petId) {
      return ref.watch(petRepositoryProvider).watchHealthEntries(petId);
    });

final petWeightsProvider =
    StreamProvider.family<List<PetWeightEntry>, String>((ref, petId) {
      return ref.watch(petRepositoryProvider).watchWeights(petId);
    });
