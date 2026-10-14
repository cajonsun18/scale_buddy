// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Scale Buddy';

  @override
  String get step2HeaderSubtitle => 'Step 2: Correct perspective';

  @override
  String get step2HeaderSemantics => 'Header area step 2: Correct perspective';

  @override
  String get step3HeaderSubtitle => 'Step 3: Calibrate scale';

  @override
  String get step3HeaderSemantics => 'Header area step 3: Calibrate scale';

  @override
  String get perspectiveInitial => 'Select a rectification method';

  @override
  String get perspectiveAutoDetected => '✨ Automatically detected';

  @override
  String get perspectiveManualReady => '✓ 4 of 4 corners set – Ready';

  @override
  String get perspectiveRectified => '✓ Perspective rectified';

  @override
  String get perspectiveCornerTopLeft => 'Tap corner 1 of 4 (top left)';

  @override
  String get perspectiveCornerTopRight => 'Tap corner 2 of 4 (top right)';

  @override
  String get perspectiveCornerBottomRight => 'Tap corner 3 of 4 (bottom right)';

  @override
  String get perspectiveCornerBottomLeft => 'Tap corner 4 of 4 (bottom left)';

  @override
  String get perspectiveCornersAllSet => '4 of 4 corners set';

  @override
  String perspectiveManualStatusSemantics(int pointsCount, String helperText) {
    return 'Status: $pointsCount of 4 corners set. $helperText';
  }

  @override
  String get calibrationPhase1 => 'Tap on the 1st reference point';

  @override
  String get calibrationPhase2 => 'Point 1 set – Tap on the 2nd point';

  @override
  String get calibrationPhase3 => '2 points set – Enter real length';

  @override
  String statusPrefix(String text) {
    return 'Status: $text';
  }
}
