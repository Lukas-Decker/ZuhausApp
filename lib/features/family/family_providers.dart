import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import '../../core/scope/app_scope.dart';
import '../../core/settings/app_settings.dart';
import '../auth/auth_providers.dart';
import '../meds/meds_providers.dart';
import '../pets/pets_providers.dart';
import 'family_event_service.dart';

/// Dienst fuer Familien-Ereignisse, sofern angemeldet.
final familyEventServiceProvider = Provider<FamilyEventService?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !ref.watch(authConfiguredProvider)) return null;
  return FamilyEventService(Supabase.instance.client);
});

/// Zeigt eingehende Familien-Ereignisse als lokale Benachrichtigung.
/// Muss beobachtet werden (AppShell).
final familyEventListenerProvider = Provider<void>((ref) {
  final service = ref.watch(familyEventServiceProvider);
  if (service == null) return;

  final shown = <String>{};
  final channel = service.subscribe((event) {
    final myId = ref.read(identityProvider).userId;
    // Eigene Ereignisse nicht sich selbst melden.
    if (event.createdBy == myId) return;
    if (!ref.read(appSettingsProvider).familyPushEnabled) return;
    if (!shown.add(event.id)) return;

    ref.read(notificationServiceProvider).show(
      id: notificationIdFromKey(event.id),
      title: event.title,
      body: event.body,
      channel: NotificationService.familyChannel,
      payload: 'family:${event.householdId}',
    );
  });

  ref.onDispose(channel.unsubscribe);
});

/// Prueft periodisch auf meldenswerte Situationen und legt Ereignisse an.
/// Muss beobachtet werden (AppShell).
final familyEventCheckerProvider = Provider<void>((ref) {
  final service = ref.watch(familyEventServiceProvider);
  if (service == null) return;

  final checker = _FamilyEventChecker(ref, service);
  final timer = Timer.periodic(
    const Duration(minutes: 10),
    (_) => checker.run(),
  );
  ref.onDispose(timer.cancel);
  Future.microtask(checker.run);
});

class _FamilyEventChecker {
  _FamilyEventChecker(this._ref, this._service);

  final Ref _ref;
  final FamilyEventService _service;

  /// Nach so vielen Minuten Verzug gilt eine Einnahme als verpasst.
  static const _medGraceMinutes = 30;

  /// Ab dieser Uhrzeit gilt eine offene Fuetterung als ueberfaellig.
  static const _petOverdueHour = 19;

  bool _running = false;

  Future<void> run() async {
    if (_running) return;
    _running = true;
    try {
      final settings = _ref.read(appSettingsProvider);
      final households = _ref.read(householdsProvider).value ?? const [];
      final now = DateTime.now();

      for (final entry in households) {
        final scope = AppScope.household(
          entry.household.id,
          entry.household.name,
        );
        if (settings.medEscalationEnabled) {
          await _checkMeds(scope, entry.household.id, now);
        }
        if (settings.petOverdueEnabled) {
          await _checkPets(scope, entry.household.id, now);
        }
      }
    } catch (_) {
      // Netzwerk o.ae.: beim naechsten Lauf erneut.
    } finally {
      _running = false;
    }
  }

  Future<void> _checkMeds(AppScope scope, String householdId, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final statuses =
        await _ref.read(medicationRepositoryProvider).watchDay(scope, today).first;

    for (final status in statuses) {
      if (status.isHandled) continue;
      final plan = status.occurrence.plan;
      // Nur Plaene mit Betreuer oder Haushaltsfreigabe eskalieren.
      final hasCaregiver = plan.caregiverUserId != null;
      if (!hasCaregiver && !plan.sharedWithHousehold) continue;

      final due = status.occurrence.scheduledFor;
      if (now.difference(due).inMinutes < _medGraceMinutes) continue;

      final time = DateFormat('HH:mm', 'de').format(due);
      await _service.postEvent(
        householdId: householdId,
        kind: 'med_escalation',
        title: 'Einnahme nicht bestätigt',
        body: '${plan.name} um $time Uhr wurde nicht bestätigt.',
        targetUserId: plan.caregiverUserId,
        dedupKey: 'med-miss:${plan.id}@${due.toIso8601String()}',
      );
    }
  }

  Future<void> _checkPets(AppScope scope, String householdId, DateTime now) async {
    if (now.hour < _petOverdueHour) return;
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(today);

    final pets = await _ref.read(petRepositoryProvider).watchPets(scope).first;
    for (final pet in pets) {
      final statuses = await _ref
          .read(petRepositoryProvider)
          .watchTaskStatus(pet.id, today)
          .first;
      for (final status in statuses) {
        // Nur Fuetterungen melden, um Spam zu vermeiden.
        if (!status.task.consumesFood || status.isComplete) continue;
        await _service.postEvent(
          householdId: householdId,
          kind: 'pet_overdue',
          title: '${pet.name}: Fütterung offen',
          body: '${status.task.title} wurde heute noch nicht erledigt.',
          dedupKey: 'pet-overdue:${status.task.id}:$dateStr',
        );
      }
    }
  }
}
