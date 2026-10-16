import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_perspective_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/tools/perspective_tool.dart';
import 'package:scale_buddy/widgets/mobile_perspective_dock.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';

void main() {
  LoadedImageInfo createMockImage({String fileName = 'test.png'}) {
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
      width: 100,
      height: 100,
    );
  }

  Widget buildTestWidget({
    required ProviderContainer container,
    required WorkflowStepType activeStep,
    required bool isMobile,
    VoidCallback? onSkipOrNext,
    ValueChanged<WorkflowStepType>? onStepSelected,
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
            onStepSelected: onStepSelected,
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }

  group('MobilePerspectiveDock Widget & Integration Tests', () {
    testWidgets(
      'Zustand 1: Start-Auswahl zeigt Auto-Entzerrung, Manuell, Überspringen',
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
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Check buttons
        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
        expect(find.text('Manuell'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);

        // Not visible in Zustand 1
        expect(find.text('Zurücksetzen'), findsNothing);
        expect(find.text('Entzerren'), findsNothing);
        expect(find.text('Punkte anpassen'), findsNothing);
        expect(find.text('Weiter'), findsNothing);
      },
    );

    testWidgets(
      'Tipp auf "Manuell" schaltet in Zustand 2 (manuelle Erfassung) um',
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
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Tap "Manuell"
        await tester.tap(find.text('Manuell'));
        await tester.pumpAndSettle();

        // Active tool is PerspectiveTool
        expect(container.read(activeToolProvider), isA<PerspectiveTool>());

        // State is now manualInProgress
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.manualInProgress,
        );

        // Buttons in Zustand 2: Zurücksetzen, Entzerren (disabled), Überspringen
        expect(find.text('Zurücksetzen'), findsOneWidget);
        expect(find.text('Entzerren'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);
      },
    );

    testWidgets(
      'Zustand 2: "Entzerren" Button ist disabled (onPressed ist null)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            DrawingEntity.perspective(
              id: 'p1',
              points: const [Offset(0.1, 0.1), Offset(0.9, 0.1)],
              color: Colors.orange,
            ),
          ],
        );
        container
            .read(mobilePerspectiveStateProvider.notifier)
            .setManualInProgress();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Entzerren'), findsOneWidget);

        // Verify that the semantics or button indicates disabled
        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Entzerren' &&
              w.properties.enabled == false,
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Zustand 3: 4 Ecken bereit zeigt [Zurücksetzen], [Entzerren] aktiv, [Überspringen]',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            DrawingEntity.perspective(
              id: 'p1',
              points: const [
                Offset(0.1, 0.1),
                Offset(0.9, 0.1),
                Offset(0.9, 0.9),
                Offset(0.1, 0.9),
              ],
              color: Colors.orange,
            ),
          ],
        );
        container.read(mobilePerspectiveStateProvider.notifier).setReady();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Zurücksetzen'), findsOneWidget);
        expect(find.text('Entzerren'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);

        // Verify "Entzerren" is enabled
        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Entzerren' &&
              w.properties.enabled == true,
        );
        expect(semanticsFinder, findsOneWidget);

        // Klick auf "Zurücksetzen" kehrt zu Zustand 1 zurück
        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.initial,
        );
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
      },
    );

    testWidgets(
      'Zustand 4: Nach dem Entzerren zeigt [Punkte anpassen], [Zurücksetzen], [Weiter]',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final warpedImage = createMockImage(fileName: 'warped.png');
        final origImage = createMockImage(fileName: 'orig.png');

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: warpedImage,
          originalImage: origImage,
          preWarpEntities: [
            DrawingEntity.perspective(
              id: 'p1',
              points: const [
                Offset(0.1, 0.1),
                Offset(0.9, 0.1),
                Offset(0.9, 0.9),
                Offset(0.1, 0.9),
              ],
              color: Colors.orange,
            ),
          ],
        );
        container.read(mobilePerspectiveStateProvider.notifier).setRectified();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Punkte anpassen'), findsOneWidget);
        expect(find.text('Zurücksetzen'), findsOneWidget);
        expect(find.text('Weiter'), findsOneWidget);
        // "Überspringen" is hidden in Zustand 4
        expect(find.text('Überspringen'), findsNothing);
      },
    );

    testWidgets(
      'Tipp auf "Punkte anpassen" stellt Originalbild wieder her und kehrt zu Zustand 3 zurück',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final warpedImage = createMockImage(fileName: 'warped.png');
        final origImage = createMockImage(fileName: 'orig.png');

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: warpedImage,
          originalImage: origImage,
          preWarpEntities: [
            DrawingEntity.perspective(
              id: 'p1',
              points: const [
                Offset(0.1, 0.1),
                Offset(0.9, 0.1),
                Offset(0.9, 0.9),
                Offset(0.1, 0.9),
              ],
              color: Colors.orange,
            ),
          ],
        );
        container.read(mobilePerspectiveStateProvider.notifier).setRectified();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Punkte anpassen'));
        await tester.pumpAndSettle();

        final state = container.read(workspaceControllerProvider);
        expect(state.originalImage, isNull);
        expect(state.loadedImage?.fileName, 'orig.png');
        expect(
          state.entities.whereType<PerspectiveEntity>().first.points.length,
          4,
        );

        // State is ready4Points
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.ready4Points,
        );
      },
    );

    testWidgets(
      'Tipp auf "Zurücksetzen" aus Zustand 4 verwirft Bild und kehrt zu Zustand 1 zurück',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final warpedImage = createMockImage(fileName: 'warped.png');
        final origImage = createMockImage(fileName: 'orig.png');

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: warpedImage, originalImage: origImage);
        container.read(mobilePerspectiveStateProvider.notifier).setRectified();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        final state = container.read(workspaceControllerProvider);
        expect(state.originalImage, isNull);
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.initial,
        );
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
      },
    );

    testWidgets(
      'Tipp auf "Überspringen" oder "Weiter" wechselt zu Schritt 3 (Kalibrieren)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        WorkflowStepType? navigatedStep;

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
            onStepSelected: (step) {
              navigatedStep = step;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();

        expect(navigatedStep, WorkflowStepType.calibrate);
      },
    );
  });
}
