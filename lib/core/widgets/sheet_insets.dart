import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Abstand, den der Inhalt eines Blattes nach unten braucht.
///
/// Zwei Dinge können von unten hereinragen: die Tastatur (viewInsets) und die
/// System-Leiste des Geräts (viewPadding), also der Gestenbalken oder die
/// Zurück-Knöpfe. Ohne den zweiten Wert sitzt die unterste Knopfreihe auf
/// vielen Telefonen halb unter der Systemleiste.
///
/// Beides gleichzeitig gibt es nie: bei offener Tastatur deckt sie die
/// Systemleiste ohnehin ab, deshalb der größere der beiden Werte.
double sheetBottomInset(BuildContext context) {
  final media = MediaQuery.of(context);
  return math.max(media.viewInsets.bottom, media.viewPadding.bottom);
}

/// Höhe der System-Leiste am unteren Rand (Gestenbalken oder Zurück-Knöpfe).
///
/// Für Bildschirme, deren Inhalt bis nach ganz unten scrollt: auf den
/// gewünschten Abstand aufaddieren, sonst verschwindet der letzte Eintrag
/// halb unter der Leiste.
double systemBottomInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom;
