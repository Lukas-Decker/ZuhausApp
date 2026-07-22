import 'package:flutter/material.dart';

/// Grobe Warengruppen, damit die Liste im Laden nach Gängen sortiert ist.
enum ShoppingCategory {
  produce('Obst & Gemüse', Icons.eco_rounded),
  bakery('Backwaren', Icons.bakery_dining_rounded),
  dairy('Milch & Käse', Icons.egg_alt_rounded),
  meat('Fleisch & Fisch', Icons.set_meal_rounded),
  frozen('Tiefkühl', Icons.ac_unit_rounded),
  pantry('Vorrat & Konserven', Icons.inventory_2_rounded),
  drinks('Getränke', Icons.local_drink_rounded),
  household('Haushalt', Icons.cleaning_services_rounded),
  care('Drogerie', Icons.soap_rounded),
  pet('Tierbedarf', Icons.pets_rounded),
  other('Sonstiges', Icons.shopping_basket_rounded);

  const ShoppingCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static ShoppingCategory parse(String? value) => ShoppingCategory.values
      .firstWhere((c) => c.name == value, orElse: () => ShoppingCategory.other);

  /// Rät die Warengruppe aus dem Produktnamen oder der Open-Food-Facts-Kategorie.
  ///
  /// Bewusst simpel gehalten: die Zuordnung ist nur ein Vorschlag und lässt
  /// sich im Formular jederzeit ändern.
  static ShoppingCategory guess(String text) {
    final value = text.toLowerCase();
    bool has(List<String> needles) => needles.any(value.contains);

    if (has(['obst', 'gemüse', 'salat', 'apfel', 'banane', 'tomate',
      'kartoffel', 'zwiebel', 'gurke', 'paprika'])) {
      return ShoppingCategory.produce;
    }
    if (has(['brot', 'brötchen', 'semmel', 'baguette', 'kuchen', 'toast'])) {
      return ShoppingCategory.bakery;
    }
    if (has(['milch', 'käse', 'joghurt', 'quark', 'butter', 'sahne', 'ei'])) {
      return ShoppingCategory.dairy;
    }
    if (has(['fleisch', 'wurst', 'hack', 'schinken', 'fisch', 'lachs',
      'hähnchen', 'huhn'])) {
      return ShoppingCategory.meat;
    }
    if (has(['tiefkühl', 'gefroren', 'eis', 'pizza'])) {
      return ShoppingCategory.frozen;
    }
    if (has(['nudel', 'pasta', 'reis', 'mehl', 'zucker', 'konserve', 'dose',
      'öl', 'essig', 'soße', 'sauce'])) {
      return ShoppingCategory.pantry;
    }
    if (has(['wasser', 'saft', 'cola', 'bier', 'wein', 'kaffee', 'tee',
      'limo', 'getränk'])) {
      return ShoppingCategory.drinks;
    }
    if (has(['spül', 'wasch', 'putz', 'reiniger', 'müllbeutel', 'papier'])) {
      return ShoppingCategory.household;
    }
    if (has(['shampoo', 'zahn', 'duschgel', 'seife', 'creme', 'windel'])) {
      return ShoppingCategory.care;
    }
    if (has(['katze', 'hund', 'futter', 'streu', 'napf'])) {
      return ShoppingCategory.pet;
    }
    return ShoppingCategory.other;
  }
}
