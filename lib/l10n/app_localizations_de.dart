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
