import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';

/// Einheitlicher Rahmen für alle Modul-Bildschirme.
///
/// Der Kontextbanner sitzt eine Ebene höher in der [AppShell], deshalb
/// braucht hier nur noch die Kopfzeile gesetzt zu werden.
class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    // Auf schmalen (mobilen) Layouts eine kompakte Kopfzeile, damit oben mehr
    // Platz fuer Inhalt bleibt; auf breiten Fenstern die Standardhoehe.
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        toolbarHeight: isCompact ? 44 : null,
        titleTextStyle: isCompact
            ? Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 18)
            : null,
        actions: [
          ...actions,
          if (isCompact)
            IconButton(
              tooltip: 'Einstellungen',
              onPressed: () => context.push(settingsPath),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
