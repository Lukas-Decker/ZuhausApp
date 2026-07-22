/// Mengeneinheiten für Vorräte und Einkaufslisten.
enum MeasurementUnit {
  piece('Stk.', 'Stück'),
  package('Pck.', 'Packung'),
  bottle('Fl.', 'Flasche'),
  can('Do.', 'Dose'),
  gram('g', 'Gramm'),
  kilogram('kg', 'Kilogramm'),
  milliliter('ml', 'Milliliter'),
  liter('l', 'Liter');

  const MeasurementUnit(this.short, this.label);

  final String short;
  final String label;

  /// Ganze Stücke werden ohne Nachkommastellen dargestellt.
  bool get isCountable => switch (this) {
    MeasurementUnit.piece ||
    MeasurementUnit.package ||
    MeasurementUnit.bottle ||
    MeasurementUnit.can => true,
    _ => false,
  };

  static MeasurementUnit parse(String? value) => MeasurementUnit.values
      .firstWhere((u) => u.name == value, orElse: () => MeasurementUnit.piece);

  /// Formatiert eine Menge, z.B. "2 Stk." oder "1,5 l".
  String format(double quantity) {
    final text = quantity == quantity.roundToDouble()
        ? quantity.round().toString()
        : quantity.toStringAsFixed(1).replaceAll('.', ',');
    return '$text $short';
  }
}
