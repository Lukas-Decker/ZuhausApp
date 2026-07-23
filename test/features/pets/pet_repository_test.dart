import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/inventory_repository.dart';
import 'package:multiapp/data/repositories/pet_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late PetRepository repository;
  late InventoryRepository inventory;

  setUp(() {
    db = createTestDatabase();
    inventory = InventoryRepository(db);
    repository = PetRepository(db, inventory);
  });

  tearDown(() => db.close());

  Future<String> seedPet() => repository.upsertPet(
    scope: personalScope,
    userId: testUserId,
    name: 'Rex',
    species: 'dog',
  );

  test('Tier anlegen und im Kontext finden', () async {
    await seedPet();
    final pets = await repository.watchPets(personalScope).first;
    expect(pets, hasLength(1));
    expect(pets.single.name, 'Rex');
    expect(await repository.watchPets(householdScope).first, isEmpty);
  });

  test('Standardaufgaben werden angelegt', () async {
    final petId = await seedPet();
    await repository.seedDefaultTasks(
      scope: personalScope,
      petId: petId,
      userId: testUserId,
      tasks: const [
        (title: 'Fuettern', iconKey: 'food', timesPerDay: 2, food: true),
        (title: 'Gassi', iconKey: 'walk', timesPerDay: 3, food: false),
      ],
    );
    final tasks = await repository.watchTasks(petId).first;
    expect(tasks, hasLength(2));
    expect(tasks.first.title, 'Fuettern');
  });

  group('Tagesaufgaben', () {
    late String petId;
    late String taskId;

    setUp(() async {
      petId = await seedPet();
      taskId = await repository.upsertTask(
        scope: personalScope,
        petId: petId,
        userId: testUserId,
        title: 'Fuettern',
        iconKey: 'food',
        timesPerDay: 2,
        consumesFood: false,
      );
    });

    test('Erledigung zählt hoch und Status stimmt', () async {
      final task = (await repository.watchTasks(petId).first).single;
      final today = DateTime.now();

      var statuses = await repository.watchTaskStatus(petId, today).first;
      expect(statuses.single.doneToday, 0);
      expect(statuses.single.isComplete, isFalse);

      await repository.markTaskDone(
        scope: personalScope,
        task: task,
        userId: testUserId,
        doneByName: 'Lukas',
      );
      statuses = await repository.watchTaskStatus(petId, today).first;
      expect(statuses.single.doneToday, 1);
      expect(statuses.single.remaining, 1);
      expect(statuses.single.lastDoneBy, 'Lukas');
      expect(statuses.single.isComplete, isFalse);

      await repository.markTaskDone(
        scope: personalScope,
        task: task,
        userId: testUserId,
        doneByName: 'Anna',
      );
      statuses = await repository.watchTaskStatus(petId, today).first;
      expect(statuses.single.doneToday, 2);
      expect(statuses.single.isComplete, isTrue);
    });

    test('Zurücknehmen entfernt die letzte Erledigung', () async {
      final task = (await repository.watchTasks(petId).first).single;
      final today = DateTime.now();
      await repository.markTaskDone(
        scope: personalScope,
        task: task,
        userId: testUserId,
        doneByName: 'Lukas',
      );
      await repository.undoTaskDone(task: task, userId: testUserId);

      final statuses = await repository.watchTaskStatus(petId, today).first;
      expect(statuses.single.doneToday, 0);
    });

    test('taskId wird verwendet', () {
      expect(taskId, isNotEmpty);
    });
  });

  group('Futtervorrat-Kopplung', () {
    test('Füttern zieht die Portion vom Vorrat ab, Zurücknehmen bucht zurück',
        () async {
      final foodId = await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Hundefutter',
        quantity: 10,
        unit: 'kilogram',
      );
      final petId = await repository.upsertPet(
        scope: personalScope,
        userId: testUserId,
        name: 'Rex',
        species: 'dog',
        foodInventoryItemId: Value(foodId),
        foodPortion: const Value(0.5),
      );
      final task = await repository.upsertTask(
        scope: personalScope,
        petId: petId,
        userId: testUserId,
        title: 'Fuettern',
        iconKey: 'food',
        timesPerDay: 2,
        consumesFood: true,
      );
      final taskObj = (await repository.watchTasks(petId).first)
          .firstWhere((t) => t.id == task);

      await repository.markTaskDone(
        scope: personalScope,
        task: taskObj,
        userId: testUserId,
        doneByName: 'Lukas',
      );
      expect((await inventory.findById(foodId))!.quantity, 9.5);

      await repository.undoTaskDone(task: taskObj, userId: testUserId);
      expect((await inventory.findById(foodId))!.quantity, 10);
    });

    test('ohne Portion bleibt der Vorrat unangetastet', () async {
      final foodId = await inventory.addItem(
        scope: personalScope,
        userId: testUserId,
        name: 'Hundefutter',
        quantity: 10,
        unit: 'kilogram',
      );
      final petId = await repository.upsertPet(
        scope: personalScope,
        userId: testUserId,
        name: 'Rex',
        species: 'dog',
        foodInventoryItemId: Value(foodId),
      );
      final task = await repository.upsertTask(
        scope: personalScope,
        petId: petId,
        userId: testUserId,
        title: 'Fuettern',
        iconKey: 'food',
        timesPerDay: 1,
        consumesFood: true,
      );
      final taskObj = (await repository.watchTasks(petId).first).single;
      expect(taskObj.id, task);

      await repository.markTaskDone(
        scope: personalScope,
        task: taskObj,
        userId: testUserId,
        doneByName: 'Lukas',
      );
      expect((await inventory.findById(foodId))!.quantity, 10);
    });
  });

  group('Gesundheit', () {
    test('Eintrag anlegen, als erledigt markieren, offene Liste', () async {
      final petId = await seedPet();
      final id = await repository.upsertHealthEntry(
        scope: personalScope,
        petId: petId,
        userId: testUserId,
        kind: 'vaccination',
        title: 'Tollwut',
        dueAt: DateTime(2026, 8, 1),
      );

      expect(await repository.upcomingHealthEntries(personalScope), hasLength(1));

      await repository.setHealthDone(id, true, testUserId);
      final entries = await repository.watchHealthEntries(petId).first;
      expect(entries.single.isDone, isTrue);
      expect(await repository.upcomingHealthEntries(personalScope), isEmpty);
    });
  });

  group('Gewicht', () {
    test('Messungen werden chronologisch geführt', () async {
      final petId = await seedPet();
      await repository.addWeight(
        scope: personalScope,
        petId: petId,
        userId: testUserId,
        weightKg: 12.5,
        measuredAt: DateTime(2026, 1, 1),
      );
      await repository.addWeight(
        scope: personalScope,
        petId: petId,
        userId: testUserId,
        weightKg: 13.0,
        measuredAt: DateTime(2026, 2, 1),
      );
      final weights = await repository.watchWeights(petId).first;
      expect(weights.map((w) => w.weightKg), [12.5, 13.0]);
    });
  });
}
