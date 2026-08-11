/// Defensive Lesehilfen fuer JSON aus inoffiziellen APIs.
///
/// Die Quellen aendern Felder ohne Ankuendigung und liefern fuer dieselbe
/// Eigenschaft mal `null`, mal einen String, mal eine Zahl. Diese Helfer
/// liefern in solchen Faellen null statt zu werfen. Der Mapper entscheidet
/// dann, ob ein Eintrag verwertbar ist. Ein einzelner kaputter Eintrag darf
/// nie die gesamte Antwort verwerfen.
library;

extension JsonMapReader on Map<String, Object?> {
  Map<String, Object?>? mapAt(String key) {
    final value = this[key];
    return value is Map<String, Object?> ? value : null;
  }

  List<Object?>? listAt(String key) {
    final value = this[key];
    return value is List<Object?> ? value : null;
  }

  /// Alle Listenelemente, die selbst Objekte sind. Andere werden ignoriert.
  List<Map<String, Object?>> objectsAt(String key) =>
      listAt(key)?.whereType<Map<String, Object?>>().toList() ?? const [];

  /// String, aber nur wenn nicht leer. Leere Strings sind bei diesen Quellen
  /// gleichbedeutend mit "nicht gesetzt".
  String? stringAt(String key) {
    final value = this[key];
    if (value is String) return value.isEmpty ? null : value;
    return null;
  }

  double? doubleAt(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? intAt(String key) {
    final value = this[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? boolAt(String key) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) return value == 'true' ? true : (value == 'false' ? false : null);
    return null;
  }

  Uri? uriAt(String key) {
    final value = stringAt(key);
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme ? uri : null;
  }

  /// ISO-8601 oder Unix-Sekunden. Tjek nutzt beides, je nach Endpunkt.
  DateTime? dateAt(String key) {
    final value = this[key];
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt() * 1000,
        isUtc: true,
      );
    }
    return null;
  }
}
