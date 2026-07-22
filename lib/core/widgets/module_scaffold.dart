import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';

/// Einheitlicher Rahmen fuer alle Modul-Bildschirme.
///
/// Der Kontextbanner sitzt eine Ebene hoeher in der [AppShell], deshalb
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
    final showSettingsAction =
        MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          if (showSettingsAction)
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
