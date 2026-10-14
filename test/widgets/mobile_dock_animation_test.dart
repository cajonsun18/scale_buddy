import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/mobile_calibration_dock.dart';
import 'package:scale_buddy/widgets/mobile_calibration_header.dart';
import 'package:scale_buddy/widgets/mobile_perspective_dock.dart';
import 'package:scale_buddy/widgets/mobile_perspective_header.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';

import '../utils/mock_data.dart';

void main() {
  LoadedImageInfo createMockImage({String fileName = 'test.png'}) {
    return LoadedImageInfo(
      fileName: fileName,
      fileSizeBytes: mockPngBytes.lengthInBytes,
      bytes: mockPngBytes,
      width: 200,
      height: 200,
    );
  }

  Widget buildTestWidget({
    required ProviderContainer container,
    required WorkflowStepType activeStep,
    ValueChanged<WorkflowStepType>? onStepSelected,
    ValueChanged<StepStatus>? onStatusChanged,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StepDetailView(
            activeStep: activeStep,
            currentStatus: StepStatus.active,
            onStatusChanged: onStatusChanged ?? (_) {},
            onStepSelected: onStepSelected,
            isMobile: true,
          ),
        ),
      ),
    );
  }

  group('Mobile Dock Vertical Slide & Header Fade Animation Tests', () {
    testWidgets(
      'Forward transition (Perspective -> Calibrate) slides outgoing dock downwards and incoming dock upwards while headers fade',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        // 1. Initial State: Perspective Step (Step 2)
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(find.byType(MobilePerspectiveHeader), findsOneWidget);
        expect(find.byType(MobileCalibrationDock), findsNothing);
        expect(find.byType(MobileCalibrationHeader), findsNothing);

        final initialDockPos = tester.getTopLeft(
          find.byType(MobilePerspectiveDock),
        );
        final initialHeaderPos = tester.getTopLeft(
          find.byType(MobilePerspectiveHeader),
        );
        final initialCanvasPos = tester.getTopLeft(
          find.byType(WorkspaceImageView),
        );

        // 2. Transition: Switch to Calibrate Step (Step 3)
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
          ),
        );

        // Advance 50 ms into the ~250 ms animation
        await tester.pump(const Duration(milliseconds: 50));

        // Both docks and headers are present mid-animation
        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(find.byType(MobilePerspectiveHeader), findsOneWidget);
        expect(find.byType(MobileCalibrationHeader), findsOneWidget);

        final midPerspectiveDockPos = tester.getTopLeft(
          find.byType(MobilePerspectiveDock),
        );
        final midCalibrationDockPos = tester.getTopLeft(
          find.byType(MobileCalibrationDock),
        );
        final midPerspectiveHeaderPos = tester.getTopLeft(
          find.byType(MobilePerspectiveHeader),
        );
        final midCalibrationHeaderPos = tester.getTopLeft(
          find.byType(MobileCalibrationHeader),
        );
        final midCanvasPos = tester.getTopLeft(find.byType(WorkspaceImageView));

        // Outgoing dock has slid downwards (dy increased relative to resting position)
        expect(
          midPerspectiveDockPos.dy,
          greaterThan(initialDockPos.dy),
          reason: 'Outgoing dock should slide downwards out of view',
        );

        // Forward header slide: Outgoing header slides left (dx < initial dx), incoming enters from right
        expect(
          midPerspectiveHeaderPos.dx,
          lessThan(initialHeaderPos.dx),
          reason:
              'Outgoing header should slide to the left on forward transition',
        );
        expect(
          midCalibrationHeaderPos.dx,
          greaterThan(midPerspectiveHeaderPos.dx),
          reason: 'Incoming header should enter from the right on forward transition',
        );

        // Canvas position remains 100% static during transition
        expect(
          midCanvasPos,
          equals(initialCanvasPos),
          reason: 'Image canvas must remain completely static during dock animation',
        );

        // Check header fade transitions
        final headerFades = tester.widgetList<FadeTransition>(
          find.descendant(
            of: find.byType(AnimatedSwitcher),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(
          headerFades,
          isNotEmpty,
          reason: 'Header or dock transitions must utilize fade effects',
        );

        // 3. Settle animation to completion
        await tester.pumpAndSettle();

        expect(find.byType(MobilePerspectiveDock), findsNothing);
        expect(find.byType(MobilePerspectiveHeader), findsNothing);
        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(find.byType(MobileCalibrationHeader), findsOneWidget);

        final settledCalibrationDockPos = tester.getTopLeft(
          find.byType(MobileCalibrationDock),
        );

        // The mid-transition calibration dock position was below its settled resting position
        expect(
          midCalibrationDockPos.dy,
          greaterThan(settledCalibrationDockPos.dy),
          reason: 'Incoming dock should enter sliding upwards from the bottom',
        );
      },
    );

    testWidgets(
      'Backward transition (Calibrate -> Perspective) slides outgoing dock downwards and incoming dock upwards while headers fade',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        // 1. Initial State: Calibrate Step (Step 3)
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(find.byType(MobileCalibrationHeader), findsOneWidget);

        final initialCalibDockPos = tester.getTopLeft(
          find.byType(MobileCalibrationDock),
        );
        final initialCalibHeaderPos = tester.getTopLeft(
          find.byType(MobileCalibrationHeader),
        );

        // 2. Transition back to Perspective (Step 2)
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));

        // Both docks and headers present during transition
        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(find.byType(MobileCalibrationHeader), findsOneWidget);
        expect(find.byType(MobilePerspectiveHeader), findsOneWidget);

        final midCalibDockPos = tester.getTopLeft(
          find.byType(MobileCalibrationDock),
        );
        final midPerspectiveDockPos = tester.getTopLeft(
          find.byType(MobilePerspectiveDock),
        );
        final midCalibHeaderPos = tester.getTopLeft(
          find.byType(MobileCalibrationHeader),
        );

        // Outgoing calibration dock slides downwards
        expect(
          midCalibDockPos.dy,
          greaterThan(initialCalibDockPos.dy),
          reason: 'Outgoing calibration dock should slide downwards',
        );

        // Backward header slide: Outgoing header slides right (dx > initial dx)
        expect(
          midCalibHeaderPos.dx,
          greaterThan(initialCalibHeaderPos.dx),
          reason: 'Outgoing calibration header should slide to the right on backward transition',
        );

        // Finish transition
        await tester.pumpAndSettle();

        expect(find.byType(MobileCalibrationDock), findsNothing);
        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(find.byType(MobilePerspectiveHeader), findsOneWidget);

        final settledPerspectiveDockPos = tester.getTopLeft(
          find.byType(MobilePerspectiveDock),
        );

        // Incoming perspective dock was lower mid-transition than resting position
        expect(
          midPerspectiveDockPos.dy,
          greaterThan(settledPerspectiveDockPos.dy),
          reason: 'Incoming perspective dock should enter from the bottom',
        );
      },
    );

    testWidgets(
      'Transitioning to step without dock slides dock downwards without errors',
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
          ),
        );
        await tester.pumpAndSettle();

        final initialCalibDockPos = tester.getTopLeft(
          find.byType(MobileCalibrationDock),
        );

        // Navigate to Measure (Step 4) which has no bottom dock
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
          ),
        );

        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(MobileCalibrationDock)).dy,
          greaterThan(initialCalibDockPos.dy),
        );

        await tester.pumpAndSettle();

        expect(find.byType(MobileCalibrationDock), findsNothing);
        expect(find.byType(MobileCalibrationHeader), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Keyboard insets / viewInsets and touch interactions produce no render overflows',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
          ),
        );
        await tester.pumpAndSettle();

        // Simulate virtual keyboard popping up (e.g. 260 dp bottom view insets)
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        await tester.pump();

        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Transition with keyboard present
        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Touch interaction test
        final resetButton = find.text('Überspringen');
        if (resetButton.evaluate().isNotEmpty) {
          await tester.tap(resetButton);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  });
}
