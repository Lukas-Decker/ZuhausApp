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
