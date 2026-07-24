import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../privacy_providers.dart';
import 'privacy_info_screen.dart';

/// Zeigt beim ersten Start einen Datenschutz-Hinweis, bis er bestätigt ist.
///
/// Sitzt (wie das App-Schloss) im `builder` der MaterialApp und umschließt die
/// gesamte App. Bewusst schlicht und blockierend: erst nach Bestätigung geht
/// es weiter.
class ConsentGate extends ConsumerWidget {
  const ConsentGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accepted = ref.watch(
      appSettingsProvider.select((s) => s.privacyAccepted),
    );
    if (accepted) return child;

    // Eigener Navigator, damit die Detailseite über dem Hinweis geöffnet
    // werden kann (der Router-Navigator liegt unter diesem Gate).
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => _ConsentScreen(
          onAccept: () async {
            await ref
                .read(appSettingsProvider.notifier)
                .setPrivacyAccepted(true);
            final scope = ref.read(activeScopeProvider);
            await ref
                .read(auditServiceProvider)
                .log(
                  scope: scope,
                  entityType: 'consent',
                  action: 'accept',
                  summary: 'Datenschutz-Hinweis beim ersten Start bestätigt',
                );
          },
        ),
      ),
    );
  }
}

class _ConsentScreen extends StatelessWidget {
  const _ConsentScreen({required this.onAccept});

  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Willkommen bei $appName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const _Point(
                      icon: Icons.wifi_off_rounded,
                      text:
                          'Die App läuft offline. Ohne Konto bleiben alle Daten '
                          'auf diesem Gerät.',
                    ),
                    const _Point(
                      icon: Icons.cloud_outlined,
                      text:
                          'Nur bei Anmeldung werden Daten zum Abgleich in der EU '
                          '(Supabase) gespeichert.',
                    ),
                    const _Point(
                      icon: Icons.visibility_off_outlined,
                      text: 'Keine Telemetrie, kein Tracking, keine Werbung.',
                    ),
                    const _Point(
                      icon: Icons.download_outlined,
                      text:
                          'Du kannst deine Daten jederzeit exportieren und dein '
                          'Konto endgültig löschen.',
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => PrivacyInfoScreen.show(context),
                      child: const Text('Datenschutz im Detail'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onAccept,
                        child: const Text('Verstanden und einverstanden'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
