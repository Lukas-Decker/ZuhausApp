import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../privacy_providers.dart';

/// Zeigt das lokale Aktivitaetsprotokoll (Audit-Log).
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuditLogScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(auditLogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitätsprotokoll')),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Noch keine Einträge. Datenschutzrelevante Aktionen '
                  'erscheinen hier.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final format = DateFormat('dd.MM.yyyy HH:mm', 'de');
          return ListView.separated(
            // Platz fuer die Systemleiste am unteren Rand.
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = list[index];
              return ListTile(
                leading: Icon(_iconFor(entry.action)),
                title: Text(entry.summary),
                subtitle: Text(
                  '${format.format(entry.createdAt)}'
                  '${entry.actorName != null ? ' - ${entry.actorName}' : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String action) => switch (action) {
    'create' => Icons.add_circle_outline,
    'update' => Icons.edit_outlined,
    'delete' => Icons.delete_outline,
    'accept' => Icons.check_circle_outline,
    'export' => Icons.download_outlined,
    _ => Icons.circle_outlined,
  };
}
