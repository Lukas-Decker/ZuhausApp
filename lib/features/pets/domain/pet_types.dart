import 'package:flutter/material.dart';

/// Tierarten mit Symbol.
const Map<String, ({String label, IconData icon})> petSpecies = {
  'dog': (label: 'Hund', icon: Icons.pets_rounded),
  'cat': (label: 'Katze', icon: Icons.pets_rounded),
  'bird': (label: 'Vogel', icon: Icons.flutter_dash_rounded),
  'fish': (label: 'Fisch', icon: Icons.set_meal_rounded),
  'rodent': (label: 'Nager', icon: Icons.cruelty_free_rounded),
  'reptile': (label: 'Reptil', icon: Icons.bug_report_rounded),
  'horse': (label: 'Pferd', icon: Icons.bedroom_baby_rounded),
  'other': (label: 'Sonstiges', icon: Icons.pets_outlined),
};

({String label, IconData icon}) petSpeciesInfo(String key) =>
    petSpecies[key] ?? petSpecies['other']!;

/// Symbole fuer Tagesaufgaben.
const Map<String, ({String label, IconData icon})> petTaskIcons = {
  'food': (label: 'Fuettern', icon: Icons.restaurant_rounded),
  'water': (label: 'Wasser', icon: Icons.water_drop_rounded),
  'walk': (label: 'Gassi', icon: Icons.directions_walk_rounded),
  'litter': (label: 'Katzenklo', icon: Icons.cleaning_services_rounded),
  'play': (label: 'Spielen', icon: Icons.sports_baseball_rounded),
  'brush': (label: 'Buersten', icon: Icons.brush_rounded),
  'clean': (label: 'Gehege', icon: Icons.home_work_rounded),
  'paw': (label: 'Sonstiges', icon: Icons.pets_rounded),
};

({String label, IconData icon}) petTaskIcon(String key) =>
    petTaskIcons[key] ?? petTaskIcons['paw']!;

/// Standard-Tagesaufgaben je Tierart, die beim Anlegen vorgeschlagen werden.
const Map<String, List<({String title, String iconKey, int timesPerDay, bool food})>>
petDefaultTasks = {
  'dog': [
    (title: 'Fuettern', iconKey: 'food', timesPerDay: 2, food: true),
    (title: 'Gassi', iconKey: 'walk', timesPerDay: 3, food: false),
    (title: 'Wasser', iconKey: 'water', timesPerDay: 1, food: false),
  ],
  'cat': [
    (title: 'Fuettern', iconKey: 'food', timesPerDay: 2, food: true),
    (title: 'Katzenklo', iconKey: 'litter', timesPerDay: 1, food: false),
    (title: 'Wasser', iconKey: 'water', timesPerDay: 1, food: false),
  ],
  'other': [
    (title: 'Fuettern', iconKey: 'food', timesPerDay: 1, food: true),
  ],
};

enum PetHealthKind {
  medication('medication', 'Medikament', Icons.medication_rounded),
  vaccination('vaccination', 'Impfung', Icons.vaccines_rounded),
  deworming('deworming', 'Entwurmung', Icons.medication_liquid_rounded),
  vet('vet', 'Tierarzt', Icons.local_hospital_rounded),
  other('other', 'Sonstiges', Icons.medical_services_rounded);

  const PetHealthKind(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static PetHealthKind parse(String? value) => PetHealthKind.values
      .firstWhere((k) => k.key == value, orElse: () => PetHealthKind.other);
}
