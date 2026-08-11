/// Aufloesung quellenspezifischer Haendlernamen auf kanonische IDs.
///
/// Notwendig, weil dieselbe Kette in verschiedenen Quellen unterschiedlich
/// heisst: Tjek schreibt `ALDI Sued`, Schwarz kennt sie gar nicht, Kaufland
/// taucht als `Kaufland` (Tjek) und als `kaufland/de-DE` (Schwarz) auf. Ohne
/// diese Ebene waere Kaufland in der App zweimal vorhanden.
library;

/// Ordnet einen Rohnamen einer Quelle einer kanonischen Haendler-ID zu.
///
/// Die Zuordnung ist bewusst datengetrieben und nicht ueber Heuristiken
/// geloest: die Namen sind stabil genug, dass eine Tabelle wartbarer und
/// nachvollziehbarer ist als eine Fuzzy-Suche.
class RetailerRegistry {
  const RetailerRegistry._();

  /// Normalisierter Rohname zu kanonischer ID.
  ///
  /// Jede Quelle schreibt dieselbe Kette anders. Tjek nutzt die englischen
  /// Formen ("Familia Northeast"), Marktguru die vollen Firmierungen
  /// ("dm-drogerie markt"). Ohne diese Tabelle stuende ein Haendler je Quelle
  /// einmal in der App.
  static const Map<String, String> _canonicalByName = {
    'aldi nord': 'aldi-nord',
    'aldi sued': 'aldi-sued',
    'aldi sud': 'aldi-sued',
    'citti': 'citti',
    'citti markt': 'citti',
    'dm': 'dm',
    'dm drogerie markt': 'dm',
    'dm drogeriemarkt': 'dm',
    'edeka': 'edeka',
    'edeka center': 'edeka',
    'familia northeast': 'famila-nordost',
    'familia northwest': 'famila-nordwest',
    'famila nordost': 'famila-nordost',
    'famila nordwest': 'famila-nordwest',
    'globus': 'globus',
    'globus markthalle': 'globus',
    'hit': 'hit',
    'hit markt': 'hit',
    'kaufland': 'kaufland',
    'lidl': 'lidl',
    'mueller': 'mueller',
    'mueller drogeriemarkt': 'mueller',
    'mueller drogerie markt': 'mueller',
    // Achtung: gemeint ist der deutsche Netto Marken-Discount (netto.de).
    // Der daenische Netto der Salling Group ist eine andere Kette, taucht in
    // deutschen Abfragen aber nur im Grenzhandel auf.
    'netto': 'netto',
    'netto marken discount': 'netto',
    'norma': 'norma',
    'penny': 'penny',
    'penny markt': 'penny',
    'rewe': 'rewe',
    'rewe center': 'rewe',
    'rossmann': 'rossmann',
    'tegut': 'tegut',
    'xxxlutz': 'xxxlutz',
  };

  /// Anzeigenamen je kanonischer ID. Sorgt fuer einheitliche Schreibweise,
  /// unabhaengig davon, welche Quelle den Haendler geliefert hat.
  static const Map<String, String> _displayNames = {
    'aldi-nord': 'ALDI Nord',
    'aldi-sued': 'ALDI SUED',
    'citti': 'CITTI',
    'dm': 'dm',
    'edeka': 'EDEKA',
    'famila-nordost': 'famila Nordost',
    'famila-nordwest': 'famila Nordwest',
    'globus': 'Globus',
    'hit': 'HIT',
    'kaufland': 'Kaufland',
    'lidl': 'Lidl',
    'mueller': 'Mueller',
    'netto': 'Netto',
    'norma': 'NORMA',
    'penny': 'PENNY',
    'rewe': 'REWE',
    'rossmann': 'Rossmann',
    'tegut': 'tegut',
    'xxxlutz': 'XXXLutz',
  };

  /// Kanonische ID zu einem Rohnamen. Faellt auf einen aus dem Namen
  /// abgeleiteten Slug zurueck, damit auch unbekannte Haendler eine stabile
  /// ID bekommen und nicht verloren gehen.
  static String canonicalId(String rawName) {
    final normalized = _normalize(rawName);
    final known = _canonicalByName[normalized];
    if (known != null) return known;
    return slugify(rawName);
  }

  /// Bevorzugter Anzeigename, sonst der Name der Quelle.
  static String displayName(String canonicalId, String fallback) =>
      _displayNames[canonicalId] ?? fallback;

  /// True, wenn die ID in der Tabelle steht. Nur fuer Diagnosezwecke.
  static bool isKnown(String canonicalId) =>
      _displayNames.containsKey(canonicalId);

  static String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(switch (String.fromCharCode(rune)) {
        'ä' => 'ae',
        'ö' => 'oe',
        'ü' => 'ue',
        'ß' => 'ss',
        'é' || 'è' || 'ê' => 'e',
        final c => c,
      });
    }
    // Mehrfache Leerzeichen und Sonderzeichen vereinheitlichen.
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  /// URL- und dateinamensicherer Slug aus einem beliebigen Namen.
  static String slugify(String value) {
    final normalized = _normalize(value).replaceAll(' ', '-');
    return normalized.isEmpty ? 'unknown' : normalized;
  }
}
