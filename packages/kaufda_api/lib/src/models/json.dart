/// Kleine, tolerante JSON-Helfer.
///
/// Die API liefert Felder je nach Prospekt-Typ mal mit, mal ohne Wert. Alle
/// Helfer geben deshalb `null` bzw. eine leere Liste zurueck, statt zu werfen.
library;

/// Liest ein Unterobjekt.
Map<String, dynamic>? asMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

/// Liest eine Liste von Objekten und mappt sie mit [parse].
List<T> mapList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}

/// Liest eine Liste von Strings.
List<String> stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

/// Liest einen String, auch wenn das Feld fehlt oder `null` ist.
String? asString(Object? value) => value is String ? value : null;

/// Liest einen `int`, akzeptiert auch `double` und numerische Strings.
int? asInt(Object? value) => switch (value) {
      final int v => v,
      final double v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };

/// Liest einen `double`, akzeptiert auch `int` und numerische Strings.
double? asDouble(Object? value) => switch (value) {
      final double v => v,
      final int v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };

/// Liest einen `bool`, akzeptiert auch `"true"`/`"false"` und 0/1.
bool? asBool(Object? value) => switch (value) {
      final bool v => v,
      final num v => v != 0,
      'true' => true,
      'false' => false,
      _ => null,
    };

/// Parst einen ISO-8601-Zeitstempel. Die API mischt `+0000` und `+02:00`.
DateTime? asDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Entfernt `null`-Werte, damit `toJson()` kompakt bleibt.
Map<String, dynamic> compact(Map<String, dynamic> json) {
  json.removeWhere((_, value) => value == null);
  return json;
}
