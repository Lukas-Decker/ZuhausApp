import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/diagnostics/debug_log.dart';
import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import 'data/update_installer.dart';
import 'data/update_service.dart';
import 'domain/release_manifest.dart';

/// Woran die Update-Funktion gerade arbeitet.
enum UpdatePhase {
  idle,
  checking,
  downloading,
  installing,
  failed;

  bool get isBusy => this == downloading || this == installing;
}

@immutable
class UpdateStatus {
  const UpdateStatus({
    this.phase = UpdatePhase.idle,
    this.manifest,
    this.asset,
    this.availability = UpdateAvailability.none,
    this.received = 0,
    this.total = 0,
    this.error,
    this.lastCheckedAt,
    this.needsInstallPermission = false,
  });

  final UpdatePhase phase;
  final ReleaseManifest? manifest;

  /// Das Paket, das zu diesem Geraet passt (auf Android die APK der
  /// richtigen Prozessorart).
  final ReleaseAsset? asset;

  final UpdateAvailability availability;
  final int received;
  final int total;
  final String? error;
  final DateTime? lastCheckedAt;

  /// Android: "Unbekannte Apps installieren" ist für diese App noch nicht
  /// erlaubt.
  final bool needsInstallPermission;

  bool get hasUpdate => availability.hasUpdate;

  /// Fortschritt zwischen 0 und 1, oder `null` bei unbekannter Gesamtgröße.
  double? get progress =>
      total > 0 ? (received / total).clamp(0.0, 1.0) : null;

  UpdateStatus copyWith({
    UpdatePhase? phase,
    ReleaseManifest? manifest,
    ReleaseAsset? asset,
    UpdateAvailability? availability,
    int? received,
    int? total,
    Object? error = _unset,
    DateTime? lastCheckedAt,
    bool? needsInstallPermission,
  }) => UpdateStatus(
    phase: phase ?? this.phase,
    manifest: manifest ?? this.manifest,
    asset: asset ?? this.asset,
    availability: availability ?? this.availability,
    received: received ?? this.received,
    total: total ?? this.total,
    error: error == _unset ? this.error : error as String?,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    needsInstallPermission:
        needsInstallPermission ?? this.needsInstallPermission,
  );

  static const Object _unset = Object();
}

class UpdateController extends Notifier<UpdateStatus> {
  /// Version, für die der Nutzer "Später" gewählt hat.
  static const String _keySkipped = 'update.skipped.version';

  /// Der Fortschritt darf die Oberfläche nicht überrollen.
  static const Duration _progressInterval = Duration(milliseconds: 200);

  DateTime _lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  UpdateStatus build() => const UpdateStatus();

  UpdateService get _service => ref.read(updateServiceProvider);
  UpdateInstaller get _installer => ref.read(updateInstallerProvider);

  /// Laufende Version der App.
  static AppVersion get currentVersion =>
      AppVersion.tryParse(appVersion) ?? const AppVersion(0, 0, 0);

  String? get skippedVersion =>
      ref.read(sharedPreferencesProvider).getString(_keySkipped);

  bool get isSupported => _service.isConfigured && _installer.isSupported;

  /// Holt das Manifest und vergleicht es mit der laufenden Version.
  Future<void> check() async {
    if (!isSupported || state.phase == UpdatePhase.checking) return;
    state = state.copyWith(phase: UpdatePhase.checking, error: null);
    try {
      final manifest = await _service.fetchManifest();
      // Auf Android bestimmt die Prozessorart, welche der APKs passt.
      final asset = manifest.assetFor(
        UpdateService.currentPlatform ?? '',
        abis: await _installer.supportedAbis(),
      );
      final availability = evaluateUpdate(
        current: currentVersion,
        manifest: manifest,
        asset: asset,
      );
      state = UpdateStatus(
        manifest: manifest,
        asset: asset,
        availability: availability,
        lastCheckedAt: DateTime.now(),
      );
      DebugLog.instance.add(
        'update',
        'Geprüft: ${manifest.latest} (${availability.name}, '
            'Paket ${asset?.fileName ?? 'keins'})',
      );
    } catch (error) {
      state = state.copyWith(
        phase: UpdatePhase.failed,
        error: '$error',
        lastCheckedAt: DateTime.now(),
      );
      DebugLog.instance.add(
        'update',
        'Prüfung fehlgeschlagen',
        level: LogLevel.error,
        error: error,
      );
    }
  }

