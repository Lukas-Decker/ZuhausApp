import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_de.dart';

/// Kurzer Weg zu den übersetzten Texten in Widgets: `context.l10n.commonSave`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Texte für Code ohne BuildContext.
///
/// Benachrichtigungen, Dienste und Hintergrundarbeiten haben keinen
/// BuildContext, brauchen aber dieselben Texte. In `main()` wird einmal die
/// passende Sprache geladen; bis dahin gilt Deutsch als Quellsprache.
abstract final class AppTexts {
  static AppLocalizations _current = AppLocalizationsDe();

  static AppLocalizations get current => _current;

  static Future<void> load(Locale locale) async {
    _current = await AppLocalizations.delegate.load(locale);
  }
}
