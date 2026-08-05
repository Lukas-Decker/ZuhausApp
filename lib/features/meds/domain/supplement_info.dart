import 'package:flutter/material.dart';

/// Ein Eintrag der Supplement-Infothek.
///
/// Bewusst OHNE Dosierungsangaben: Mengen haengen von Alter, Ernaehrung,
/// Blutwerten und Medikamenten ab. Statt Zahlen zu nennen, verweisen die
/// Eintraege auf die offiziellen Quellen und aufs Nachfragen bei Arzt oder
/// Apotheke. Siehe [supplementDisclaimer].
@immutable
class SupplementInfo {
  const SupplementInfo({
    required this.name,
    required this.icon,
    required this.summary,
    required this.goodToKnow,
    required this.safety,
  });

  final String name;
  final IconData icon;

  /// Ein Satz: worum es geht.
  final String summary;

  /// Allgemein anerkannte Hintergrundinfos.
  final List<String> goodToKnow;

  /// Sicherheitshinweise: Wechselwirkungen, typische Fehler, Grenzen.
  final List<String> safety;
}

/// Pflicht-Hinweis, der ueber der gesamten Infothek steht.
const String supplementDisclaimer =
    'Diese Infothek ersetzt keine ärztliche Beratung. Die Texte sind '
    'allgemeine Informationen, keine Diagnose, keine Therapie- oder '
    'Dosierungsempfehlung und keine Heilversprechen.\n\n'
    'Nahrungsergänzungsmittel sind Lebensmittel, keine Arzneimittel. Sie '
    'können eine ausgewogene Ernährung nicht ersetzen. Sprich vor der '
    'Einnahme mit Ärztin, Arzt oder Apotheke, besonders bei Vorerkrankungen, '
    'in Schwangerschaft und Stillzeit, bei Kindern und wenn du Medikamente '
    'nimmst. Mehr hilft nicht mehr: Überdosierung kann schaden.';

/// Weiterfuehrende, unabhaengige Quellen (bewusst ohne Verkaufsinteresse).
const List<({String label, String source})> supplementSources = [
  (
    label: 'Bundesinstitut für Risikobewertung (BfR)',
    source: 'Höchstmengen und Risikobewertungen',
  ),
  (
    label: 'Verbraucherzentrale: Klartext Nahrungsergänzung',
    source: 'Unabhängige Einordnung von Werbeversprechen',
  ),
  (
    label: 'Deutsche Gesellschaft für Ernährung (DGE)',
    source: 'Referenzwerte für die Nährstoffzufuhr',
  ),
];

