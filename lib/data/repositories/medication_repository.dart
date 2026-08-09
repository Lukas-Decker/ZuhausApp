import 'package:drift/drift.dart';

import '../../core/scope/app_scope.dart';
import '../../features/meds/domain/dose_schedule.dart';
import '../db/app_database.dart';
import '../db/tables/common.dart';

/// Eine Fälligkeit zusammen mit ihrem eventuell schon vorhandenen Log-Eintrag.
class DoseStatus {
  const DoseStatus({required this.occurrence, this.log});

  final DoseOccurrence occurrence;
  final MedicationLog? log;

  bool get isHandled => log != null;
}

class MedicationRepository {
  MedicationRepository(this._db);

  final AppDatabase _db;

  // --- Pläne ---------------------------------------------------------------

  Stream<List<MedicationPlan>> watchPlans(AppScope scope) {
    return (_db.select(_db.medicationPlans)
          ..where((p) => p.scopeKind.equals(scope.kind.name))
          ..where((p) => p.scopeId.equals(scope.id))
          ..where((p) => p.deletedAt.isNull())
          ..orderBy([
            (p) => OrderingTerm.desc(p.isActive),
            (p) => OrderingTerm.asc(p.name),
          ]))
        .watch();
  }

  /// Alle aktiven Pläne kontextübergreifend. Basis für das Planen der
  /// Erinnerungen, die geräteweit gelten.
  Future<List<MedicationPlan>> allActivePlans() {
    return (_db.select(_db.medicationPlans)
          ..where((p) => p.deletedAt.isNull())
          ..where((p) => p.isActive.equals(true))
          ..where((p) => p.remindersEnabled.equals(true)))
        .get();
  }

