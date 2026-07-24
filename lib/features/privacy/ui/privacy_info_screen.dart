import 'package:flutter/material.dart';

/// Zusammenfassung, wie die App mit Daten umgeht (DSGVO-Transparenz).
class PrivacyInfoScreen extends StatelessWidget {
  const PrivacyInfoScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: 'Offline-first',
            body:
                'Die App funktioniert vollständig ohne Konto. Alle Daten '
                'liegen zunächst nur auf deinem Gerät.',
          ),
          _Section(
            title: 'Konto und Synchronisierung',
            body:
                'Nur wenn du dich anmeldest, werden Daten zum Abgleich an '
                'unseren Anbieter Supabase übertragen und dort gespeichert. '
                'Das Hosting liegt in der EU.',
          ),
          _Section(
            title: 'Keine Telemetrie',
            body:
                'Es gibt kein Tracking, keine Analyse und keine Werbe-IDs. '
                'Es werden keine Nutzungsdaten an Dritte gesendet.',
          ),
          _Section(
            title: 'Gesundheitsdaten',
            body:
                'Der Pillen-Tracker verarbeitet besondere Daten (DSGVO Art. 9) '
                'nur mit deiner ausdrücklichen Einwilligung und standardmäßig '
                'privat. Eine Freigabe an Betreuer erfolgt pro Plan.',
          ),
          _Section(
            title: 'Barcode-Abfrage',
            body:
                'Beim Scannen wird nur der Barcode an Open Food Facts '
                'übertragen, und auch das nur nach deiner Einwilligung.',
          ),
          _Section(
            title: 'Deine Rechte',
            body:
                'Du kannst deine Daten jederzeit exportieren (Auskunft und '
                'Mitnahme) und dein Konto samt Serverdaten endgültig löschen. '
                'Beides findest du in den Einstellungen unter Datenschutz.',
          ),
          _Section(
            title: 'Aufbewahrung',
            body:
                'Gelöschte Einträge und alte Protokolleinträge werden nach '
                'der eingestellten Frist (Standard 90 Tage) endgültig entfernt.',
          ),
          _Section(
            title: 'Aktivitätsprotokoll',
            body:
                'Datenschutzrelevante Handlungen (Einwilligungen, Export, '
                'App-Schloss) werden lokal protokolliert, damit du sie '
                'nachvollziehen kannst.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
