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
  String get medsScheduleDaily => 'Fixed times';

  @override
  String get medsScheduleScheme => 'Times of day (1-0-1)';

  @override
  String get medsScheduleInterval => 'Every few hours';

  @override
  String get medsSlotMorning => 'Morning';

  @override
  String get medsSlotNoon => 'Noon';

  @override
  String get medsSlotEvening => 'Evening';

  @override
  String get medsSlotNight => 'Night';

  @override
  String get medsSchemeHint =>
      'Amount per time of day. Empty or 0 means: nothing to take then.';

  @override
  String medsSchemeSummary(String scheme, String times) {
    return '$scheme ($times)';
  }

  @override
  String get medsSchemeEmpty =>
      'Please enter an amount for at least one time of day.';

  @override
  String get medsHintsTitle => 'Intake notes';

  @override
  String get medsHintsExplainTitle => 'What do these notes mean?';

  @override
  String get medsHintsDisclaimer =>
      'General explanations, not medical advice. When in doubt, follow the leaflet or your doctor.';

  @override
  String get medsHintsNoteLabel => 'Your own note';

  @override
  String get medsHintsNoteHint => 'e.g. easy to mix up with the blue box';

  @override
  String get medsHintFasting => 'On an empty stomach';

  @override
  String get medsHintFastingInfo =>
      'Take at least one hour before or two hours after eating. Food in the stomach would interfere with absorption.';

  @override
  String get medsHintWithFood => 'With a meal';

  @override
  String get medsHintWithFoodInfo =>
      'Take during a meal. This is gentler on the stomach and helps with substances absorbed better with fat.';

  @override
  String get medsHintBeforeFood => 'Before eating';

  @override
  String get medsHintBeforeFoodInfo =>
      'Take about 15 to 30 minutes before the meal.';

  @override
  String get medsHintAfterFood => 'After eating';

  @override
  String get medsHintAfterFoodInfo => 'Take right after the meal.';

  @override
  String get medsHintUpright => 'Stay upright afterwards';

  @override
  String get medsHintUprightInfo =>
      'Do not lie down for about 30 minutes so the tablet does not stay in the oesophagus.';

  @override
  String get medsHintWater => 'With plenty of water';

  @override
  String get medsHintWaterInfo =>
      'Take with a full glass of water, not with coffee, tea or juice.';

  @override
  String get medsHintNoDairy => 'No dairy';

  @override
  String get medsHintNoDairyInfo =>
      'Avoid milk, cheese and yoghurt two hours before and after: calcium can bind the substance.';

  @override
  String get medsHintNoAlcohol => 'No alcohol';

  @override
  String get medsHintNoAlcoholInfo => 'Do not drink alcohol while taking this.';

  @override
  String get medsHintAvoidSun => 'Avoid the sun';

  @override
  String get medsHintAvoidSunInfo =>
      'Skin reacts more sensitively to sunlight. Avoid direct sun and tanning beds, use sunscreen.';

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
