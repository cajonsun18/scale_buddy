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
}
