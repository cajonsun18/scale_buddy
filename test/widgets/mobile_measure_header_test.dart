import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/l10n/app_localizations.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/mobile_measure_header.dart';
import 'package:scale_buddy/widgets/mobile_step_header.dart';
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
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

  group('MobileMeasureHeader & MobileMeasureStatusPill Tests', () {
    testWidgets(
      'renders title, subtitle and dynamic scale highlighted in blue',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // 1000x1000 image, 200px distance = 2.0 m -> 100 px/m
        final mockImage = createMockImage(width: 1000, height: 1000);
        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.1),
          enteredDistance: 2.0,
          selectedUnit: 'm',
          isConfirmed: true,
        );

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MobileMeasureHeader), findsOneWidget);
        expect(find.text('Scale Buddy'), findsOneWidget);
        expect(find.text('Schritt 4: Messwerkzeuge'), findsOneWidget);
        expect(
          find.textContaining(
            'Tippe auf das Bild, um die 1. Messung zu starten',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('1 m = 100 px'), findsOneWidget);

        // Verify scale text color
        final textWidgetFinder = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan != null &&
              w.textSpan!.toPlainText().contains('1 m = 100 px'),
        );
        expect(textWidgetFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textWidgetFinder);
        final rootSpan = textWidget.textSpan! as TextSpan;
        final scaleSpan = rootSpan.children!.last as TextSpan;
        expect(scaleSpan.style?.color, const Color(0xFF38BDF8));
      },
    );

    testWidgets('hides header on desktop screens (>= 800 pt)', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: Scaffold(body: MobileMeasureHeader())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Schritt 4: Messwerkzeuge'), findsNothing);
      expect(find.text('Scale Buddy'), findsNothing);
    });

    testWidgets(
      'Zustand 2: shows point 1 placement status pill with blue border',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const openLine = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.3, 0.4),
          p2: null,
          color: Color(0xFF38BDF8),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [openLine],
        );

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Strecke: Punkt 1 gesetzt – Klicke auf Punkt 2'),
          findsOneWidget,
        );

        final pillContainer = tester.widget<MobileStatusPillContainer>(
          find.byType(MobileStatusPillContainer),
        );
        expect(pillContainer.borderColor, const Color(0xFF38BDF8));
      },
    );

    testWidgets(
      'Zustand 3: shows completed measurements status with emerald border',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const line = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.3, 0.4),
          p2: Offset(0.6, 0.4),
          color: Color(0xFF38BDF8),
        );
        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.3),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [line, rect],
        );

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('2 Messungen erfasst'), findsOneWidget);
        expect(find.textContaining('Bereit für Export'), findsOneWidget);

        final pillContainer = tester.widget<MobileStatusPillContainer>(
          find.byType(MobileStatusPillContainer),
        );
        expect(pillContainer.borderColor, const Color(0xFF10B981));
      },
    );

    testWidgets(
      'Zustand 4: shows selected element status pill with green accent',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.3, 0.3),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [rect],
          selectedEntityId: 'R1',
        );

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Element ausgewählt: F1 (Rechteck)'), findsOneWidget);

        final pillContainer = tester.widget<MobileStatusPillContainer>(
          find.byType(MobileStatusPillContainer),
        );
        expect(pillContainer.borderColor, const Color(0xFF10B981));
      },
    );
  });
}
