import 'package:flutter/material.dart';

import '../../../core/widgets/sheet_insets.dart';
import '../domain/supplement_info.dart';

/// Infothek zu haeufigen Nahrungsergaenzungsmitteln.
///
/// Der Haftungsausschluss steht bewusst ganz oben und wiederholt sich in jedem
/// Detail, damit die Texte nicht als aerztlicher Rat missverstanden werden.
class SupplementInfoScreen extends StatelessWidget {
  const SupplementInfoScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupplementInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplement-Infothek')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + systemBottomInset(context)),
        children: [
          const _DisclaimerCard(),
          const SizedBox(height: 8),
          Text(
            'Häufige Präparate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (final info in supplementInfos)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(info.icon),
                title: Text(info.name),
                subtitle: Text(
                  info.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SupplementDetailScreen(info: info),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Unabhängige Quellen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (final source in supplementSources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.link_rounded),
              title: Text(source.label),
              subtitle: Text(source.source),
            ),
        ],
      ),
    );
  }
}

class _SupplementDetailScreen extends StatelessWidget {
  const _SupplementDetailScreen({required this.info});

  final SupplementInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(info.name)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + systemBottomInset(context)),
        children: [
          Row(
            children: [
              Icon(info.icon, size: 32, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Gut zu wissen',
            icon: Icons.info_outline_rounded,
            points: info.goodToKnow,
          ),
          _Section(
            title: 'Sicherheit',
            icon: Icons.health_and_safety_outlined,
            color: scheme.error,
            points: info.safety,
          ),
          const SizedBox(height: 8),
          const _DisclaimerCard(compact: true),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.points,
    this.color,
  });

  final String title;
  final IconData icon;
  final List<String> points;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: tint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      point,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Der Haftungsausschluss als hervorgehobene Karte.
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  'Haftungsausschluss',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              compact
                  ? 'Allgemeine Information, kein ärztlicher Rat und keine '
                        'Dosierungsempfehlung. Im Zweifel Ärztin, Arzt oder '
                        'Apotheke fragen.'
                  : supplementDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
