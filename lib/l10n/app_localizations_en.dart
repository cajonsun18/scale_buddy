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

  @override
  String get step4HeaderSubtitle => 'Step 4: Measuring tools';

  @override
  String get step4HeaderSemantics => 'Header area step 4: Measuring tools';

  @override
  String get measureStatusStart =>
      'Tap on the image to start the 1st measurement';

  @override
  String get measureToolDistance => 'Distance';

  @override
  String get measureToolRectangle => 'Rectangle';

  @override
  String get measureToolPolygon => 'Polygon';

  @override
  String get measureToolAngle => 'Angle';

  @override
  String get measureToolEdit => 'Edit';

  @override
  String get measureActionUndo => 'Undo';

  @override
  String get measureActionExport => 'Continue to Step 5 (Export)';

  @override
  String measureStatusPoint1Set(String tool) {
    return '$tool: Point 1 set – Click on point 2';
  }

  @override
  String get measureStatusReadySingular =>
      '1 measurement recorded • Ready for export';

  @override
  String measureStatusReadyPlural(int count) {
    return '$count measurements recorded • Ready for export';
  }

  @override
  String get measureActionDiscardPoint1 => 'Discard Point 1';

  @override
  String get measureStartpointLabel => 'Start point';

  @override
  String get measureTapPoint2Label => 'Tap point 2';

  @override
  String measureStatusPolygonPointsSet(int count) {
    return 'Polygon: $count points placed – Tap start to close';
  }

  @override
  String measureStatusElementSelected(String name, String type) {
    return 'Element selected: $name ($type)';
  }

  @override
  String get measureActionDelete => 'Delete';

  @override
  String get measureActionDone => 'Done';

  @override
  String get measureInspectorLengthLabel => 'Length';

  @override
  String get measureInspectorAreaLabel => 'Area';

  @override
  String get measureInspectorPerimeterLabel => 'Perimeter';

  @override
  String get measureInspectorAngleLabel => 'Angle';

  @override
  String measureTitleLine(Object identifier) {
    return '$identifier · Line length';
  }

  @override
  String measureTitleRectangle(Object identifier) {
    return '$identifier · Rectangle area';
  }

  @override
  String measureTitlePolygon(Object identifier) {
    return '$identifier · Polygon area';
  }

  @override
  String measureTitleAngle(Object identifier) {
    return '$identifier · Roof angle';
  }

  @override
  String get measureTypeCalibration => 'Calibration';

  @override
  String get measureTypePerspective => 'Perspective';

  @override
  String get measureTypeDistance => 'Distance';

  @override
  String get measureTypeRectangle => 'Rectangle';

  @override
  String get measureTypePolygon => 'Polygon';

  @override
  String get measureTypeAngle => 'Roof angle';
}
