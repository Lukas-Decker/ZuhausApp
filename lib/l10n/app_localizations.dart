import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Knopf: Eingaben uebernehmen
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get commonBack;

  /// No description provided for @commonLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get commonLater;

  /// No description provided for @commonAllow.
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get commonAllow;

  /// No description provided for @commonRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get commonRetry;

  /// No description provided for @commonSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get commonSettings;

  /// No description provided for @commonError.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {message}'**
  String commonError(String message);

  /// No description provided for @medsTitle.
  ///
  /// In de, this message translates to:
  /// **'Pillen'**
  String get medsTitle;

  /// No description provided for @medsDoseTaken.
  ///
  /// In de, this message translates to:
  /// **'Genommen'**
  String get medsDoseTaken;

  /// No description provided for @medsDoseSkipped.
  ///
  /// In de, this message translates to:
  /// **'Ausgelassen'**
  String get medsDoseSkipped;

  /// No description provided for @medsDosePostponed.
  ///
  /// In de, this message translates to:
  /// **'Verschoben'**
  String get medsDosePostponed;

  /// No description provided for @medsSnoozeMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String medsSnoozeMinutes(int minutes);

  /// No description provided for @medsSnoozeSeconds.
  ///
  /// In de, this message translates to:
  /// **'{seconds} Sek.'**
  String medsSnoozeSeconds(int seconds);

  /// No description provided for @medsPlanMissing.
  ///
  /// In de, this message translates to:
  /// **'Dieser Plan existiert nicht mehr.'**
  String get medsPlanMissing;

  /// Titel der Erinnerung, z.B. '2 Tabletten nehmen'
  ///
  /// In de, this message translates to:
  /// **'{dose} nehmen'**
  String medsReminderTitle(String dose);

  /// No description provided for @medsReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Zeit für {name}'**
  String medsReminderBody(String name);

  /// No description provided for @medsScheduleDaily.
  ///
  /// In de, this message translates to:
  /// **'Feste Uhrzeiten'**
  String get medsScheduleDaily;

  /// No description provided for @medsScheduleScheme.
  ///
  /// In de, this message translates to:
  /// **'Tageszeiten (1-0-1)'**
  String get medsScheduleScheme;

  /// No description provided for @medsScheduleInterval.
  ///
  /// In de, this message translates to:
  /// **'Im Abstand'**
  String get medsScheduleInterval;

  /// No description provided for @medsSlotMorning.
  ///
  /// In de, this message translates to:
  /// **'Morgens'**
  String get medsSlotMorning;

  /// No description provided for @medsSlotNoon.
  ///
  /// In de, this message translates to:
  /// **'Mittags'**
  String get medsSlotNoon;

  /// No description provided for @medsSlotEvening.
  ///
  /// In de, this message translates to:
  /// **'Abends'**
  String get medsSlotEvening;

  /// No description provided for @medsSlotNight.
  ///
  /// In de, this message translates to:
  /// **'Nachts'**
  String get medsSlotNight;

  /// No description provided for @medsSchemeHint.
  ///
  /// In de, this message translates to:
  /// **'Menge je Tageszeit. Leer oder 0 heißt: dann nichts einnehmen.'**
  String get medsSchemeHint;

  /// z.B. '1-0-1 (08:00, 18:00)'
  ///
  /// In de, this message translates to:
  /// **'{scheme} ({times})'**
  String medsSchemeSummary(String scheme, String times);

  /// No description provided for @medsSchemeEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte für mindestens eine Tageszeit eine Menge angeben.'**
  String get medsSchemeEmpty;

  /// No description provided for @medsHintsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einnahmehinweise'**
  String get medsHintsTitle;

  /// No description provided for @medsHintsExplainTitle.
  ///
  /// In de, this message translates to:
  /// **'Was bedeuten die Hinweise?'**
  String get medsHintsExplainTitle;

  /// No description provided for @medsHintsDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Allgemeine Erklärungen, keine ärztliche Beratung. Im Zweifel gilt der Beipackzettel oder die Aussage deiner Ärztin.'**
  String get medsHintsDisclaimer;

  /// No description provided for @medsHintsNoteLabel.
  ///
  /// In de, this message translates to:
  /// **'Eigene Anmerkung'**
  String get medsHintsNoteLabel;

  /// No description provided for @medsHintsNoteHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. mit der blauen Dose verwechselbar'**
  String get medsHintsNoteHint;

  /// No description provided for @medsHintFasting.
  ///
  /// In de, this message translates to:
  /// **'Auf nüchternen Magen'**
  String get medsHintFasting;

  /// No description provided for @medsHintFastingInfo.
  ///
  /// In de, this message translates to:
  /// **'Mindestens eine Stunde vor oder zwei Stunden nach dem Essen einnehmen. Nahrung im Magen würde die Aufnahme des Wirkstoffs stören.'**
  String get medsHintFastingInfo;

  /// No description provided for @medsHintWithFood.
  ///
  /// In de, this message translates to:
  /// **'Zum Essen'**
  String get medsHintWithFood;

  /// No description provided for @medsHintWithFoodInfo.
  ///
  /// In de, this message translates to:
  /// **'Während einer Mahlzeit einnehmen. Das schont den Magen und hilft bei Wirkstoffen, die mit Fett besser aufgenommen werden.'**
  String get medsHintWithFoodInfo;

  /// No description provided for @medsHintBeforeFood.
  ///
  /// In de, this message translates to:
  /// **'Vor dem Essen'**
  String get medsHintBeforeFood;

  /// No description provided for @medsHintBeforeFoodInfo.
  ///
  /// In de, this message translates to:
  /// **'Etwa 15 bis 30 Minuten vor der Mahlzeit einnehmen.'**
  String get medsHintBeforeFoodInfo;

  /// No description provided for @medsHintAfterFood.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Essen'**
  String get medsHintAfterFood;

  /// No description provided for @medsHintAfterFoodInfo.
  ///
  /// In de, this message translates to:
  /// **'Direkt im Anschluss an die Mahlzeit einnehmen.'**
  String get medsHintAfterFoodInfo;

  /// No description provided for @medsHintUpright.
  ///
  /// In de, this message translates to:
  /// **'Danach aufrecht bleiben'**
  String get medsHintUpright;

  /// No description provided for @medsHintUprightInfo.
  ///
  /// In de, this message translates to:
  /// **'Nach der Einnahme etwa 30 Minuten nicht hinlegen, damit die Tablette nicht in der Speiseröhre liegen bleibt.'**
  String get medsHintUprightInfo;

  /// No description provided for @medsHintWater.
  ///
  /// In de, this message translates to:
  /// **'Mit viel Wasser'**
  String get medsHintWater;

  /// No description provided for @medsHintWaterInfo.
  ///
  /// In de, this message translates to:
  /// **'Mit einem vollen Glas Wasser einnehmen, nicht mit Kaffee, Tee oder Saft.'**
  String get medsHintWaterInfo;

  /// No description provided for @medsHintNoDairy.
  ///
  /// In de, this message translates to:
  /// **'Nicht mit Milch'**
  String get medsHintNoDairy;

  /// No description provided for @medsHintNoDairyInfo.
  ///
  /// In de, this message translates to:
  /// **'Milch, Käse und Joghurt zwei Stunden vorher und nachher meiden: Kalzium kann den Wirkstoff binden.'**
  String get medsHintNoDairyInfo;

  /// No description provided for @medsHintNoAlcohol.
  ///
  /// In de, this message translates to:
  /// **'Kein Alkohol'**
  String get medsHintNoAlcohol;

  /// No description provided for @medsHintNoAlcoholInfo.
  ///
  /// In de, this message translates to:
  /// **'Während der Einnahme keinen Alkohol trinken.'**
  String get medsHintNoAlcoholInfo;

  /// No description provided for @medsHintAvoidSun.
  ///
  /// In de, this message translates to:
  /// **'Sonne meiden'**
  String get medsHintAvoidSun;

  /// No description provided for @medsHintAvoidSunInfo.
  ///
  /// In de, this message translates to:
  /// **'Die Haut reagiert empfindlicher auf Sonne. Direkte Sonne und Solarium meiden, Sonnenschutz verwenden.'**
  String get medsHintAvoidSunInfo;

  /// No description provided for @medsFormTablet.
  ///
  /// In de, this message translates to:
  /// **'Tablette'**
  String get medsFormTablet;

  /// No description provided for @medsFormCapsule.
  ///
  /// In de, this message translates to:
  /// **'Kapsel'**
  String get medsFormCapsule;

  /// No description provided for @medsFormDrop.
  ///
  /// In de, this message translates to:
  /// **'Tropfen'**
  String get medsFormDrop;

  /// No description provided for @medsFormSpray.
  ///
  /// In de, this message translates to:
  /// **'Spray'**
  String get medsFormSpray;

  /// No description provided for @medsFormInjection.
  ///
  /// In de, this message translates to:
  /// **'Spritze'**
  String get medsFormInjection;

  /// No description provided for @medsFormOintment.
  ///
  /// In de, this message translates to:
  /// **'Salbe'**
  String get medsFormOintment;

  /// No description provided for @medsFormOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get medsFormOther;

  /// Menge mit Form; amount ist die Eingabe des Nutzers (kann '0,5' sein)
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Tablette} other{{amount} Tabletten}}'**
  String medsDoseTablet(num count, String amount);

  /// No description provided for @medsDoseCapsule.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Kapsel} other{{amount} Kapseln}}'**
  String medsDoseCapsule(num count, String amount);

  /// No description provided for @medsDoseDrop.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Tropfen} other{{amount} Tropfen}}'**
  String medsDoseDrop(num count, String amount);

  /// No description provided for @medsDoseSpray.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Sprühstoß} other{{amount} Sprühstöße}}'**
  String medsDoseSpray(num count, String amount);

  /// No description provided for @medsDoseInjection.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Spritze} other{{amount} Spritzen}}'**
  String medsDoseInjection(num count, String amount);

  /// No description provided for @medsDoseOintment.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Anwendung} other{{amount} Anwendungen}}'**
  String medsDoseOintment(num count, String amount);

  /// No description provided for @medsDoseOther.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{{amount} Einheit} other{{amount} Einheiten}}'**
  String medsDoseOther(num count, String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
