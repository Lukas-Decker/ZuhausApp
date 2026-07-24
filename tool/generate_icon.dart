// Erzeugt die Quellgrafiken fuer das App-Icon: ein weisses Haus auf blauem
// Grund. Selbst gezeichnet (nur einfache geometrische Formen), damit es
// kommerziell unbedenklich ist.
//
// Ausgabe:
//   assets/icon/app_icon.png             (blauer Grund + weisses Haus)
//   assets/icon/app_icon_foreground.png  (nur weisses Haus, transparent)
//
// Danach die Plattform-Icons erzeugen mit:
//   dart run flutter_launcher_icons
//
// Aufruf: dart run tool/generate_icon.dart

import 'dart:io';

import 'package:image/image.dart' as img;

const int _size = 1024;
final img.Color _white = img.ColorRgba8(255, 255, 255, 255);
// Kontextfarbe "Privat" (ScopePalette.personalSeed = 0xFF2563EB).
final img.Color _blue = img.ColorRgba8(37, 99, 235, 255);

/// Zeichnet das Haus in die Bildmitte. [background] fuellt den Hintergrund
/// blau; sonst bleibt er transparent (fuer das adaptive Vordergrund-Icon).
img.Image _house({required bool background}) {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  if (background) {
    // Abgerundetes Quadrat (wie Android-Adaptive), Ecken bleiben transparent.
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: _size - 1,
      y2: _size - 1,
      color: _blue,
      radius: 200,
    );
  }

  // Dach als gefuelltes Dreieck (Zeile fuer Zeile), mit Ueberstand.
  const apexX = _size ~/ 2;
  const roofTop = 285;
  const roofBottom = 500;
  const roofHalf = 274; // Basis von 238 bis 786.
  for (var y = roofTop; y <= roofBottom; y++) {
    final t = (y - roofTop) / (roofBottom - roofTop);
    final half = (t * roofHalf).round();
    img.fillRect(
      image,
      x1: apexX - half,
      y1: y,
      x2: apexX + half,
      y2: y,
      color: _white,
    );
  }

  // Wand.
  img.fillRect(image, x1: 300, y1: 495, x2: 724, y2: 775, color: _white);

  // Tuer als blauer Ausschnitt (passt auf beiden Icons zum Hintergrund).
  img.fillRect(image, x1: 452, y1: 610, x2: 572, y2: 775, color: _blue);

  return image;
}

Future<void> _write(String path, img.Image image) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(img.encodePng(image));
  stdout.writeln('geschrieben: $path');
}

Future<void> main() async {
  await _write('assets/icon/app_icon.png', _house(background: true));
  await _write('assets/icon/app_icon_foreground.png', _house(background: false));
}
