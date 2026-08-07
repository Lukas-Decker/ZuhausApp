import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/diagnostics/debug_log.dart';

/// Zeigt das laufende Fehler- und Ereignisprotokoll der App.
///
/// Gedacht fuer die Testphase: Fehler und Abstuerze werden sichtbar, ohne dass
/// ein Rechner mit Konsole angeschlossen sein muss. Der Inhalt liegt nur im
/// Arbeitsspeicher und laesst sich zum Weitergeben kopieren.
class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebugLogScreen()),
    );
  }

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  bool _onlyProblems = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<void>(
      stream: DebugLog.instance.changes,
      builder: (context, _) {
        final all = DebugLog.instance.entries;
        final entries = _onlyProblems
            ? all.where((e) => e.level != LogLevel.info).toList()
            : all;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Protokoll'),
            actions: [
              IconButton(
                tooltip: 'Kopieren',
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: DebugLog.instance.asText()),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Protokoll in die Zwischenablage kopiert.'),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy_rounded),
              ),
              IconButton(
                tooltip: 'Leeren',
                onPressed: () => setState(DebugLog.instance.clear),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${all.length} Einträge · '
                        '${DebugLog.instance.errorCount} Fehler',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    FilterChip(
                      selected: _onlyProblems,
                      label: const Text('Nur Probleme'),
                      onSelected: (value) =>
                          setState(() => _onlyProblems = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('Noch nichts protokolliert.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final color = switch (entry.level) {
                            LogLevel.error => scheme.error,
                            LogLevel.warning => scheme.tertiary,
                            LogLevel.info => scheme.onSurfaceVariant,
                          };
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    switch (entry.level) {
                                      LogLevel.error => Icons.error_outline,
                                      LogLevel.warning =>
                                        Icons.warning_amber_rounded,
                                      LogLevel.info => Icons.info_outline,
                                    },
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.source,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: color),
                                  ),
                                  const Spacer(),
                                  Text(
                                    entry.time
                                        .toIso8601String()
                                        .substring(11, 19),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(entry.message),
                              if (entry.details != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    entry.details!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontFamily: 'monospace'),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
