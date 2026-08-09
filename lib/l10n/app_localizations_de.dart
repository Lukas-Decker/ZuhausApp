// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonLater => 'Später';

  @override
  String get commonAllow => 'Erlauben';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String commonError(String message) {
    return 'Fehler: $message';
  }

  @override
  String get medsTitle => 'Pillen';

  @override
  String get medsDoseTaken => 'Genommen';

  @override
  String get medsDoseSkipped => 'Ausgelassen';

  @override
  String get medsDosePostponed => 'Verschoben';

  @override
  String medsSnoozeMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String medsSnoozeSeconds(int seconds) {
    return '$seconds Sek.';
  }

  @override
  String get medsPlanMissing => 'Dieser Plan existiert nicht mehr.';

  @override
  String medsReminderTitle(String dose) {
    return '$dose nehmen';
  }

  @override
  String medsReminderBody(String name) {
    return 'Zeit für $name';
  }

  @override
  String get medsScheduleDaily => 'Feste Uhrzeiten';

  @override
  String get medsScheduleScheme => 'Tageszeiten (1-0-1)';

  @override
  String get medsScheduleInterval => 'Im Abstand';

  @override
  String get medsSlotMorning => 'Morgens';

  @override
  String get medsSlotNoon => 'Mittags';

  @override
  String get medsSlotEvening => 'Abends';

  @override
  String get medsSlotNight => 'Nachts';

  @override
  String get medsSchemeHint =>
      'Menge je Tageszeit. Leer oder 0 heißt: dann nichts einnehmen.';

  @override
  String medsSchemeSummary(String scheme, String times) {
    return '$scheme ($times)';
  }

  @override
  String get medsSchemeEmpty =>
      'Bitte für mindestens eine Tageszeit eine Menge angeben.';

  @override
  String get medsHintsTitle => 'Einnahmehinweise';

  @override
  String get medsHintsExplainTitle => 'Was bedeuten die Hinweise?';

  @override
  String get medsHintsDisclaimer =>
      'Allgemeine Erklärungen, keine ärztliche Beratung. Im Zweifel gilt der Beipackzettel oder die Aussage deiner Ärztin.';

  @override
  String get medsHintsNoteLabel => 'Eigene Anmerkung';

  @override
  String get medsHintsNoteHint => 'z.B. mit der blauen Dose verwechselbar';

  @override
  String get medsHintFasting => 'Auf nüchternen Magen';

  @override
  String get medsHintFastingInfo =>
      'Mindestens eine Stunde vor oder zwei Stunden nach dem Essen einnehmen. Nahrung im Magen würde die Aufnahme des Wirkstoffs stören.';

  @override
  String get medsHintWithFood => 'Zum Essen';

  @override
  String get medsHintWithFoodInfo =>
      'Während einer Mahlzeit einnehmen. Das schont den Magen und hilft bei Wirkstoffen, die mit Fett besser aufgenommen werden.';

  @override
  String get medsHintBeforeFood => 'Vor dem Essen';

  @override
  String get medsHintBeforeFoodInfo =>
      'Etwa 15 bis 30 Minuten vor der Mahlzeit einnehmen.';

  @override
  String get medsHintAfterFood => 'Nach dem Essen';

  @override
  String get medsHintAfterFoodInfo =>
      'Direkt im Anschluss an die Mahlzeit einnehmen.';

  @override
  String get medsHintUpright => 'Danach aufrecht bleiben';

  @override
  String get medsHintUprightInfo =>
      'Nach der Einnahme etwa 30 Minuten nicht hinlegen, damit die Tablette nicht in der Speiseröhre liegen bleibt.';

  @override
  String get medsHintWater => 'Mit viel Wasser';

  @override
  String get medsHintWaterInfo =>
      'Mit einem vollen Glas Wasser einnehmen, nicht mit Kaffee, Tee oder Saft.';

  @override
  String get medsHintNoDairy => 'Nicht mit Milch';

  @override
  String get medsHintNoDairyInfo =>
      'Milch, Käse und Joghurt zwei Stunden vorher und nachher meiden: Kalzium kann den Wirkstoff binden.';

  @override
  String get medsHintNoAlcohol => 'Kein Alkohol';

  @override
  String get medsHintNoAlcoholInfo =>
      'Während der Einnahme keinen Alkohol trinken.';

  @override
  String get medsHintAvoidSun => 'Sonne meiden';

  @override
  String get medsHintAvoidSunInfo =>
      'Die Haut reagiert empfindlicher auf Sonne. Direkte Sonne und Solarium meiden, Sonnenschutz verwenden.';

  @override
  String get medsFormTablet => 'Tablette';

  @override
  String get medsFormCapsule => 'Kapsel';

  @override
  String get medsFormDrop => 'Tropfen';

  @override
  String get medsFormSpray => 'Spray';

  @override
  String get medsFormInjection => 'Spritze';

  @override
  String get medsFormOintment => 'Salbe';

  @override
  String get medsFormOther => 'Sonstiges';

  @override
  String medsDoseTablet(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Tabletten',
      one: '$amount Tablette',
    );
    return '$_temp0';
  }

  @override
  String medsDoseCapsule(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Kapseln',
      one: '$amount Kapsel',
    );
    return '$_temp0';
  }

  @override
  String medsDoseDrop(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Tropfen',
      one: '$amount Tropfen',
    );
    return '$_temp0';
  }

  @override
  String medsDoseSpray(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Sprühstöße',
      one: '$amount Sprühstoß',
    );
    return '$_temp0';
  }

  @override
  String medsDoseInjection(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Spritzen',
      one: '$amount Spritze',
    );
    return '$_temp0';
  }

  @override
  String medsDoseOintment(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Anwendungen',
      one: '$amount Anwendung',
    );
    return '$_temp0';
  }

  @override
  String medsDoseOther(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount Einheiten',
      one: '$amount Einheit',
    );
    return '$_temp0';
  }
}
