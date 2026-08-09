// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonLater => 'Later';

  @override
  String get commonAllow => 'Allow';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSettings => 'Settings';

  @override
  String commonError(String message) {
    return 'Error: $message';
  }

  @override
  String get medsTitle => 'Meds';

  @override
  String get medsDoseTaken => 'Taken';

  @override
  String get medsDoseSkipped => 'Skipped';

  @override
  String get medsDosePostponed => 'Postponed';

  @override
  String medsSnoozeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String medsSnoozeSeconds(int seconds) {
    return '$seconds sec';
  }

  @override
  String get medsPlanMissing => 'This plan no longer exists.';

  @override
  String medsReminderTitle(String dose) {
    return 'Take $dose';
  }

  @override
  String medsReminderBody(String name) {
    return 'Time for $name';
  }

  @override
  String get medsFormTablet => 'Tablet';

  @override
  String get medsFormCapsule => 'Capsule';

  @override
  String get medsFormDrop => 'Drops';

  @override
  String get medsFormSpray => 'Spray';

  @override
  String get medsFormInjection => 'Injection';

  @override
  String get medsFormOintment => 'Ointment';

  @override
  String get medsFormOther => 'Other';

  @override
  String medsDoseTablet(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount tablets',
      one: '$amount tablet',
    );
    return '$_temp0';
  }

  @override
  String medsDoseCapsule(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount capsules',
      one: '$amount capsule',
    );
    return '$_temp0';
  }

  @override
  String medsDoseDrop(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount drops',
      one: '$amount drop',
    );
    return '$_temp0';
  }

  @override
  String medsDoseSpray(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount sprays',
      one: '$amount spray',
    );
    return '$_temp0';
  }

  @override
  String medsDoseInjection(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount injections',
      one: '$amount injection',
    );
    return '$_temp0';
  }

  @override
  String medsDoseOintment(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount applications',
      one: '$amount application',
    );
    return '$_temp0';
  }

  @override
  String medsDoseOther(num count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount units',
      one: '$amount unit',
    );
    return '$_temp0';
  }
}
