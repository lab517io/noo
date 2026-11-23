/// The app's translations: how code reaches them, and which languages exist.
///
/// Strings live in `lib/l10n/app_<lang>.arb`; `app_en.arb` is the source and
/// `flutter gen-l10n` (run by every build, `generate: true`) turns them into
/// [AppLocalizations]. Two ways in:
///
/// - `context.l10n` in a widget. It falls back to [appL10n] when the tree has
///   no [AppLocalizations] — a widget test that builds its own `MaterialApp`
///   without the delegate gets English rather than a null check failing.
/// - [appL10n] where there is no `BuildContext`: an exception's `toString()`,
///   a provider's status message, the macOS menu bar (built above the
///   navigator). It follows the locale the app resolved; `NooApp` keeps it in
///   step through [updateAppLocale].
///
/// **Not translated**, because it is data rather than interface: text written
/// into the outline (a conflict copy's title syncs to devices in other
/// languages), the Obsidian export and CSV report formats, MCP tool
/// descriptions (read by agents), the sync log's decision codes, log lines,
/// and release notes.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Interface languages, each named in its own language, in the order the
/// Preferences list offers them. The keys are what `AppSettings.appLanguage`
/// stores; `''` (not listed) follows the system.
const Map<String, String> kAppLanguages = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'it': 'Italiano',
  'ru': 'Русский',
  'tr': 'Türkçe',
  'zh': '简体中文',
  'ja': '日本語',
};

/// The locale `MaterialApp.locale` should be given for a stored
/// `AppSettings.appLanguage`: null follows the system, as does a code the app
/// has no translation for.
Locale? appLocaleFor(String language) {
  if (language.isEmpty) return null;
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == language);
  return supported ? Locale(language) : null;
}

AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

/// The translations for the locale the app is showing, for code with no
/// `BuildContext`. English until the app has resolved its locale.
AppLocalizations get appL10n => _current;

/// Point [appL10n] and `Intl.defaultLocale` at [locale], the one the app
/// resolved. A locale with no translation falls back to English.
void updateAppLocale(Locale locale) {
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);
  final effective = supported ? Locale(locale.languageCode) : const Locale('en');
  _current = lookupAppLocalizations(effective);
  Intl.defaultLocale = effective.languageCode;
}

extension AppLocalizationsContext on BuildContext {
  /// The translations in scope here, or [appL10n] when none are.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? appL10n;
}

/// A duration with the interface language's short units — `2h 30m`,
/// `2 ч 30 мин`, `2時間30分` — split the way
/// `DurationFormatter.formatHuman` splits it (hours and minutes, or seconds
/// under a minute). That one stays English: the time report's text uses it.
String formatDurationShort(AppLocalizations l10n, Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return l10n.timeShortHoursMinutes(hours, minutes);
  }
  if (hours > 0) return l10n.timeShortHours(hours);
  if (minutes > 0) return l10n.timeShortMinutes(minutes);
  return l10n.timeShortSeconds(duration.inSeconds);
}