/// Kuratierte Auswahl haeufiger Praeparate.
const List<SupplementInfo> supplementInfos = [
  SupplementInfo(
    name: 'Vitamin D',
    icon: Icons.wb_sunny_outlined,
    summary:
        'Bildet der Körper vor allem über Sonnenlicht in der Haut; wichtig für '
        'Knochen und Immunsystem.',
    goodToKnow: [
      'In unseren Breiten ist die körpereigene Bildung im Winter gering.',
      'Über die Ernährung ist nur wenig zu decken (z.B. fetter Seefisch).',
      'Wird fettlöslich gespeichert, reichert sich also im Körper an.',
    ],
    safety: [
      'Der Status lässt sich im Blut bestimmen; das ist die sinnvolle '
          'Grundlage statt Selbstversuch.',
      'Dauerhaft zu hohe Zufuhr kann zu erhöhtem Kalziumspiegel und '
          'Nierenschäden führen.',
      'Hochdosierte Präparate aus dem Internet sind ein häufiger Grund für '
          'Überdosierungen.',
    ],
  ),
  SupplementInfo(
    name: 'Magnesium',
    icon: Icons.bolt_outlined,
    summary:
        'Beteiligt an Muskel- und Nervenfunktion sowie am Energiestoffwechsel.',
    goodToKnow: [
      'Steckt in Vollkorn, Nüssen, Hülsenfrüchten und grünem Gemüse.',
      'Es gibt verschiedene Verbindungen (z.B. Citrat, Oxid), die sich in der '
          'Verträglichkeit unterscheiden.',
    ],
    safety: [
      'Zu viel wirkt abführend: Durchfall ist das typische erste Zeichen.',
      'Bei eingeschränkter Nierenfunktion nur nach ärztlicher Rücksprache.',
      'Kann die Aufnahme mancher Antibiotika stören; zeitlichen Abstand '
          'ärztlich klären.',
    ],
  ),
  SupplementInfo(
    name: 'Vitamin B12',
    icon: Icons.energy_savings_leaf_outlined,
    summary:
        'Wichtig für Blutbildung und Nerven; kommt praktisch nur in tierischen '
        'Lebensmitteln vor.',
    goodToKnow: [
      'Bei rein pflanzlicher Ernährung gilt eine Ergänzung als notwendig.',
      'Auch bestimmte Magen-Darm-Erkrankungen und Medikamente können die '
          'Aufnahme beeinträchtigen.',
    ],
    safety: [
      'Ein Mangel entwickelt sich langsam und kann Nerven dauerhaft schädigen: '
          'lieber früh ärztlich abklären.',
      'Eine Ergänzung kann einen Folsäuremangel im Blutbild verschleiern.',
    ],
  ),
  SupplementInfo(
    name: 'Omega-3 (EPA/DHA)',
    icon: Icons.set_meal_outlined,
    summary: 'Langkettige Fettsäuren, vor allem aus fettem Seefisch oder Algen.',
    goodToKnow: [
      'Algenöl ist die pflanzliche Quelle für EPA und DHA.',
      'Pflanzliches ALA (z.B. Leinöl) wird im Körper nur begrenzt umgewandelt.',
    ],
    safety: [
      'Kann in höheren Mengen die Blutgerinnung beeinflussen: bei '
          'Blutverdünnern oder vor Operationen unbedingt ärztlich abklären.',
      'Auf Qualität achten; ranziges Öl erkennt man am Geruch.',
    ],
  ),
  SupplementInfo(
    name: 'Eisen',
    icon: Icons.bloodtype_outlined,
    summary: 'Nötig für den Sauerstofftransport im Blut.',
    goodToKnow: [
      'Eisen aus pflanzlichen Quellen wird schlechter aufgenommen; Vitamin C '
          'zur Mahlzeit verbessert die Aufnahme.',
      'Kaffee und Tee zur Mahlzeit hemmen die Aufnahme.',
    ],
    safety: [
      'Nur bei nachgewiesenem Mangel einnehmen. Eisen auf Verdacht ist riskant, '
          'weil der Körper Überschuss kaum ausscheiden kann.',
      'Häufige Nebenwirkungen sind Magen-Darm-Beschwerden und Verstopfung.',
      'Für Kinder sind Eisenpräparate gefährlich: sicher aufbewahren.',
    ],
  ),
  SupplementInfo(
    name: 'Zink',
    icon: Icons.shield_outlined,
    summary: 'Beteiligt an Immunfunktion, Wundheilung und Stoffwechsel.',
    goodToKnow: [
      'Steckt in Fleisch, Käse, Hülsenfrüchten und Vollkorn.',
      'Wird oft in Erkältungspräparaten beworben.',
    ],
    safety: [
      'Dauerhaft hohe Zufuhr kann den Kupferhaushalt stören.',
      'Kann die Aufnahme bestimmter Antibiotika verringern.',
    ],
  ),
  SupplementInfo(
    name: 'Kreatin',
    icon: Icons.fitness_center_outlined,
    summary:
        'Gut untersuchte Substanz aus dem Sportbereich, betrifft die '
        'Energiebereitstellung im Muskel.',
    goodToKnow: [
      'Kommt natürlich in Fleisch und Fisch vor.',
      'Der Körper bindet damit mehr Wasser im Muskel; eine leichte '
          'Gewichtszunahme zu Beginn ist normal.',
    ],
    safety: [
      'Bei Nieren- oder Lebererkrankungen nur nach ärztlicher Rücksprache.',
      'Ausreichend trinken.',
      'Kreatin kann Blutwerte (Kreatinin) verändern: erwähne die Einnahme bei '
          'Blutuntersuchungen.',
    ],
  ),
  SupplementInfo(
    name: 'Folsäure',
    icon: Icons.eco_outlined,
    summary: 'Wichtig für Zellteilung und Blutbildung.',
    goodToKnow: [
      'Bei Kinderwunsch und in der Frühschwangerschaft wird eine Ergänzung '
          'ausdrücklich empfohlen: dazu ärztlich beraten lassen.',
      'Steckt in grünem Gemüse, Hülsenfrüchten und Vollkorn.',
    ],
    safety: [
      'Hohe Mengen können einen Vitamin-B12-Mangel überdecken.',
      'Wechselwirkungen mit bestimmten Medikamenten (z.B. Methotrexat, '
          'Antiepileptika) ärztlich abklären.',
    ],
  ),
];
