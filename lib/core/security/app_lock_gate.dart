import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import 'app_lock.dart';

/// Legt bei aktivem App-Schloss eine Sperre ueber die gesamte App.
///
/// Sitzt im `builder` der [MaterialApp], umschliesst also den kompletten
/// Router. Die eigentliche Oberflaeche bleibt im Baum (Zustand geht nicht
/// verloren), wird bei Sperrung aber vollstaendig verdeckt.
///
/// Gesperrt wird beim Kaltstart und immer dann, wenn die App in den
/// Hintergrund geht. Das Umlegen des Schalters in den Einstellungen sperrt
/// nicht sofort - sonst wuerde man sich beim Aktivieren selbst aussperren.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authInProgress = false;

  bool get _enabled => ref.read(appSettingsProvider).appLockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_enabled) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptUnlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Beim Verlassen sperren, damit beim Zurueckkehren neu geprueft wird.
        if (!_locked) setState(() => _locked = true);
      case AppLifecycleState.resumed:
        if (_locked) _promptUnlock();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _promptUnlock() async {
    if (_authInProgress) return;
    _authInProgress = true;
    final ok = await ref.read(appLockProvider).authenticate();
    _authInProgress = false;
    if (!mounted) return;
    if (ok) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    // Reagiert sofort, wenn das Schloss abgeschaltet wird.
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.appLockEnabled),
    );
    final showLock = enabled && _locked;

    return Stack(
      children: [
        widget.child,
        if (showLock) _LockScreen(onUnlock: _promptUnlock),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: scheme.primary),
              const SizedBox(height: 24),
              Text(
                'MultiApp ist gesperrt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Zum Fortfahren bitte entsperren.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Entsperren'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
