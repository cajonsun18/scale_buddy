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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// Name der Anwendung
  ///
  /// In de, this message translates to:
  /// **'Scale Buddy'**
  String get appName;

  /// Untertitel im Kopfbereich für Schritt 2
  ///
  /// In de, this message translates to:
  /// **'Schritt 2: Perspektive korrigieren'**
  String get step2HeaderSubtitle;

  /// Screen-Reader-Label für den Header von Schritt 2
  ///
  /// In de, this message translates to:
  /// **'Kopfbereich Schritt 2: Perspektive korrigieren'**
  String get step2HeaderSemantics;

  /// Untertitel im Kopfbereich für Schritt 3
  ///
  /// In de, this message translates to:
  /// **'Schritt 3: Maßstab kalibrieren'**
  String get step3HeaderSubtitle;

  /// Screen-Reader-Label für den Header von Schritt 3
  ///
  /// In de, this message translates to:
  /// **'Kopfbereich Schritt 3: Maßstab kalibrieren'**
  String get step3HeaderSemantics;

  /// Statusmeldung vor Beginn der Entzerrung
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Methode zur Entzerrung'**
  String get perspectiveInitial;

  /// Statusmeldung nach automatischer Eckenerkennung
  ///
  /// In de, this message translates to:
  /// **'✨ Automatisch erkannt'**
  String get perspectiveAutoDetected;

  /// Statusmeldung nach manuellem Setzen aller 4 Ecken
  ///
  /// In de, this message translates to:
  /// **'✓ 4 von 4 Ecken gesetzt – Bereit'**
  String get perspectiveManualReady;

  /// Statusmeldung nach erfolgreicher Entzerrung
  ///
  /// In de, this message translates to:
  /// **'✓ Perspektive entzerrt'**
  String get perspectiveRectified;

  /// Hilfetext für die erste Ecke
  ///
  /// In de, this message translates to:
  /// **'Ecke 1 von 4 antippen (oben links)'**
  String get perspectiveCornerTopLeft;

  /// Hilfetext für die zweite Ecke
  ///
  /// In de, this message translates to:
  /// **'Ecke 2 von 4 antippen (oben rechts)'**
  String get perspectiveCornerTopRight;

  /// Hilfetext für die dritte Ecke
  ///
  /// In de, this message translates to:
  /// **'Ecke 3 von 4 antippen (unten rechts)'**
  String get perspectiveCornerBottomRight;

  /// Hilfetext für die vierte Ecke
  ///
  /// In de, this message translates to:
  /// **'Ecke 4 von 4 antippen (unten links)'**
  String get perspectiveCornerBottomLeft;

  /// Hilfetext wenn alle 4 Ecken gesetzt sind
  ///
  /// In de, this message translates to:
  /// **'4 von 4 Ecken gesetzt'**
  String get perspectiveCornersAllSet;

  /// Screen-Reader-Status beim schrittweisen Setzen der Ecken
  ///
  /// In de, this message translates to:
  /// **'Status: {pointsCount} von 4 Ecken gesetzt. {helperText}'**
  String perspectiveManualStatusSemantics(int pointsCount, String helperText);

  /// Statusmeldung für Phase 1 der Kalibrierung
  ///
  /// In de, this message translates to:
  /// **'Tippe auf den 1. Referenzpunkt'**
  String get calibrationPhase1;

  /// Statusmeldung für Phase 2 der Kalibrierung
  ///
  /// In de, this message translates to:
  /// **'Punkt 1 gesetzt – Tippe auf den 2. Punkt'**
  String get calibrationPhase2;

  /// Statusmeldung für Phase 3 der Kalibrierung
  ///
  /// In de, this message translates to:
  /// **'2 Punkte gesetzt – Reale Länge eingeben'**
  String get calibrationPhase3;

  /// Präfix für Screen-Reader-Statusmeldungen
  ///
  /// In de, this message translates to:
  /// **'Status: {text}'**
  String statusPrefix(String text);
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
