import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/data/db/app_database.dart';
import 'package:multiapp/data/repositories/medication_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late MedicationRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = MedicationRepository(db);
  });

  tearDown(() => db.close());

  Future<String> seedPlan({
    double? stock,
    double dosePerIntake = 1,
    bool reminders = true,
    bool active = true,
  }) {
    return repository.upsertPlan(
      scope: personalScope,
      userId: testUserId,
      name: 'Ibuprofen',
      dosage: '1 Tablette',
      form: 'tablet',
      scheduleType: 'daily',
      times: '08:00,20:00',
      weekdays: '',
      intervalHours: 8,
      stockCount: stock,
      dosePerIntake: dosePerIntake,
      remindersEnabled: reminders,
      isActive: active,
    );
  }

  test('Plan anlegen und wiederfinden', () async {
    final id = await seedPlan();
    final plan = await repository.getPlan(id);
    expect(plan, isNotNull);
    expect(plan!.name, 'Ibuprofen');
  });

  test('Kontexte sind getrennt', () async {
    await seedPlan();
    expect(await repository.watchPlans(personalScope).first, hasLength(1));
    expect(await repository.watchPlans(householdScope).first, isEmpty);
  });

  group('recordIntake und Vorrat', () {
    test('genommen zieht additiv vom Vorrat ab', () async {
      final id = await seedPlan(stock: 10, dosePerIntake: 2);
      final plan = await repository.getPlan(id);
      final when = DateTime(2026, 7, 22, 8);

      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: plan!,
        scheduledFor: when,
        status: 'taken',
      );

      expect((await repository.getPlan(id))!.stockCount, 8);
    });

    test('Statuswechsel von genommen bucht den Vorrat zurück', () async {
      final id = await seedPlan(stock: 10);
      final plan = await repository.getPlan(id);
      final when = DateTime(2026, 7, 22, 8);

      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: plan!,
        scheduledFor: when,
        status: 'taken',
      );
      // Frischen Plan mit reduziertem Vorrat holen, dann auf ausgelassen.
      final afterTake = await repository.getPlan(id);
      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: afterTake!,
        scheduledFor: when,
        status: 'skipped',
      );

      expect((await repository.getPlan(id))!.stockCount, 10);
    });

    test('mehrfaches Genommen zieht nicht doppelt ab', () async {
      final id = await seedPlan(stock: 10);
      final plan = await repository.getPlan(id);
      final when = DateTime(2026, 7, 22, 8);

      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: plan!,
        scheduledFor: when,
        status: 'taken',
      );
      final again = await repository.getPlan(id);
      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: again!,
        scheduledFor: when,
        status: 'taken',
      );

      expect((await repository.getPlan(id))!.stockCount, 9);
    });

    test('Vorrat ohne Bestand bleibt null', () async {
      final id = await seedPlan();
      final plan = await repository.getPlan(id);
      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: plan!,
        scheduledFor: DateTime(2026, 7, 22, 8),
        status: 'taken',
      );
      expect((await repository.getPlan(id))!.stockCount, isNull);
    });
  });

  group('watchDay', () {
    test('verknüpft Fälligkeiten mit dem Log-Status', () async {
      final id = await seedPlan();
      final plan = await repository.getPlan(id);
      final day = DateTime(2026, 7, 22);

      await repository.recordIntake(
        scope: personalScope,
        userId: testUserId,
        plan: plan!,
        scheduledFor: DateTime(2026, 7, 22, 8),
        status: 'taken',
      );

      final statuses = await repository.watchDay(personalScope, day).first;
      expect(statuses, hasLength(2)); // 08:00 und 20:00
      final morning = statuses.firstWhere(
        (s) => s.occurrence.scheduledFor.hour == 8,
      );
      final evening = statuses.firstWhere(
        (s) => s.occurrence.scheduledFor.hour == 20,
      );
      expect(morning.isHandled, isTrue);
      expect(morning.log!.status, 'taken');
      expect(evening.isHandled, isFalse);
    });
  });

  group('allActivePlans', () {
    test('liefert nur aktive Pläne mit Erinnerung', () async {
      await seedPlan();
      await seedPlan(reminders: false);
      await seedPlan(active: false);
      final plans = await repository.allActivePlans();
      expect(plans, hasLength(1));
    });
  });

  test('deletePlan ist ein Soft-Delete', () async {
    final id = await seedPlan();
    await repository.deletePlan(id, testUserId);
    expect(await repository.watchPlans(personalScope).first, isEmpty);
    final plan = await repository.getPlan(id);
    expect(plan!.deletedAt, isNotNull);
  });
}
