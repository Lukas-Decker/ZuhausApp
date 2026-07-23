import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/household/household_role.dart';
import '../../../core/providers.dart';
import '../../../core/scope/app_scope.dart';
import '../../../data/db/app_database.dart';
import '../domain/household_models.dart';
import '../household_actions.dart';
import '../household_providers.dart';
import 'invite_editor.dart';

/// Verwaltung eines Haushalts: Mitglieder, Rollen, Einladungen.
class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key, required this.householdId});

  final String householdId;

  static Future<void> show(BuildContext context, String householdId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HouseholdScreen(householdId: householdId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final households = ref.watch(householdsProvider).value ?? const [];
    final entry = households.where((h) => h.household.id == householdId).firstOrNull;
    final members = ref.watch(householdMembersProvider(householdId));
    final myUserId = ref.watch(identityProvider).userId;

    if (entry == null) {
      // Kein Zugriff mehr (entfernt/aufgeloest): zurueck.
      return const Scaffold(body: Center(child: Text('Kein Zugriff auf diesen Haushalt.')));
    }
    final myRole = entry.role;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.household.name),
        actions: [
          if (myRole.canManageMembers)
            IconButton(
              tooltip: 'Umbenennen',
              onPressed: () => _rename(context, ref, entry.household.name),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (list) => ListView(
          children: [
            const _SectionHeader('Mitglieder'),
            for (final member in list)
              _MemberTile(
                householdId: householdId,
                member: member,
                myRole: myRole,
                isMe: member.userId == myUserId,
              ),
            if (myRole.canManageMembers) ...[
              const Divider(),
              _InviteSection(householdId: householdId, myRole: myRole),
            ],
            const Divider(),
            const _SectionHeader('Aktionen'),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Haushalt verlassen'),
              onTap: () => _leave(context, ref, entry.household.name),
            ),
            if (myRole.canDeleteHousehold)
              ListTile(
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Haushalt aufloesen',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text('Fuer alle Mitglieder unwiderruflich.'),
                onTap: () => _delete(context, ref, entry.household.name),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Haushalt umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;
    await runHouseholdVoidAction(
      context,
      ref,
      () => ref.read(householdActionsProvider).rename(householdId, trimmed),
    );
  }

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Haushalt verlassen?'),
        content: Text(
          'Du verlaesst "$name". Als Eigentuemer musst du vorher die '
          'Eigentuemerschaft uebergeben oder den Haushalt aufloesen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final ok = await runHouseholdVoidAction(
      context,
      ref,
      () => ref.read(householdActionsProvider).leave(householdId),
    );
    if (!ok) return; // Fehler (z.B. Owner ohne Uebergabe)
    await ref.read(activeScopeProvider.notifier).select(
      AppScope.personal(ref.read(identityProvider).userId),
    );
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Haushalt aufloesen?'),
        content: Text(
          '"$name" wird fuer ALLE Mitglieder geloescht. Das laesst sich nicht '
          'rueckgaengig machen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Aufloesen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final ok = await runHouseholdVoidAction(
      context,
      ref,
      () => ref.read(householdActionsProvider).delete(householdId),
    );
    if (!ok) return;
    await ref.read(activeScopeProvider.notifier).select(
      AppScope.personal(ref.read(identityProvider).userId),
    );
    if (navigator.canPop()) navigator.pop();
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.householdId,
    required this.member,
    required this.myRole,
    required this.isMe,
  });

  final String householdId;
  final HouseholdMember member;
  final HouseholdRole myRole;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = HouseholdRole.values.firstWhere(
      (r) => r.name == member.role,
      orElse: () => HouseholdRole.member,
    );

    // Was darf ich mit diesem Mitglied tun?
    final canManageThis = !isMe &&
        role != HouseholdRole.owner &&
        (myRole == HouseholdRole.owner ||
            (myRole == HouseholdRole.admin &&
                role.rank < HouseholdRole.admin.rank));

    return ListTile(
      leading: CircleAvatar(child: Icon(role.icon)),
      title: Text(member.displayName + (isMe ? ' (du)' : '')),
      subtitle: Text(role.label),
      trailing: canManageThis
          ? PopupMenuButton<String>(
              onSelected: (value) => _onAction(context, ref, value, role),
              itemBuilder: (_) => [
                ...HouseholdRole.values
                    .where((r) => r != HouseholdRole.owner && myRole.canAssign(r))
                    .map(
                      (r) => PopupMenuItem(
                        value: 'role:${r.name}',
                        enabled: r != role,
                        child: Row(
                          children: [
                            Icon(r.icon, size: 18),
                            const SizedBox(width: 10),
                            Text('Rolle: ${r.label}'),
                          ],
                        ),
                      ),
                    ),
                if (myRole.canTransferOwnership)
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Zum Eigentuemer machen'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Entfernen'),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String value,
    HouseholdRole currentRole,
  ) async {
    final actions = ref.read(householdActionsProvider);
    if (value.startsWith('role:')) {
      final role = HouseholdRole.values.firstWhere(
        (r) => r.name == value.substring(5),
      );
      await runHouseholdVoidAction(
        context,
        ref,
        () => actions.setRole(householdId, member.userId, role),
      );
    } else if (value == 'remove') {
      await runHouseholdVoidAction(
        context,
        ref,
        () => actions.removeMember(householdId, member.userId),
      );
    } else if (value == 'transfer') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eigentuemerschaft uebergeben?'),
          content: Text(
            '${member.displayName} wird Eigentuemer. Du wirst zum Admin. Das '
            'kann nur der neue Eigentuemer rueckgaengig machen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Uebergeben'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await runHouseholdVoidAction(
        context,
        ref,
        () => actions.transferOwnership(householdId, member.userId),
      );
    }
  }
}

class _InviteSection extends ConsumerWidget {
  const _InviteSection({required this.householdId, required this.myRole});

  final String householdId;
  final HouseholdRole myRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(householdInvitesProvider(householdId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Einladungen',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Neu'),
              ),
            ],
          ),
        ),
        invites.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fehler: $error'),
          ),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Keine aktiven Einladungen.'),
                )
              : Column(
                  children: [
                    for (final invite in list)
                      _InviteTile(householdId: householdId, invite: invite),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    await InviteEditor.show(context, ref, householdId: householdId, myRole: myRole);
    ref.invalidate(householdInvitesProvider(householdId));
  }
}

class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.householdId, required this.invite});

  final String householdId;
  final RemoteInvite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = '${AppConfig.authRedirectScheme}://join?code=${invite.code}';
    return ListTile(
      leading: const Icon(Icons.confirmation_number_outlined),
      title: SelectableText(
        invite.prettyCode,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
      ),
      subtitle: Text(_subtitle()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Code kopieren',
            onPressed: () => _copy(context, invite.prettyCode, 'Code kopiert'),
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Link kopieren',
            onPressed: () => _copy(context, link, 'Einladungslink kopiert'),
            icon: const Icon(Icons.link_rounded),
          ),
          IconButton(
            tooltip: 'Widerrufen',
            onPressed: () => _revoke(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final parts = <String>['als ${invite.role.label}'];
    if (invite.maxUses != null) {
      parts.add('${invite.uses}/${invite.maxUses} genutzt');
    }
    if (invite.expiresAt != null) {
      parts.add('laeuft ab');
    }
    return parts.join(' · ');
  }

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    await runHouseholdVoidAction(
      context,
      ref,
      () => ref.read(householdActionsProvider).revokeInvite(invite.id),
    );
    ref.invalidate(householdInvitesProvider(householdId));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
