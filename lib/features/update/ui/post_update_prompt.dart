import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/diagnostics/debug_log.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/providers.dart';
import '../../../core/settings/app_settings.dart';

/// Prüft nach einem Update, ob Android den Wecker-Modus noch erlaubt.
///
/// Beim Ersetzen der App kann die Sonderfreigabe für Vollbild-Meldungen
/// verloren gehen. Der Schalter in den Einstellungen steht dann weiter auf an,
/// der Bildschirm bleibt aber dunkel. Deshalb hier einmal je Version nachsehen
/// und, wenn nötig, direkt anbieten sie nachzuholen.
///
/// Der Vergleich läuft über die zuletzt gestartete Version in den
/// Einstellungen; beide Zustände landen im Protokoll, damit sich beim nächsten
/// Mal belegen lässt, ob wirklich Android die Freigabe zurücksetzt.
class PostUpdatePrompt extends ConsumerStatefulWidget {
  const PostUpdatePrompt({super.key});

  /// Zuletzt gestartete Version, um ein Update zu erkennen.
  static const String lastRunVersionKey = 'update.lastRunVersion';

  @override
  ConsumerState<PostUpdatePrompt> createState() => _PostUpdatePromptState();
}

class _PostUpdatePromptState extends ConsumerState<PostUpdatePrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (!Platform.isAndroid) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final previous = prefs.getString(PostUpdatePrompt.lastRunVersionKey);
    if (previous == appVersion) return;
    await prefs.setString(PostUpdatePrompt.lastRunVersionKey, appVersion);

    final wakeWanted = ref.read(appSettingsProvider).wakeScreenEnabled;
    final service = ref.read(notificationServiceProvider);
    final allowed = await service.canUseFullScreenIntent();

    DebugLog.instance.add(
      'update',
      'Erster Start von $appVersion (vorher ${previous ?? 'unbekannt'}): '
          'Wecker-Schalter $wakeWanted, Android-Freigabe $allowed',
    );

    // Nur nachfragen, wenn der Nutzer den Wecker-Modus wirklich will und die
    // Freigabe tatsächlich fehlt.
    if (!wakeWanted || allowed || !mounted) return;
    await _ask();
  }

  Future<void> _ask() async {
    final grant = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.alarm_off_rounded),
        title: const Text('Wecker-Modus erneut erlauben'),
        content: const Text(
          'Nach dem Update erlaubt Android das Aufwecken des Bildschirms '
          'nicht mehr. Die Erinnerungen kommen zwar an, wecken dich aber '
          'nicht. Die Freigabe lässt sich in zwei Schritten nachholen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Später'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Erlauben'),
          ),
        ],
      ),
    );

    if (grant != true) return;
    await ref
        .read(notificationServiceProvider)
        .requestFullScreenIntentPermission();
    if (!mounted) return;
    ref.invalidate(notificationPermissionsProvider);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
