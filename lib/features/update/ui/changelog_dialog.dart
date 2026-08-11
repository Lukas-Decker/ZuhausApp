import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/release_manifest.dart';

/// Zeigt die Änderungen als Dialog, ein Abschnitt je Version.
Future<void> showChangelogDialog(
  BuildContext context, {
  required List<ChangelogEntry> entries,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(entries.length == 1 ? 'Änderungen' : 'Was ist neu'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in entries) _ChangelogSection(entry: entry),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Schließen'),
        ),
      ],
    ),
  );
}

class _ChangelogSection extends StatelessWidget {
  const _ChangelogSection({required this.entry});

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = entry.date;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Version ${entry.version}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (date != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('d. MMMM y', 'de').format(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          for (final line in _bulletsOf(entry.notes))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Zerlegt den Text in Stichpunkte. Das Changelog schreibt sie als
  /// "- ..." und bricht lange Punkte eingerückt um; solche Folgezeilen
  /// gehören zum vorherigen Punkt.
  static List<String> _bulletsOf(String notes) {
    final bullets = <String>[];
    for (final raw in notes.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('- ') || line.startsWith('* ')) {
        bullets.add(line.substring(2).trim());
      } else if (bullets.isEmpty) {
        bullets.add(line);
      } else {
        bullets[bullets.length - 1] = '${bullets.last} $line';
      }
    }
    return bullets;
  }
}