  Future<MedicationPlan?> getPlan(String id) {
    return (_db.select(_db.medicationPlans)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> upsertPlan({
    String? id,
    required AppScope scope,
    required String userId,
    required String name,
    required String dosage,
    required String form,
    required String scheduleType,
    required String times,
    required String weekdays,
    required int intervalHours,
    /// Menge je Tageszeit beim Schema-Modus, sonst leer.
    String doses = '',
    /// Einnahmehinweise als CSV von Schluesseln.
    String intakeHints = '',
    DateTime? startDate,
    DateTime? endDate,
    double? stockCount,
    double? stockThreshold,
    double dosePerIntake = 1,
    String? note,
    bool remindersEnabled = true,
    bool sharedWithHousehold = false,
    String? caregiverUserId,
    bool isActive = true,
  }) async {
    final planId = id ?? uuid.v4();
    final companion = MedicationPlansCompanion(
      id: Value(planId),
      scopeKind: Value(scope.kind.name),
      scopeId: Value(scope.id),
      name: Value(name),
      dosage: Value(dosage),
      form: Value(form),
      scheduleType: Value(scheduleType),
      times: Value(times),
      doses: Value(doses),
      intakeHints: Value(intakeHints),
      weekdays: Value(weekdays),
      intervalHours: Value(intervalHours),
      startDate: Value(startDate),
      endDate: Value(endDate),
      stockCount: Value(stockCount),
      stockThreshold: Value(stockThreshold),
      dosePerIntake: Value(dosePerIntake),
      note: Value(note),
      remindersEnabled: Value(remindersEnabled),
      sharedWithHousehold: Value(sharedWithHousehold),
      caregiverUserId: Value(caregiverUserId),
      isActive: Value(isActive),
      updatedAt: Value(DateTime.now()),
      updatedBy: Value(userId),
      isDirty: const Value(true),
    );

    await _db.transaction(() async {
      if (id == null) {
        // Anlegen: der Vorrat steckt in der Zeile selbst (kein Delta noetig).
        await _db.into(_db.medicationPlans).insert(
          companion.copyWith(createdBy: Value(userId)),
        );
      } else {
        // Beim Aendern den Vorrat als additives Delta (neu - alt) verbuchen.
        if (stockCount != null) {
          final current = await (_db.select(_db.medicationPlans)
                ..where((p) => p.id.equals(id)))
              .getSingleOrNull();
          final old = current?.stockCount;
          if (old != null && old != stockCount) {
            await _db.logCounterDelta(
              table: 'medication_plans',
              rowId: id,
              field: 'stock_count',
              delta: stockCount - old,
            );
          }
        }
        await (_db.update(_db.medicationPlans)..where((p) => p.id.equals(id)))
            .write(companion);
      }
    });
    return planId;
  }

  Future<void> setActive(String id, bool active, String userId) async {
    await (_db.update(_db.medicationPlans)..where((p) => p.id.equals(id))).write(
      MedicationPlansCompanion(
        isActive: Value(active),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> setRemindersEnabled(
    String id,
    bool enabled,
    String userId,
  ) async {
    await (_db.update(_db.medicationPlans)..where((p) => p.id.equals(id))).write(
      MedicationPlansCompanion(
        remindersEnabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
        updatedBy: Value(userId),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> deletePlan(String id, String userId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.medicationPlans)..where((p) => p.id.equals(id)))
          .write(
        MedicationPlansCompanion(
          deletedAt: Value(now),
          isActive: const Value(false),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(_db.medicationLogs)..where((l) => l.planId.equals(id)))
          .write(
        MedicationLogsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedBy: Value(userId),
          isDirty: const Value(true),
        ),
      );
    });
  }

  // --- Einnahme-Log --------------------------------------------------------

  Stream<List<MedicationLog>> watchLogsForDay(AppScope scope, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.medicationLogs)
          ..where((l) => l.scopeKind.equals(scope.kind.name))
          ..where((l) => l.scopeId.equals(scope.id))
          ..where((l) => l.deletedAt.isNull())
          ..where((l) => l.scheduledFor.isBiggerOrEqualValue(start))
          ..where((l) => l.scheduledFor.isSmallerThanValue(end)))
        .watch();
  }

  Stream<List<MedicationLog>> watchRecentLogs(AppScope scope, {int limit = 60}) {
    return (_db.select(_db.medicationLogs)
          ..where((l) => l.scopeKind.equals(scope.kind.name))
          ..where((l) => l.scopeId.equals(scope.id))
          ..where((l) => l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.desc(l.scheduledFor)])
          ..limit(limit))
        .watch();
  }

  /// Setzt oder ändert den Status einer geplanten Einnahme.
  ///
  /// Passt zusätzlich den Vorrat additiv an: wird "genommen" gesetzt, sinkt der
  /// Vorrat um die Dosis; eine Rücknahme (von genommen auf etwas anderes) bucht
  /// zurück. Additiv, damit gleichzeitige Änderungen später sauber mergen.
  Future<void> recordIntake({
    required AppScope scope,
    required String userId,
    required MedicationPlan plan,
    required DateTime scheduledFor,
    required String status,
  }) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.medicationLogs)
            ..where((l) => l.planId.equals(plan.id))
            ..where((l) => l.scheduledFor.equals(scheduledFor))
            ..where((l) => l.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();

      final wasTaken = existing?.status == 'taken';
      final willBeTaken = status == 'taken';

      if (existing == null) {
        await _db.into(_db.medicationLogs).insert(
          MedicationLogsCompanion.insert(
            scopeKind: scope.kind.name,
            scopeId: scope.id,
            planId: plan.id,
            scheduledFor: scheduledFor,
            status: Value(status),
            actedAt: Value(DateTime.now()),
            dose: Value(plan.dosePerIntake),
            createdBy: Value(userId),
            updatedBy: Value(userId),
          ),
        );
      } else {
        await (_db.update(_db.medicationLogs)
              ..where((l) => l.id.equals(existing.id)))
            .write(
          MedicationLogsCompanion(
            status: Value(status),
            actedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            updatedBy: Value(userId),
            isDirty: const Value(true),
          ),
        );
      }

      if (plan.stockCount != null && wasTaken != willBeTaken) {
        final delta = willBeTaken ? -plan.dosePerIntake : plan.dosePerIntake;
        final next = (plan.stockCount! + delta).clamp(0.0, double.maxFinite);
        final applied = next - plan.stockCount!;
        await (_db.update(_db.medicationPlans)..where((p) => p.id.equals(plan.id)))
            .write(
          MedicationPlansCompanion(
            stockCount: Value(next),
            updatedAt: Value(DateTime.now()),
            updatedBy: Value(userId),
            isDirty: const Value(true),
          ),
        );
        await _db.logCounterDelta(
          table: 'medication_plans',
          rowId: plan.id,
          field: 'stock_count',
          delta: applied,
        );
      }
    });
  }

  /// Kombiniert die berechneten Fälligkeiten eines Tages mit vorhandenen Logs.
  Stream<List<DoseStatus>> watchDay(AppScope scope, DateTime day) {
    return watchPlans(scope).asyncMap((plans) async {
      final logs = await watchLogsForDay(scope, day).first;
      final byPlanAndTime = {
        for (final log in logs) '${log.planId}@${log.scheduledFor.toIso8601String()}': log,
      };

      final result = <DoseStatus>[];
      for (final plan in plans) {
        for (final occ in DoseSchedule.forDay(plan, day)) {
          result.add(
            DoseStatus(
              occurrence: occ,
              log: byPlanAndTime[occ.slotKey],
            ),
          );
        }
      }
      result.sort(
        (a, b) => a.occurrence.scheduledFor.compareTo(b.occurrence.scheduledFor),
      );
      return result;
    });
  }
}
