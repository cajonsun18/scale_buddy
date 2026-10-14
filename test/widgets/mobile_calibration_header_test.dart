import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_calibration_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/mobile_calibration_header.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';

void main() {
  LoadedImageInfo createMockImage({
    String fileName = 'test.png',
    int width = 1000,
    int height = 1000,
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

  Widget buildTestWidget({
    required ProviderContainer container,
    required WorkflowStepType activeStep,
    required bool isMobile,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StepDetailView(
            activeStep: activeStep,
            currentStatus: StepStatus.active,
            onStatusChanged: (_) {},
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }

  group('MobileCalibrationHeader & MobileCalibrationStatusPill', () {
    testWidgets(
      'Mobile calibration header renders typography correctly (< 800 dp)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Header titles
        expect(find.text('Scale Buddy'), findsOneWidget);
        expect(find.text('Schritt 3: Maßstab kalibrieren'), findsOneWidget);

        // Header Semantics
        final headerSemantics = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Kopfbereich Schritt 3: Maßstab kalibrieren',
        );
        expect(headerSemantics, findsOneWidget);

        // Verify typography styling of title and subtitle
        final titleText = tester.widget<Text>(find.text('Scale Buddy'));
        expect(titleText.style?.color, Colors.white);
        expect(titleText.style?.fontWeight, FontWeight.bold);

        final subtitleText = tester.widget<Text>(
          find.text('Schritt 3: Maßstab kalibrieren'),
        );
        expect(subtitleText.style?.color, const Color(0xFF94A3B8));
      },
    );

    testWidgets('Status-Pille Phase 1: Start (0 Punkte)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage);

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.calibrate,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Status: Tippe auf den 1. Referenzpunkt',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Status-Pille Phase 2: Punkt 1 gesetzt (● ○)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      const entity = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.2, 0.2),
      );

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage, entities: [entity]);

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.calibrate,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Punkt 1 gesetzt – Tippe auf den 2. Punkt'),
        findsOneWidget,
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Status: Punkt 1 gesetzt – Tippe auf den 2. Punkt',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Status-Pille Phase 3: 2 Punkte gesetzt & Eingabe (● ●)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      const entity = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.2, 0.2),
        p2: Offset(0.8, 0.2),
        isConfirmed: false,
      );

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage, entities: [entity]);

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.calibrate,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('2 Punkte gesetzt – Reale Länge eingeben'),
        findsOneWidget,
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Status: 2 Punkte gesetzt – Reale Länge eingeben',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
      'Status-Pille Phase 4: Erfolgreich kalibriert mit dynamischem Maßstabsfaktor (m)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage(width: 1000, height: 1000);
        // distance: 207.9 px, 2.10 m -> 99 px/m
        const entity = DrawingEntity.calibration(
          id: 'calib_1',
          p1: Offset(0.2, 0.5),
          p2: Offset(0.4079, 0.5),
          enteredDistance: 2.10,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [entity]);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('✓ Maßstab kalibriert: 1 m = 99 px'), findsOneWidget);

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Status: ✓ Maßstab kalibriert: 1 m = 99 px',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Status-Pille Phase 4: Erfolgreich kalibriert mit gewählter Einheit cm',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage(width: 1000, height: 1000);
        // distance: 500 px, 50.0 cm -> 10 px/cm
        const entity = DrawingEntity.calibration(
          id: 'calib_1',
          p1: Offset(0.1, 0.5),
          p2: Offset(0.6, 0.5),
          enteredDistance: 50.0,
          selectedUnit: 'cm',
          isConfirmed: true,
        );

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [entity]);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('✓ Maßstab kalibriert: 1 cm = 10 px'), findsOneWidget);

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Status: ✓ Maßstab kalibriert: 1 cm = 10 px',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Desktop-Modus (>= 800 dp) rendert den mobilen Kalibrierungs-Header NICHT',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MobileCalibrationHeader), findsNothing);
        expect(find.byType(MobileCalibrationStatusPill), findsNothing);
      },
    );

    testWidgets(
      'Direct rendering of MobileCalibrationHeader on desktop (>= 800 dp) returns SizedBox.shrink',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: MobileCalibrationHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scale Buddy'), findsNothing);
        expect(find.text('Schritt 3: Maßstab kalibrieren'), findsNothing);
        expect(find.byType(MobileCalibrationStatusPill), findsNothing);
      },
    );

    testWidgets(
      'Reaktive Zustandsaktualisierung über mobileCalibrationStateProvider',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);

        container.read(mobileCalibrationStateProvider.notifier).setOnePoint();
        await tester.pumpAndSettle();
        expect(
          find.text('Punkt 1 gesetzt – Tippe auf den 2. Punkt'),
          findsOneWidget,
        );

        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();
        await tester.pumpAndSettle();
        expect(
          find.text('2 Punkte gesetzt – Reale Länge eingeben'),
          findsOneWidget,
        );
      },
    );
  });
}
