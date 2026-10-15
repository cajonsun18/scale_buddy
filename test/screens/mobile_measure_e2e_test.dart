import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/l10n/app_localizations.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/painters/drawing_entity_painter.dart';
import 'package:scale_buddy/screens/main_layout_screen.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/tools/distance_tool.dart';
import 'package:scale_buddy/widgets/mobile_dock_components.dart';
import 'package:scale_buddy/widgets/mobile_measure_dock.dart';
import 'package:scale_buddy/widgets/mobile_measure_header.dart';
import 'package:scale_buddy/widgets/scale_buddy_app_bar.dart';
import 'package:scale_buddy/widgets/workflow_sidebar.dart';

void main() {
  LoadedImageInfo createMockImage({
    String fileName = 'test.png',
    int width = 800,
    int height = 600,
  }) {
    return LoadedImageInfo(
      fileName: fileName,
      fileSizeBytes: 58,
      bytes: Uint8List.fromList([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        11,
        73,
        68,
        65,
        84,
        8,
        215,
        99,
        74,
        150,
        0,
        0,
        1,
        1,
        1,
        0,
        24,
        221,
        141,
        178,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ]),
      width: width,
      height: height,
    );
  }

  Widget buildAppWithContainer(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: const MainLayoutScreen(),
      ),
    );
  }

  group('Mobile Measure Step 4 E2E Tests', () {
    testWidgets(
      'Mobile (< 800 pt) renders full-screen Step 4 with header and floating dock on dark background',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.3, 0.4),
          p2: Offset(0.3, 0.7),
          enteredDistance: 2.10,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);
        await tester.pumpAndSettle();

        // 1. Initial on mobile: Schritt 2 (Perspektive). Tap "Überspringen" to advance to Schritt 3 (Kalibrieren)
        expect(find.text('Überspringen'), findsOneWidget);
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();

        // 2. In Schritt 3: Calibration is confirmed (p1, p2, 2.10m). Tap "Weiter zu Schritt 4"
        expect(find.text('Weiter zu Schritt 4'), findsOneWidget);
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // 3. Now in Step 4 on Mobile!
        expect(find.byType(MobileMeasureHeader), findsOneWidget);
        expect(find.byType(MobileMeasureDock), findsOneWidget);
        expect(find.text('Scale Buddy'), findsOneWidget);
        expect(find.text('Schritt 4: Messwerkzeuge'), findsOneWidget);

        // Tool "Strecke" is active by default
        expect(find.text('Strecke'), findsOneWidget);
        expect(container.read(activeToolProvider), isA<DistanceTool>());

        // 0 measurements -> Export & Rückgängig are disabled
        final exportSemantics = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Weiter zu Schritt 5 (Export)' &&
              w.properties.enabled == false,
        );
        expect(exportSemantics, findsOneWidget);
      },
    );

    testWidgets(
      'Desktop (>= 800 pt) preserves desktop sidebar, toolbar and AppBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.3, 0.4),
          p2: Offset(0.3, 0.7),
          enteredDistance: 2.10,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        // Desktop elements are visible
        expect(find.byType(ScaleBuddyAppBar), findsOneWidget);
        expect(find.byType(WorkflowSidebar), findsOneWidget);

        // Mobile header and dock are NOT visible
        expect(find.byType(MobileMeasureHeader), findsNothing);
        expect(find.byType(MobileMeasureDock), findsNothing);
      },
    );

    testWidgets(
      'Calibration reference line from Step 3 is not visible on Canvas in Step 4 on mobile',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.2, 0.3),
          p2: Offset(0.2, 0.6),
          enteredDistance: 2.10,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);
        await tester.pumpAndSettle();

        // Advance from step 2 to step 3
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();

        // Advance from step 3 to step 4
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        expect(find.byType(MobileMeasureHeader), findsOneWidget);

        // Calibration line is not rendered in Step 4
        const painter = CalibrationPainter();
        expect(painter.isVisibleInStep(WorkflowStepType.measure), isFalse);
      },
    );

    testWidgets(
      '2-click distance measurement sequence: Point 1 set -> Discard -> Point 1 & 2 -> S1 label -> Undo',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.1), // 200 px = 2.0 m -> 100 px/m
          enteredDistance: 2.0,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);
        await tester.pumpAndSettle();

        // Advance to Step 4
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // Initial state 1: 0 measurements, export and undo disabled
        expect(
          find.textContaining(
            'Tippe auf das Bild, um die 1. Messung zu starten',
          ),
          findsOneWidget,
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final imageCenter = tester.getCenter(imageFinder);

        // 1. Click: Set Point 1 (without drag!)
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        // State 2: Guidance active!
        expect(find.text('▪ Startpunkt'), findsOneWidget);
        expect(find.text('Tippe Punkt 2'), findsOneWidget);
        expect(
          find.textContaining('Strecke: Punkt 1 gesetzt – Klicke auf Punkt 2'),
          findsOneWidget,
        );
        expect(find.text('Punkt 1 verwerfen'), findsOneWidget);

        // Discard point 1
        await tester.tap(find.text('Punkt 1 verwerfen'));
        await tester.pumpAndSettle();

        // Back to state 1!
        expect(find.text('▪ Startpunkt'), findsNothing);
        expect(find.text('Punkt 1 verwerfen'), findsNothing);
        expect(find.text('Rückgängig'), findsOneWidget);

        // 2. Click sequence again: Tap 1, then Tap 2 to complete distance
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        expect(find.text('▪ Startpunkt'), findsOneWidget);

        // Tap 2 at +100 px horizontally (1.00 m distance)
        await tester.tapAt(Offset(imageCenter.dx + 100, imageCenter.dy));
        await tester.pumpAndSettle();

        // State 3: Measurement completed!
        expect(find.textContaining('1 Messung erfasst'), findsOneWidget);
        expect(find.textContaining('Bereit für Export'), findsOneWidget);

        // Centered badge S1: ...
        expect(find.textContaining('S1:'), findsOneWidget);

        // Undo is active and Export button is active emerald green!
        final exportButton = tester.widget<MobileDockButton>(
          find.widgetWithText(MobileDockButton, 'Weiter zu Schritt 5 (Export)'),
        );
        expect(exportButton.backgroundColor, const Color(0xFF10B981));
        expect(exportButton.isPrimary, isTrue);

        // Tap Rückgängig -> removes measurement and reverts to state 1
        await tester.tap(find.text('Rückgängig'));
        await tester.pumpAndSettle();

        expect(find.textContaining('S1:'), findsNothing);
        expect(
          find.textContaining(
            'Tippe auf das Bild, um die 1. Messung zu starten',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2-click rectangle measurement sequence: Tap 1 -> Tap 2 diagonal -> Top edge and F1 area badge',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.1),
          enteredDistance: 2.0,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);
        await tester.pumpAndSettle();

        // Advance to Step 4
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // Select Rectangle Tool
        await tester.tap(find.text('Rechteck'));
        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        final imageCenter = tester.getCenter(imageFinder);

        // 1. Tap: Point 1
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Rechteck: Punkt 1 gesetzt – Klicke auf Punkt 2'),
          findsOneWidget,
        );
        expect(find.text('▪ Startpunkt'), findsOneWidget);
        expect(find.text('Punkt 1 verwerfen'), findsOneWidget);

        // 2. Tap: Diagonal corner (+100 px dx, +100 px dy)
        await tester.tapAt(Offset(imageCenter.dx + 100, imageCenter.dy + 100));
        await tester.pumpAndSettle();

        // State 3: Completed!
        expect(find.textContaining('1 Messung erfasst'), findsOneWidget);
        expect(find.textContaining('F1:'), findsOneWidget);

        // Export button is primary and active
        final exportButton = tester.widget<MobileDockButton>(
          find.widgetWithText(MobileDockButton, 'Weiter zu Schritt 5 (Export)'),
        );
        expect(exportButton.backgroundColor, const Color(0xFF10B981));
        expect(exportButton.isPrimary, isTrue);
      },
    );

    testWidgets(
      'Multi-click polygon measurement sequence: Tap 1 -> Discard -> Tap 1,2,3 -> Tap start to close -> P1 badge -> Undo',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.1),
          enteredDistance: 2.0,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);
        await tester.pumpAndSettle();

        // Advance to Step 4
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // Select Polygon Tool
        await tester.tap(find.text('Polygon'));
        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        final imageCenter = tester.getCenter(imageFinder);

        // 1. Tap: Point 1
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Polygon: Punkt 1 gesetzt – Klicke auf Punkt 2'),
          findsOneWidget,
        );
        expect(find.text('▪ Startpunkt'), findsOneWidget);
        expect(find.text('Punkt 1 verwerfen'), findsOneWidget);

        // Discard point 1
        await tester.tap(find.text('Punkt 1 verwerfen'));
        await tester.pumpAndSettle();

        expect(find.text('▪ Startpunkt'), findsNothing);
        expect(find.text('Punkt 1 verwerfen'), findsNothing);

        // Tap sequence for Triangle: Point 1, Point 2, Point 3, then Tap Point 1 to close
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        // Point 2 (+100 px horizontally)
        await tester.tapAt(Offset(imageCenter.dx + 100, imageCenter.dy));
        await tester.pumpAndSettle();

        // Point 3 (+50 px horizontally, +80 px vertically)
        await tester.tapAt(Offset(imageCenter.dx + 50, imageCenter.dy + 80));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Polygon: 3 Punkte gesetzt – Klicke Startpunkt zum Schließen',
          ),
          findsOneWidget,
        );

        // Tap start point to close polygon
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        // State 3: Measurement completed!
        expect(find.textContaining('1 Messung erfasst'), findsOneWidget);
        expect(find.textContaining('Bereit für Export'), findsOneWidget);
        expect(find.textContaining('P1:'), findsOneWidget);

        // Export button is active emerald green!
        final exportButton = tester.widget<MobileDockButton>(
          find.widgetWithText(MobileDockButton, 'Weiter zu Schritt 5 (Export)'),
        );
        expect(exportButton.backgroundColor, const Color(0xFF10B981));
        expect(exportButton.isPrimary, isTrue);

        // Tap Rückgängig -> removes polygon
        await tester.tap(find.text('Rückgängig'));
        await tester.pumpAndSettle();

        expect(find.textContaining('P1:'), findsNothing);
        expect(
          find.textContaining(
            'Tippe auf das Bild, um die 1. Messung zu starten',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2-click angle measurement sequence: Tap 1 -> Tap 2 along roof slope -> W1 badge -> Undo',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.1),
          enteredDistance: 2.0,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: [calib]);
        await tester.pumpAndSettle();

        // Advance to Step 4
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // Select Winkel Tool
        await tester.tap(find.text('Winkel'));
        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        final imageCenter = tester.getCenter(imageFinder);

        // 1. Tap: Scheitelpunkt
        await tester.tapAt(imageCenter);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Winkel: Punkt 1 gesetzt – Klicke auf Punkt 2'),
          findsOneWidget,
        );
        expect(find.text('▪ Startpunkt'), findsOneWidget);
        expect(find.text('Tippe Punkt 2'), findsOneWidget);
        expect(find.text('Punkt 1 verwerfen'), findsOneWidget);

        // 2. Tap: Along roof slope (+100 px dx, -20 px dy)
        await tester.tapAt(Offset(imageCenter.dx + 100, imageCenter.dy - 20));
        await tester.pumpAndSettle();

        // State 3: Measurement completed!
        expect(find.textContaining('1 Messung erfasst'), findsOneWidget);
        expect(find.textContaining('W1:'), findsOneWidget);

        // Export button is active emerald green!
        final exportButton = tester.widget<MobileDockButton>(
          find.widgetWithText(MobileDockButton, 'Weiter zu Schritt 5 (Export)'),
        );
        expect(exportButton.backgroundColor, const Color(0xFF10B981));
        expect(exportButton.isPrimary, isTrue);

        // Tap Rückgängig -> removes angle
        await tester.tap(find.text('Rückgängig'));
        await tester.pumpAndSettle();

        expect(find.textContaining('W1:'), findsNothing);
      },
    );

    testWidgets(
      'Multi-measurement counting in status pill: Line + Rect + Poly + Angle = 4 Messungen erfasst',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.1),
          enteredDistance: 2.0,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        const line = LineEntity(
          id: 'L1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.4, 0.2),
          color: Color(0xFF38BDF8),
        );
        const rect = RectangleEntity(
          id: 'R1',
          p1: Offset(0.5, 0.5),
          p2: Offset(0.7, 0.7),
          color: Color(0xFF10B981),
        );
        const poly = PolygonEntity(
          id: 'P1',
          points: [Offset(0.1, 0.5), Offset(0.3, 0.5), Offset(0.2, 0.8)],
          color: Color(0xFFA855F7),
          isClosed: true,
        );
        const angle = AngleEntity(
          id: 'A1',
          p1: Offset(0.1, 0.3),
          p2: Offset(0.3, 0.28),
          color: Color(0xFFF59E0B),
        );

        await tester.pumpWidget(buildAppWithContainer(container));
        await tester.pumpAndSettle();

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [calib, line, rect, poly, angle],
        );
        await tester.pumpAndSettle();

        // Advance to Step 4
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // All 4 measurements count into the status pill!
        expect(
          find.textContaining('4 Messungen erfasst • Bereit für Export'),
          findsOneWidget,
        );

        // All 4 badges visible
        expect(find.textContaining('S1:'), findsOneWidget);
        expect(find.textContaining('F1:'), findsOneWidget);
        expect(find.textContaining('P1:'), findsOneWidget);
        expect(find.textContaining('W1:'), findsOneWidget);
      },
    );
  });
}
