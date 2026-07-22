import 'package:flutter/material.dart';

/// Auswählbare Notizfarben.
///
/// Gespeichert wird nur der Schlüssel. Der konkrete Farbton wird passend zur
/// Helligkeit (hell/dunkel) berechnet, damit Notizen in beiden Themes gut
/// lesbar bleiben.
enum NoteColor {
  defaultColor('default', 'Standard', null),
  red('red', 'Rot', Color(0xFFE53935)),
  orange('orange', 'Orange', Color(0xFFFB8C00)),
  yellow('yellow', 'Gelb', Color(0xFFF9A825)),
  green('green', 'Grün', Color(0xFF43A047)),
  teal('teal', 'Türkis', Color(0xFF00897B)),
  blue('blue', 'Blau', Color(0xFF1E88E5)),
  purple('purple', 'Lila', Color(0xFF8E24AA)),
  pink('pink', 'Pink', Color(0xFFD81B60));

  const NoteColor(this.key, this.label, this.seed);

  final String key;
  final String label;

  /// `null` bei [defaultColor]: dann gilt die normale Kartenfarbe des Themes.
  final Color? seed;

  static NoteColor parse(String? value) => NoteColor.values.firstWhere(
    (c) => c.key == value,
    orElse: () => NoteColor.defaultColor,
  );

  /// Hintergrund der Notizkarte im jeweiligen Theme.
  Color background(ColorScheme scheme) {
    if (seed == null) return scheme.surfaceContainerLow;
    return Color.alphaBlend(
      seed!.withValues(alpha: scheme.brightness == Brightness.dark ? 0.22 : 0.14),
      scheme.surfaceContainerLow,
    );
  }

  Color border(ColorScheme scheme) {
    if (seed == null) return scheme.outlineVariant;
    return seed!.withValues(alpha: 0.5);
  }
}
