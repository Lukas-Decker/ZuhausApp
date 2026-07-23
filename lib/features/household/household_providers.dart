import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../auth/auth_providers.dart';
import 'data/household_remote_service.dart';
import 'domain/household_models.dart';

/// Remote-Dienst, sofern angemeldet; sonst `null` (Gastmodus).
final householdRemoteServiceProvider = Provider<HouseholdRemoteService?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !ref.watch(authConfiguredProvider)) return null;
  return HouseholdRemoteService(Supabase.instance.client);
});

/// Haelt den lokalen Haushalts-Cache mit dem Server im Takt.
///
/// Beim Anmelden werden Haushalte und Mitglieder geladen und in den lokalen
/// Drift-Cache gespiegelt; ein Realtime-Kanal loest bei jeder Aenderung ein
/// erneutes Laden aus. Beim Abmelden wird der Cache geleert. Muss irgendwo
/// beobachtet werden (siehe AppShell), damit der Seiteneffekt laeuft.
final householdSyncProvider = Provider<void>((ref) {
  final service = ref.watch(householdRemoteServiceProvider);
  final repo = ref.watch(householdRepositoryProvider);

  if (service == null) {
    repo.clearCache();
    return;
  }

  Future<void> refresh() async {
    try {
      final households = await service.fetchMyHouseholds();
      final members = await service.fetchMembers(
        households.map((h) => h.id).toList(),
      );
      await repo.mirror(
        households: [
          for (final h in households)
            (id: h.id, name: h.name, ownerUserId: h.ownerUserId),
        ],
        members: [
          for (final m in members)
            (
              householdId: m.householdId,
              userId: m.member.userId,
              displayName: m.member.displayName,
              role: m.member.role.name,
            ),
        ],
      );
    } catch (_) {
      // Offline o.ae.: bestehenden lokalen Cache behalten.
    }
  }

  refresh();
  final channel = service.subscribe(refresh);
  ref.onDispose(() {
    channel.unsubscribe();
  });
});

/// Mitglieder eines Haushalts aus dem lokalen Cache (reagiert auf den Mirror).
final householdMembersProvider =
    StreamProvider.family<List<HouseholdMember>, String>((ref, householdId) {
      return ref
          .watch(householdRepositoryProvider)
          .watchMembers(householdId);
    });

/// Aktive Einladungen eines Haushalts, direkt vom Server.
final householdInvitesProvider =
    FutureProvider.family<List<RemoteInvite>, String>((ref, householdId) async {
      final service = ref.watch(householdRemoteServiceProvider);
      if (service == null) return const [];
      // Bei Realtime-Aenderungen neu laden.
      ref.watch(householdSyncProvider);
      return service.fetchInvites(householdId);
    });
