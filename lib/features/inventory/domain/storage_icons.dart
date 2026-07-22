import 'package:flutter/material.dart';

/// Auswählbare Symbole für Aufbewahrungsorte.
///
/// In der Datenbank steht nur der Schlüssel, damit die Zeile plattform- und
/// versionsunabhängig bleibt.
const Map<String, IconData> storageIcons = {
  'fridge': Icons.kitchen_rounded,
  'freezer': Icons.ac_unit_rounded,
  'shelf': Icons.shelves,
  'cabinet': Icons.door_sliding_rounded,
  'basement': Icons.stairs_rounded,
  'bathroom': Icons.bathtub_rounded,
  'garage': Icons.garage_rounded,
  'pet': Icons.pets_rounded,
  'box': Icons.inventory_2_rounded,
};

IconData storageIconFor(String key) =>
    storageIcons[key] ?? Icons.inventory_2_rounded;

/// Vorbelegung für einen frisch angelegten Kontext.
const List<({String name, String iconKey})> defaultStorageLocations = [
  (name: 'Kühlschrank', iconKey: 'fridge'),
  (name: 'Gefrierschrank', iconKey: 'freezer'),
  (name: 'Vorratskammer', iconKey: 'shelf'),
  (name: 'Sonstiges', iconKey: 'box'),
];
