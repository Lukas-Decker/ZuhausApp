import 'package:flutter/material.dart';

/// Einheitlicher „Hinzufuegen"-Knopf.
///
/// Auf breiten Fenstern mit Beschriftung, auf schmalen (mobilen) nur als „+".
/// So bleibt die Aktion ueberall gleich und nimmt auf dem Handy wenig Platz.
class AddFab extends StatelessWidget {
  const AddFab({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add_rounded,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  static const double _compactBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < _compactBreakpoint;
    if (compact) {
      return FloatingActionButton(
        onPressed: onPressed,
        tooltip: label,
        child: Icon(icon),
      );
    }
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
