import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/household/household_role.dart';
import '../../core/providers.dart';
import '../../core/scope/app_scope.dart';
import 'data/household_remote_service.dart';
import 'household_providers.dart';

/// Buendelt die Haushalts-Mutationen und fuellt den Anzeigenamen automatisch.
class HouseholdActions {
  HouseholdActions(this._ref);

  final Ref _ref;

  HouseholdRemoteService get _service {
    final service = _ref.read(householdRemoteServiceProvider);
    if (service == null) {
      throw const HouseholdException('Bitte zuerst anmelden.');
    }
    return service;
  }

  String get _displayName => _ref.read(identityProvider).displayName;

  Future<String> create(String name) =>
      _service.createHousehold(name, _displayName);

  Future<void> rename(String householdId, String name) =>
      _service.renameHousehold(householdId, name);

  Future<String> join(String code) =>
      _service.joinWithCode(code, _displayName);

  Future<String> createInvite({
    required String householdId,
    required HouseholdRole role,
    DateTime? expiresAt,
    int? maxUses,
  }) => _service.createInvite(
    householdId: householdId,
    role: role,
    expiresAt: expiresAt,
    maxUses: maxUses,
  );

  Future<void> revokeInvite(String inviteId) =>
      _service.revokeInvite(inviteId);

  Future<void> setRole(String householdId, String userId, HouseholdRole role) =>
      _service.setMemberRole(householdId, userId, role);

  Future<void> removeMember(String householdId, String userId) =>
      _service.removeMember(householdId, userId);

  Future<void> leave(String householdId) =>
      _service.leaveHousehold(householdId);

  Future<void> transferOwnership(String householdId, String newOwnerId) =>
      _service.transferOwnership(householdId, newOwnerId);

  Future<void> delete(String householdId) =>
      _service.deleteHousehold(householdId);
}

final householdActionsProvider = Provider<HouseholdActions>(
  (ref) => HouseholdActions(ref),
);

/// Fuehrt eine wertliefernde Haushalts-Aktion aus und zeigt Fehler als SnackBar.
///
/// Gibt das Ergebnis zurueck oder `null`, wenn ein Fehler auftrat.
Future<T?> runHouseholdAction<T extends Object>(
  BuildContext context,
  WidgetRef ref,
  Future<T> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    return await action();
  } on HouseholdException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('Fehler: $error')));
    return null;
  }
}

/// Fuehrt eine Aktion ohne Rueckgabewert aus. Gibt `true` bei Erfolg zurueck.
Future<bool> runHouseholdVoidAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } on HouseholdException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('Fehler: $error')));
    return false;
  }
}

/// Dialog zum Beitreten per Code. Bei Erfolg wird in den Haushalt gewechselt.
Future<void> showJoinHouseholdDialog(
  BuildContext context,
  WidgetRef ref, {
  String? initialCode,
}) async {
  final controller = TextEditingController(text: initialCode ?? '');
  final code = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Haushalt beitreten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Einladungscode',
              hintText: 'z.B. ABCD-2345',
            ),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          const SizedBox(height: 8),
          Text(
            'Den Code bekommst du von einem Mitglied des Haushalts.',
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: const Text('Beitreten'),
        ),
      ],
    ),
  );
  controller.dispose();

  final trimmed = code?.trim() ?? '';
  if (trimmed.isEmpty || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final householdId = await runHouseholdAction(
    context,
    ref,
    () => ref.read(householdActionsProvider).join(trimmed),
  );
  if (householdId == null) return;

  // Namen kennen wir hier noch nicht sicher; der Mirror liefert ihn gleich.
  await ref
      .read(activeScopeProvider.notifier)
      .select(AppScope.household(householdId, 'Haushalt'));
  messenger.showSnackBar(const SnackBar(content: Text('Haushalt beigetreten')));
}
