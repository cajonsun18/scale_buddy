// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Scale Buddy';

  @override
  String get step2HeaderSubtitle => 'Schritt 2: Perspektive korrigieren';

  @override
  String get step2HeaderSemantics =>
      'Kopfbereich Schritt 2: Perspektive korrigieren';

  @override
  String get step3HeaderSubtitle => 'Schritt 3: Maßstab kalibrieren';

  @override
  String get step3HeaderSemantics =>
      'Kopfbereich Schritt 3: Maßstab kalibrieren';

  @override
  String get perspectiveInitial => 'Wähle eine Methode zur Entzerrung';

  @override
  String get perspectiveAutoDetected => '✨ Automatisch erkannt';

  @override
  String get perspectiveManualReady => '✓ 4 von 4 Ecken gesetzt – Bereit';

  @override
  String get perspectiveRectified => '✓ Perspektive entzerrt';

  @override
  String get perspectiveCornerTopLeft => 'Ecke 1 von 4 antippen (oben links)';

  @override
  String get perspectiveCornerTopRight => 'Ecke 2 von 4 antippen (oben rechts)';

  @override
  String get perspectiveCornerBottomRight =>
      'Ecke 3 von 4 antippen (unten rechts)';

  @override
  String get perspectiveCornerBottomLeft =>
      'Ecke 4 von 4 antippen (unten links)';

  @override
  String get perspectiveCornersAllSet => '4 von 4 Ecken gesetzt';

  @override
  String perspectiveManualStatusSemantics(int pointsCount, String helperText) {
    return 'Status: $pointsCount von 4 Ecken gesetzt. $helperText';
  }

  @override
  String get calibrationPhase1 => 'Tippe auf den 1. Referenzpunkt';

  @override
  String get calibrationPhase2 => 'Punkt 1 gesetzt – Tippe auf den 2. Punkt';

  @override
  String get calibrationPhase3 => '2 Punkte gesetzt – Reale Länge eingeben';

  @override
  String statusPrefix(String text) {
    return 'Status: $text';
  }

  @override
  String get step4HeaderSubtitle => 'Schritt 4: Messwerkzeuge';

  @override
  String get step4HeaderSemantics => 'Kopfbereich Schritt 4: Messwerkzeuge';

  @override
  String get measureStatusStart =>
      'Tippe auf das Bild, um die 1. Messung zu starten';

  @override
  String get measureToolDistance => 'Strecke';

  @override
  String get measureToolRectangle => 'Rechteck';

  @override
  String get measureToolPolygon => 'Polygon';

  @override
  String get measureToolAngle => 'Winkel';

  @override
  String get measureToolEdit => 'Edit';

  @override
  String get measureActionUndo => 'Rückgängig';

  @override
  String get measureActionExport => 'Weiter zu Schritt 5 (Export)';

  @override
  String measureStatusPoint1Set(String tool) {
    return '$tool: Punkt 1 gesetzt – Klicke auf Punkt 2';
  }

  @override
  String get measureStatusReadySingular =>
      '1 Messung erfasst • Bereit für Export';

  @override
  String measureStatusReadyPlural(int count) {
    return '$count Messungen erfasst • Bereit für Export';
  }

  @override
  String get measureActionDiscardPoint1 => 'Punkt 1 verwerfen';

  @override
  String get measureStartpointLabel => 'Startpunkt';

  @override
  String get measureTapPoint2Label => 'Tippe Punkt 2';

  @override
  String measureStatusPolygonPointsSet(int count) {
    return 'Polygon: $count Punkte gesetzt – Klicke Startpunkt zum Schließen';
  }

  @override
  String measureStatusElementSelected(String name, String type) {
    return 'Element ausgewählt: $name ($type)';
  }

  @override
  String get measureActionDelete => 'Löschen';

  @override
  String get measureActionDone => 'Fertig';

  @override
  String get measureInspectorLengthLabel => 'Länge';

  @override
  String get measureInspectorAreaLabel => 'Fläche';

  @override
  String get measureInspectorPerimeterLabel => 'Umfang';

  @override
  String get measureInspectorAngleLabel => 'Winkel';

  @override
  String measureTitleLine(Object identifier) {
    return '$identifier · Streckenlänge';
  }

  @override
  String measureTitleRectangle(Object identifier) {
    return '$identifier · Rechteckfläche';
  }

  @override
  String measureTitlePolygon(Object identifier) {
    return '$identifier · Polygonfläche';
  }

  @override
  String measureTitleAngle(Object identifier) {
    return '$identifier · Dachwinkel';
  }

  @override
  String get measureTypeCalibration => 'Kalibrierung';

  @override
  String get measureTypePerspective => 'Perspektive';

  @override
  String get measureTypeDistance => 'Strecke';

  @override
  String get measureTypeRectangle => 'Rechteck';

  @override
  String get measureTypePolygon => 'Polygon';

  @override
  String get measureTypeAngle => 'Dachwinkel';
}
