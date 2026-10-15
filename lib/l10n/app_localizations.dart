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

  /// Untertitel im Kopfbereich für Schritt 4
  ///
  /// In de, this message translates to:
  /// **'Schritt 4: Messwerkzeuge'**
  String get step4HeaderSubtitle;

  /// Screen-Reader-Label für den Header von Schritt 4
  ///
  /// In de, this message translates to:
  /// **'Kopfbereich Schritt 4: Messwerkzeuge'**
  String get step4HeaderSemantics;

  /// Statusmeldung für Zustand 1 der Messwerkzeuge
  ///
  /// In de, this message translates to:
  /// **'Tippe auf das Bild, um die 1. Messung zu starten'**
  String get measureStatusStart;

  /// Werkzeug-Label für Streckenmessung
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get measureToolDistance;

  /// Werkzeug-Label für Rechteckmessung
  ///
  /// In de, this message translates to:
  /// **'Rechteck'**
  String get measureToolRectangle;

  /// Werkzeug-Label für Polygonmessung
  ///
  /// In de, this message translates to:
  /// **'Polygon'**
  String get measureToolPolygon;

  /// Werkzeug-Label für Winkelmessung
  ///
  /// In de, this message translates to:
  /// **'Winkel'**
  String get measureToolAngle;

  /// Werkzeug-Label für Bearbeiten/Auswählen
  ///
  /// In de, this message translates to:
  /// **'Edit'**
  String get measureToolEdit;

  /// Aktion zum Rückgängigmachen der letzten Messung
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get measureActionUndo;

  /// Aktion zum Wechsel in den Export-Schritt
  ///
  /// In de, this message translates to:
  /// **'Weiter zu Schritt 5 (Export)'**
  String get measureActionExport;

  /// Statusmeldung für Zustand 2 der Messwerkzeuge wenn Punkt 1 gesetzt ist
  ///
  /// In de, this message translates to:
  /// **'{tool}: Punkt 1 gesetzt – Klicke auf Punkt 2'**
  String measureStatusPoint1Set(String tool);

  /// Statusmeldung wenn genau 1 Messung erfasst wurde
  ///
  /// In de, this message translates to:
  /// **'1 Messung erfasst • Bereit für Export'**
  String get measureStatusReadySingular;

  /// Statusmeldung wenn mehrere Messungen erfasst wurden
  ///
  /// In de, this message translates to:
  /// **'{count} Messungen erfasst • Bereit für Export'**
  String measureStatusReadyPlural(int count);

  /// Aktion zum Verwerfen des ersten gesetzten Punkts
  ///
  /// In de, this message translates to:
  /// **'Punkt 1 verwerfen'**
  String get measureActionDiscardPoint1;

  /// Label über dem Startpunkt
  ///
  /// In de, this message translates to:
  /// **'Startpunkt'**
  String get measureStartpointLabel;

  /// Label über dem Indikator für den 2. Punkt
  ///
  /// In de, this message translates to:
  /// **'Tippe Punkt 2'**
  String get measureTapPoint2Label;

  /// Statusmeldung wenn mehrere Punkte eines Polygons gesetzt wurden
  ///
  /// In de, this message translates to:
  /// **'Polygon: {count} Punkte gesetzt – Klicke Startpunkt zum Schließen'**
  String measureStatusPolygonPointsSet(int count);

  /// Statusmeldung für Zustand 4 wenn ein Element ausgewählt ist
  ///
  /// In de, this message translates to:
  /// **'Element ausgewählt: {name} ({type})'**
  String measureStatusElementSelected(String name, String type);

  /// Button zum Löschen des ausgewählten Elements
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get measureActionDelete;

  /// Button zum Abschließen der Bearbeitung
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get measureActionDone;

  /// No description provided for @measureInspectorLengthLabel.
  ///
  /// In de, this message translates to:
  /// **'Länge'**
  String get measureInspectorLengthLabel;

  /// No description provided for @measureInspectorAreaLabel.
  ///
  /// In de, this message translates to:
  /// **'Fläche'**
  String get measureInspectorAreaLabel;

  /// No description provided for @measureInspectorPerimeterLabel.
  ///
  /// In de, this message translates to:
  /// **'Umfang'**
  String get measureInspectorPerimeterLabel;

  /// No description provided for @measureInspectorAngleLabel.
  ///
  /// In de, this message translates to:
  /// **'Winkel'**
  String get measureInspectorAngleLabel;

  /// No description provided for @measureTitleLine.
  ///
  /// In de, this message translates to:
  /// **'{identifier} · Streckenlänge'**
  String measureTitleLine(Object identifier);

  /// No description provided for @measureTitleRectangle.
  ///
  /// In de, this message translates to:
  /// **'{identifier} · Rechteckfläche'**
  String measureTitleRectangle(Object identifier);

  /// No description provided for @measureTitlePolygon.
  ///
  /// In de, this message translates to:
  /// **'{identifier} · Polygonfläche'**
  String measureTitlePolygon(Object identifier);

  /// No description provided for @measureTitleAngle.
  ///
  /// In de, this message translates to:
  /// **'{identifier} · Dachwinkel'**
  String measureTitleAngle(Object identifier);

  /// No description provided for @measureTypeCalibration.
  ///
  /// In de, this message translates to:
  /// **'Kalibrierung'**
  String get measureTypeCalibration;

  /// No description provided for @measureTypePerspective.
  ///
  /// In de, this message translates to:
  /// **'Perspektive'**
  String get measureTypePerspective;

  /// No description provided for @measureTypeDistance.
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get measureTypeDistance;

  /// No description provided for @measureTypeRectangle.
  ///
  /// In de, this message translates to:
  /// **'Rechteck'**
  String get measureTypeRectangle;

  /// No description provided for @measureTypePolygon.
  ///
  /// In de, this message translates to:
  /// **'Polygon'**
  String get measureTypePolygon;

  /// No description provided for @measureTypeAngle.
  ///
  /// In de, this message translates to:
  /// **'Dachwinkel'**
  String get measureTypeAngle;
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
