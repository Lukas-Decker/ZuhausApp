import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/notification_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/widgets/sheet_insets.dart';

/// Diagnose fuer Erinnerungen: zeigt Rechte, Zeitzone und alle beim System
/// vorgemerkten Alarme und kann Testmeldungen ausloesen.
///
/// Damit laesst sich eingrenzen, ob es an den Rechten, am Planen oder am
/// Zustellen durch Android liegt.
class NotificationDebugScreen extends ConsumerStatefulWidget {
  const NotificationDebugScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationDebugScreen()),
    );
  }

  @override
  ConsumerState<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState
    extends ConsumerState<NotificationDebugScreen> {
  List<PendingNotificationRequest> _pending = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final pending = await ref.read(notificationServiceProvider).pending();
    ref.invalidate(notificationPermissionsProvider);
    if (!mounted) return;
    setState(() {
      _pending = pending..sort((a, b) => a.id.compareTo(b.id));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(notificationServiceProvider);
    final permissions = ref.watch(notificationPermissionsProvider);
    final format = DateFormat('dd.MM. HH:mm', 'de');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erinnerungen prüfen'),
        actions: [
          IconButton(
            tooltip: 'Neu laden',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + systemBottomInset(context)),
        children: [
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          _row('Benachrichtigungen technisch aktiv', service.isSupported),
          _row('Erkannte Zeitzone', null, value: service.timeZoneName),
          permissions.when(
            loading: () => const ListTile(
              dense: true,
              title: Text('Rechte werden geprüft ...'),
            ),
            error: (error, _) => ListTile(dense: true, title: Text('$error')),
            data: (data) => Column(
              children: [
                _row('Recht: Benachrichtigungen', data.notificationsAllowed),
                _row('Recht: Alarme & Erinnerungen', data.exactAlarmsAllowed),
                _row('Recht: Bildschirm aufwecken', data.fullScreenAllowed),
                _row('Recht: Bitte nicht stören', data.dndBypassAllowed),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('Test', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await service.show(
                    id: 999001,
                    title: 'Testmeldung',
                    body: 'Wenn du das siehst, funktioniert die Anzeige.',
                  );
                  await _reload();
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Jetzt anzeigen'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final when = DateTime.now().add(const Duration(seconds: 10));
                  await service.schedule(
                    ScheduledReminder(
                      id: 999002,
                      title: 'Geplanter Test',
                      body: 'Diese Meldung war für '
                          '${DateFormat('HH:mm:ss', 'de').format(when)} geplant.',
                      when: when,
                      payload: 'debug:test',
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Geplant. Bildschirm jetzt sperren und 10 Sekunden warten.',
                      ),
                    ),
                  );
                  await _reload();
                },
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('In 10 Sekunden'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kommt "Jetzt anzeigen" an, aber die geplante nicht, blockiert '
            'Android das zeitgenaue Wecken. Das liegt dann meist an der '
            'Akku-Optimierung des Herstellers (bei Samsung: Einstellungen → '
            'Akku → Nutzungslimits für Apps → "Apps im Ruhemodus"). Trage '
            '$_appLabel dort als Ausnahme ein bzw. erlaube uneingeschränkte '
            'Akkunutzung.\n\n'
            'Soll auch der Bildschirm angehen, muss oben "Recht: Bildschirm '
            'aufwecken" auf ja stehen UND der Schalter "Wie ein Wecker" in den '
            'Einstellungen an sein. Zum Prüfen den Bildschirm sperren, bevor '
            'die Zeit abläuft.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vorgemerkte Erinnerungen (${_pending.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (!_loading && _pending.isEmpty)
            Text(
              'Keine. Wenn hier nichts steht, wurde nichts geplant: dann liegt '
              'es nicht an Android, sondern an der App (Plan inaktiv, '
              'Erinnerung im Plan aus, oder Zeitpunkt liegt in der '
              'Vergangenheit).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          for (final request in _pending)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm_rounded),
              title: Text(request.title ?? '(ohne Titel)'),
              subtitle: Text(
                '${request.body ?? ''}\n'
                'id ${request.id} · ${request.payload ?? 'ohne Payload'}',
              ),
              isThreeLine: true,
            ),
          const SizedBox(height: 16),
          Text(
            'Hinweis: Die Liste zeigt, was die App beim System vorgemerkt hat. '
            'Der genaue Zeitpunkt wird von Android nicht zurückgemeldet; er '
            'steckt im Text bzw. im Payload. Zeitformat: '
            '${format.format(DateTime.now())}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static const String _appLabel = 'Zuhaus';

  Widget _row(String label, bool? ok, {String? value}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: ok == null
          ? const Icon(Icons.info_outline, size: 20)
          : Icon(
              ok ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 20,
              color: ok
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
      title: Text(label),
      trailing: Text(value ?? (ok! ? 'ja' : 'NEIN')),
    );
  }
}