  /// Lädt das Paket und startet die Installation.
  Future<void> downloadAndInstall() async {
    final asset = state.asset;
    if (asset == null) {
      state = state.copyWith(
        phase: UpdatePhase.failed,
        error: 'Kein passendes Paket für dieses Gerät im Manifest.',
      );
      return;
    }
    if (state.phase.isBusy) return;

    state = state.copyWith(
      phase: UpdatePhase.downloading,
      received: 0,
      total: asset.sizeBytes ?? 0,
      error: null,
      needsInstallPermission: false,
    );

    try {
      final file = await _installer.download(
        asset,
        onProgress: (received, total) {
          final now = DateTime.now();
          final done = total > 0 && received >= total;
          if (!done && now.difference(_lastProgressAt) < _progressInterval) {
            return;
          }
          _lastProgressAt = now;
          state = state.copyWith(received: received, total: total);
        },
      );

      if (!await _installer.canInstall()) {
        state = state.copyWith(
          phase: UpdatePhase.idle,
          needsInstallPermission: true,
        );
        return;
      }

      state = state.copyWith(phase: UpdatePhase.installing);
      // Auf Windows kehrt der Aufruf nicht zurück: die App beendet sich, das
      // Update-Skript tauscht die Dateien und startet neu.
      await _installer.install(file);
    } catch (error) {
      state = state.copyWith(phase: UpdatePhase.failed, error: '$error');
      DebugLog.instance.add(
        'update',
        'Installation fehlgeschlagen',
        level: LogLevel.error,
        error: error,
      );
    }
  }

  Future<void> openInstallPermissionSettings() =>
      _installer.openInstallPermissionSettings();

  /// Merkt sich, dass diese Version übersprungen wurde: der Hinweis beim Start
  /// kommt dann erst bei der nächsten Version wieder.
  Future<void> skipCurrentVersion() async {
    final latest = state.manifest?.latest;
    if (latest == null) return;
    await ref.read(sharedPreferencesProvider).setString(_keySkipped, '$latest');
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  final service = UpdateService();
  ref.onDispose(service.dispose);
  return service;
});

final updateInstallerProvider = Provider<UpdateInstaller>((ref) {
  final installer = UpdateInstaller();
  ref.onDispose(installer.dispose);
  return installer;
});

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateStatus>(UpdateController.new);

/// Prozessorart des Geraets (z. B. arm64-v8a), oder `null` wo es keine Rolle
/// spielt. Nur zur Anzeige: welche APK man von Hand nehmen muss.
final deviceAbiProvider = FutureProvider<String?>((ref) async {
  final abis = await ref.watch(updateInstallerProvider).supportedAbis();
  return abis.isEmpty ? null : abis.first;
});

/// Prüft beim Start und danach alle sechs Stunden, solange die Automatik in
/// den Einstellungen an ist.
final updateAutoCheckProvider = Provider<void>((ref) {
  final enabled = ref.watch(
    appSettingsProvider.select((settings) => settings.updateCheckEnabled),
  );
  final controller = ref.read(updateControllerProvider.notifier);
  if (!enabled || !controller.isSupported) return;

  // Nicht sofort beim ersten Frame: der Start hat Wichtigeres zu tun.
  var disposed = false;
  Future<void>.delayed(const Duration(seconds: 3)).then((_) {
    if (!disposed) controller.check();
  });
  final timer = Timer.periodic(
    const Duration(hours: 6),
    (_) => controller.check(),
  );
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
  });
});
