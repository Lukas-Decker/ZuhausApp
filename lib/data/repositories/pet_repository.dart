import 'package:drift/drift.dart';

import '../../core/scope/app_scope.dart';
import '../db/app_database.dart';
import '../db/tables/common.dart';
import 'inventory_repository.dart';

/// Eine Tagesaufgabe zusammen mit dem heutigen Erledigungsstand.
class PetTaskStatus {
  const PetTaskStatus({required this.task, required this.doneToday, this.logs = const []});

  final PetTask task;
  final int doneToday;
  final List<PetTaskLog> logs;

  bool get isComplete => doneToday >= task.timesPerDay;
  int get remaining => (task.timesPerDay - doneToday).clamp(0, task.timesPerDay);

  /// Wer die letzte Erledigung eingetragen hat.
  String? get lastDoneBy => logs.isEmpty ? null : logs.last.doneByName;
  DateTime? get lastDoneAt => logs.isEmpty ? null : logs.last.doneAt;
}

class PetRepository {
  PetRepository(this._db, this._inventory);

  final AppDatabase _db;
  final InventoryRepository _inventory;

  // --- Tiere ---------------------------------------------------------------

  Stream<List<Pet>> watchPets(AppScope scope) {
    return (_db.select(_db.pets)
          ..where((p) => p.scopeKind.equals(scope.kind.name))
          ..where((p) => p.scopeId.equals(scope.id))
          ..where((p) => p.deletedAt.isNull())
          ..where((p) => p.isArchived.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Stream<Pet?> watchPet(String id) {
    return (_db.select(_db.pets)..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<Pet?> getPet(String id) {
    return (_db.select(_db.pets)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> upsertPet({
    String? id,
    required AppScope scope,
    required String userId,
    required String name,
    required String species,
    String? breed,
    DateTime? birthday,
    String? photoPath,
    Value<String?> foodInventoryItemId = const Value.absent(),
    Value<double?> foodPortion = const Value.absent(),
    String? note,
  }) async {
    final petId = id ?? uuid.v4();
    final companion = PetsCompanion(
      id: Value(petId),
      scopeKind: Value(scope.kind.name),
      scopeId: Value(scope.id),
      name: Value(name),
      species: Value(species),
      breed: Value(breed),
      birthday: Value(birthday),
      photoPath: Value(photoPath),
      foodInventoryItemId: foodInventoryItemId,
      foodPortion: foodPortion,
      note: Value(note),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
      isDirty: const Value(true),
    );

    if (id == null) {
      await _db.into(_db.pets).insert(companion.copyWith(createdBy: Value(userId)));
    } else {
      await (_db.update(_db.pets)..where((p) => p.id.equals(id))).write(companion);
    }
    return petId;
  }

  Future<void> deletePet(String id, String userId) async {
    final now = DateTime.now();
    await (_db.update(_db.pets)..where((p) => p.id.equals(id))).write(
      PetsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  /// Legt die fuer die Tierart typischen Aufgaben an.
  Future<void> seedDefaultTasks({
    required AppScope scope,
    required String petId,
    required String userId,
    required List<({String title, String iconKey, int timesPerDay, bool food})> tasks,
  }) async {
    await _db.batch((batch) {
      for (var i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        batch.insert(
          _db.petTasks,
          PetTasksCompanion.insert(
            scopeKind: scope.kind.name,
            scopeId: scope.id,
            petId: petId,
            title: t.title,
            iconKey: Value(t.iconKey),
            timesPerDay: Value(t.timesPerDay),
            consumesFood: Value(t.food),
            sortOrder: Value(i),
            createdBy: Value(userId),
            updatedBy: Value(userId),
          ),
        );
      }
    });
  }

  // --- Aufgaben ------------------------------------------------------------

  Stream<List<PetTask>> watchTasks(String petId) {
    return (_db.select(_db.petTasks)
          ..where((t) => t.petId.equals(petId))
          ..where((t) => t.deletedAt.isNull())
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<String> upsertTask({
    String? id,
    required AppScope scope,
    required String petId,
    required String userId,
    required String title,
    required String iconKey,
    required int timesPerDay,
    required bool consumesFood,
  }) async {
    final taskId = id ?? uuid.v4();
    final companion = PetTasksCompanion(
      id: Value(taskId),
      scopeKind: Value(scope.kind.name),
      scopeId: Value(scope.id),
      petId: Value(petId),
      title: Value(title),
      iconKey: Value(iconKey),
      timesPerDay: Value(timesPerDay),
      consumesFood: Value(consumesFood),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
      isDirty: const Value(true),
    );
    if (id == null) {
      await _db.into(_db.petTasks).insert(companion.copyWith(createdBy: Value(userId)));
    } else {
      await (_db.update(_db.petTasks)..where((t) => t.id.equals(id))).write(companion);
    }
    return taskId;
  }

  Future<void> deleteTask(String id, String userId) async {
    await (_db.update(_db.petTasks)..where((t) => t.id.equals(id))).write(
      PetTasksCompanion(
        deletedAt: Value(DateTime.now()),
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  /// Aufgaben eines Tieres mit dem heutigen Erledigungsstand.
  Stream<List<PetTaskStatus>> watchTaskStatus(String petId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return watchTasks(petId).asyncMap((tasks) async {
      final logs = await (_db.select(_db.petTaskLogs)
            ..where((l) => l.petId.equals(petId))
            ..where((l) => l.deletedAt.isNull())
            ..where((l) => l.doneAt.isBiggerOrEqualValue(start))
            ..where((l) => l.doneAt.isSmallerThanValue(end))
            ..orderBy([(l) => OrderingTerm.asc(l.doneAt)]))
          .get();

      return tasks.map((task) {
        final taskLogs = logs.where((l) => l.taskId == task.id).toList();
        return PetTaskStatus(
          task: task,
          doneToday: taskLogs.length,
          logs: taskLogs,
        );
      }).toList();
    });
  }

  /// Traegt eine Erledigung ein und zieht bei Bedarf den Futtervorrat ab.
  Future<void> markTaskDone({
    required AppScope scope,
    required PetTask task,
    required String userId,
    required String doneByName,
    DateTime? day,
  }) async {
    final now = DateTime.now();
    final theDay = day ?? DateTime(now.year, now.month, now.day);

    await _db.into(_db.petTaskLogs).insert(
      PetTaskLogsCompanion.insert(
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        taskId: task.id,
        petId: task.petId,
        day: DateTime(theDay.year, theDay.month, theDay.day),
        doneAt: Value(now),
        doneByName: Value(doneByName),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );

    if (task.consumesFood) {
      final pet = await getPet(task.petId);
      final itemId = pet?.foodInventoryItemId;
      final portion = pet?.foodPortion;
      if (itemId != null && portion != null && portion > 0) {
        await _inventory.adjustQuantity(
          id: itemId,
          userId: userId,
          delta: -portion,
        );
      }
    }
  }

  /// Nimmt die letzte Erledigung einer Aufgabe am Tag zurueck.
  Future<void> undoTaskDone({
    required PetTask task,
    required String userId,
    DateTime? day,
  }) async {
    final now = DateTime.now();
    final theDay = day ?? DateTime(now.year, now.month, now.day);
    final start = DateTime(theDay.year, theDay.month, theDay.day);
    final end = start.add(const Duration(days: 1));

    final last = await (_db.select(_db.petTaskLogs)
          ..where((l) => l.taskId.equals(task.id))
          ..where((l) => l.deletedAt.isNull())
          ..where((l) => l.doneAt.isBiggerOrEqualValue(start))
          ..where((l) => l.doneAt.isSmallerThanValue(end))
          ..orderBy([(l) => OrderingTerm.desc(l.doneAt)])
          ..limit(1))
        .getSingleOrNull();
    if (last == null) return;

    await (_db.delete(_db.petTaskLogs)..where((l) => l.id.equals(last.id))).go();

    if (task.consumesFood) {
      final pet = await getPet(task.petId);
      final itemId = pet?.foodInventoryItemId;
      final portion = pet?.foodPortion;
      if (itemId != null && portion != null && portion > 0) {
        await _inventory.adjustQuantity(
          id: itemId,
          userId: userId,
          delta: portion,
        );
      }
    }
  }

  // --- Gesundheit ----------------------------------------------------------

  Stream<List<PetHealthEntry>> watchHealthEntries(String petId) {
    return (_db.select(_db.petHealthEntries)
          ..where((e) => e.petId.equals(petId))
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([
            (e) => OrderingTerm.asc(e.isDone),
            (e) => OrderingTerm.asc(e.dueAt),
          ]))
        .watch();
  }

  /// Alle offenen, terminierten Gesundheitsereignisse eines Kontexts,
  /// Grundlage fuer Vorlauf-Erinnerungen.
  Future<List<PetHealthEntry>> upcomingHealthEntries(AppScope scope) {
    return (_db.select(_db.petHealthEntries)
          ..where((e) => e.scopeKind.equals(scope.kind.name))
          ..where((e) => e.scopeId.equals(scope.id))
          ..where((e) => e.deletedAt.isNull())
          ..where((e) => e.isDone.equals(false))
          ..where((e) => e.remindersEnabled.equals(true)))
        .get();
  }

  Future<String> upsertHealthEntry({
    String? id,
    required AppScope scope,
    required String petId,
    required String userId,
    required String kind,
    required String title,
    String? note,
    required DateTime dueAt,
    DateTime? nextDueAt,
    int reminderLeadDays = 2,
    bool remindersEnabled = true,
  }) async {
    final entryId = id ?? uuid.v4();
    final companion = PetHealthEntriesCompanion(
      id: Value(entryId),
      scopeKind: Value(scope.kind.name),
      scopeId: Value(scope.id),
      petId: Value(petId),
      kind: Value(kind),
      title: Value(title),
      note: Value(note),
      dueAt: Value(dueAt),
      nextDueAt: Value(nextDueAt),
      reminderLeadDays: Value(reminderLeadDays),
      remindersEnabled: Value(remindersEnabled),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
      isDirty: const Value(true),
    );
    if (id == null) {
      await _db.into(_db.petHealthEntries).insert(
        companion.copyWith(createdBy: Value(userId)),
      );
    } else {
      await (_db.update(_db.petHealthEntries)..where((e) => e.id.equals(id)))
          .write(companion);
    }
    return entryId;
  }

  Future<void> setHealthDone(String id, bool done, String userId) async {
    await (_db.update(_db.petHealthEntries)..where((e) => e.id.equals(id))).write(
      PetHealthEntriesCompanion(
        isDone: Value(done),
        doneAt: Value(done ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> deleteHealthEntry(String id, String userId) async {
    await (_db.update(_db.petHealthEntries)..where((e) => e.id.equals(id))).write(
      PetHealthEntriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  // --- Gewicht -------------------------------------------------------------

  Stream<List<PetWeightEntry>> watchWeights(String petId) {
    return (_db.select(_db.petWeightEntries)
          ..where((w) => w.petId.equals(petId))
          ..where((w) => w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.measuredAt)]))
        .watch();
  }

  Future<void> addWeight({
    required AppScope scope,
    required String petId,
    required String userId,
    required double weightKg,
    DateTime? measuredAt,
    String? note,
  }) async {
    await _db.into(_db.petWeightEntries).insert(
      PetWeightEntriesCompanion.insert(
        scopeKind: scope.kind.name,
        scopeId: scope.id,
        petId: petId,
        measuredAt: measuredAt ?? DateTime.now(),
        weightKg: weightKg,
        note: Value(note),
        createdBy: Value(userId),
        updatedBy: Value(userId),
      ),
    );
  }

  Future<void> deleteWeight(String id) async {
    await (_db.delete(_db.petWeightEntries)..where((w) => w.id.equals(id))).go();
  }
}
