import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../auth/auth_providers.dart';
import 'sync_engine.dart';

/// Sync-Engine, sofern angemeldet; sonst `null` (Gastmodus).
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !ref.watch(authConfiguredProvider)) return null;
  return SyncEngine(ref.watch(databaseProvider), Supabase.instance.client);
});

enum SyncPhase { offline, idle, syncing, error }

class SyncStatus {
  const SyncStatus(this.phase, {this.lastSyncedAt, this.error});

  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? error;

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncedAt,
    String? error,
  }) => SyncStatus(
    phase ?? this.phase,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    error: error,
  );
}

/// Orchestriert den Modul-Sync: Erstabgleich, periodisch und per Realtime.
///
/// Muss beobachtet werden (siehe AppShell), damit die Ausloeser laufen.
class SyncController extends Notifier<SyncStatus> {
  Timer? _timer;
  Timer? _debounce;
  RealtimeChannel? _channel;
  StreamSubscription<void>? _localChanges;
  AppLifecycleListener? _lifecycle;
  bool _pending = false;

  /// Sicherheitsnetz-Intervall.
  static const _interval = Duration(seconds: 90);

  /// Wartezeit, um mehrere schnelle lokale Aenderungen zu buendeln.
  static const _debounceDelay = Duration(milliseconds: 1500);

  /// Tabellen, deren lokale Aenderung einen Abgleich ausloest.
  static final Set<String> _syncedTables = {
    for (final t in SyncEngine.tables) t.name,
  };

  @override
  SyncStatus build() {
    final engine = ref.watch(syncEngineProvider);
    ref.onDispose(_teardown);

    if (engine == null) {
      _teardown();
      return const SyncStatus(SyncPhase.offline);
    }

    _start();
    return const SyncStatus(SyncPhase.idle);
  }

  void _start() {
    final db = ref.read(databaseProvider);

    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => syncNow());

    // Eingehende Aenderungen anderer Geraete.
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('sync-records')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sync_records',
          callback: (_) => syncNow(),
        )
        .subscribe();

    // Eigene lokale Aenderungen: kurz buendeln, dann abgleichen. So gehen
    // Aenderungen fast sofort raus, ohne bei jedem Tastendruck zu funken.
    _localChanges?.cancel();
    _localChanges = db.tableUpdates().listen((updates) {
      if (updates.any((u) => _syncedTables.contains(u.table))) {
        _scheduleDebounced();
      }
    });

    // Beim Zurueckkehren in die App abgleichen.
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(onResume: syncNow);

    // Erstabgleich nach dem Aufbau.
    Future.microtask(syncNow);
  }

  void _scheduleDebounced() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, syncNow);
  }

  /// Stoesst einen Abgleich an. Laeuft bereits einer, wird er danach einmal
  /// wiederholt (damit zwischenzeitliche Aenderungen nicht liegen bleiben).
  Future<void> syncNow() async {
    final engine = ref.read(syncEngineProvider);
    if (engine == null) return;

    if (state.isSyncing) {
      _pending = true;
      return;
    }

    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      await engine.sync();
      state = SyncStatus(SyncPhase.idle, lastSyncedAt: DateTime.now());
    } catch (error) {
      state = SyncStatus(
        SyncPhase.error,
        lastSyncedAt: state.lastSyncedAt,
        error: error.toString(),
      );
    }

    if (_pending) {
      _pending = false;
      unawaited(syncNow());
    }
  }

  void _teardown() {
    _timer?.cancel();
    _timer = null;
    _debounce?.cancel();
    _debounce = null;
    _channel?.unsubscribe();
    _channel = null;
    _localChanges?.cancel();
    _localChanges = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
