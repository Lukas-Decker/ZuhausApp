import 'package:supabase_flutter/supabase_flutter.dart';

/// Ein Familien-Ereignis, wie es vom Server kommt.
class FamilyEvent {
  const FamilyEvent({
    required this.id,
    required this.householdId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdBy,
    this.targetUserId,
  });

  final String id;
  final String householdId;
  final String kind;
  final String title;
  final String body;
  final String createdBy;
  final String? targetUserId;

  factory FamilyEvent.fromJson(Map<String, dynamic> json) => FamilyEvent(
    id: json['id'] as String,
    householdId: json['household_id'] as String,
    kind: (json['kind'] as String?) ?? 'info',
    title: (json['title'] as String?) ?? '',
    body: (json['body'] as String?) ?? '',
    createdBy: (json['created_by'] as String?) ?? '',
    targetUserId: json['target_user_id'] as String?,
  );
}

/// Legt Familien-Ereignisse an und liefert eingehende ueber Realtime.
class FamilyEventService {
  FamilyEventService(this._client);

  final SupabaseClient _client;

  /// Legt ein Ereignis an (serverseitig gegen Doppelmeldungen geschuetzt).
  Future<void> postEvent({
    required String householdId,
    required String kind,
    required String title,
    String body = '',
    String? targetUserId,
    String? dedupKey,
  }) async {
    try {
      await _client.rpc(
        'post_household_event',
        params: {
          '_household': householdId,
          '_kind': kind,
          '_title': title,
          '_body': body,
          '_target_user': targetUserId,
          '_dedup_key': dedupKey,
        },
      );
    } catch (_) {
      // Offline o.ae.: Ereignis wird beim naechsten Lauf erneut versucht.
    }
  }

  /// Realtime-Kanal fuer neu angelegte Ereignisse.
  RealtimeChannel subscribe(void Function(FamilyEvent) onEvent) {
    return _client
        .channel('household-events')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'household_events',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;
            onEvent(FamilyEvent.fromJson(Map<String, dynamic>.from(record)));
          },
        )
        .subscribe();
  }
}
