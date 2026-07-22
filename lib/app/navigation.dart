import 'package:flutter/material.dart';

/// Die fünf Module der App in fester Reihenfolge.
enum AppModule {
  inventory(
    path: '/inventar',
    label: 'Inventar',
    icon: Icons.kitchen_outlined,
    selectedIcon: Icons.kitchen_rounded,
  ),
  shopping(
    path: '/einkauf',
    label: 'Einkauf',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart_rounded,
  ),
  notes(
    path: '/notizen',
    label: 'Notizen',
    icon: Icons.sticky_note_2_outlined,
    selectedIcon: Icons.sticky_note_2_rounded,
  ),
  meds(
    path: '/pillen',
    label: 'Pillen',
    icon: Icons.medication_outlined,
    selectedIcon: Icons.medication_rounded,
  ),
  pets(
    path: '/tiere',
    label: 'Tiere',
    icon: Icons.pets_outlined,
    selectedIcon: Icons.pets_rounded,
  );

  const AppModule({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const settingsPath = '/einstellungen';
