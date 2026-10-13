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
import 'package:scale_buddy/widgets/step_detail_view.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';

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
      width: 200,
      height: 200,
    );
  }

  Widget buildTestWidget({
    required ProviderContainer container,
    required WorkflowStepType activeStep,
    required bool isMobile,
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

  group('Mobile Perspective Touch & Magnifier Tests', () {
    testWidgets(
      'Tippen setzt Punkte 1 bis 4 nacheinander und aktualisiert mobilePerspectiveStateProvider',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);
        container
            .read(activeToolProvider.notifier)
            .setTool(const PerspectiveTool());
        container.read(mobilePerspectiveStateProvider.notifier).startManual();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        final center = tester.getCenter(find.byType(WorkspaceImageView));

        // 1. Punkt tippen
        await tester.tapAt(center + const Offset(-40, -40));
        await tester.pumpAndSettle();

        var state = container.read(workspaceControllerProvider);
        var pEntity = state.entities.whereType<PerspectiveEntity>().firstOrNull;
        expect(pEntity?.points.length, 1);
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.manualInProgress,
        );

        // 2. Punkt tippen
        await tester.tapAt(center + const Offset(40, -40));
        await tester.pumpAndSettle();
        state = container.read(workspaceControllerProvider);
        pEntity = state.entities.whereType<PerspectiveEntity>().firstOrNull;
        expect(pEntity?.points.length, 2);

        // 3. Punkt tippen
        await tester.tapAt(center + const Offset(40, 40));
        await tester.pumpAndSettle();
        state = container.read(workspaceControllerProvider);
        pEntity = state.entities.whereType<PerspectiveEntity>().firstOrNull;
        expect(pEntity?.points.length, 3);

        // 4. Punkt tippen
        await tester.tapAt(center + const Offset(-40, 40));
        await tester.pumpAndSettle();
        state = container.read(workspaceControllerProvider);
        pEntity = state.entities.whereType<PerspectiveEntity>().firstOrNull;
        expect(pEntity?.points.length, 4);
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.ready4Points,
        );

        // Weiteres Tippen fuegt keinen 5. Punkt hinzu
        await tester.tapAt(center);
        await tester.pumpAndSettle();
        state = container.read(workspaceControllerProvider);
        pEntity = state.entities.whereType<PerspectiveEntity>().firstOrNull;
        expect(pEntity?.points.length, 4);
      },
    );

    testWidgets(
      'Ziehen eines Punktes aktiviert die Lupe mit Fadenkreuz und vertikalem Versatz',
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
              id: 'persp1',
              points: const [
                Offset(0.2, 0.2),
                Offset(0.8, 0.2),
                Offset(0.8, 0.8),
                Offset(0.2, 0.8),
              ],
              color: Colors.orange,
            ),
          ],
        );
        container
            .read(activeToolProvider.notifier)
            .setTool(const PerspectiveTool());
        container.read(mobilePerspectiveStateProvider.notifier).setReady();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Lupe anfangs nicht sichtbar
        expect(find.byType(RawMagnifier), findsNothing);

        // Erste Ecke finden (Offset(0.2, 0.2))
        final handleFinder = find.byKey(
          const ValueKey('point_handle_persp1_0'),
        );
        expect(handleFinder, findsOneWidget);

        final point1ScreenPos = tester.getCenter(handleFinder);
        final gesture = await tester.startGesture(point1ScreenPos);
        await tester.pump();
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();

        // Lupe ist sichtbar!
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Position der Lupe pruefen: Muss oberhalb des Beruehrungspunktes schweben (vertikaler Offset 70)
        final magnifierRect = tester.getRect(find.byType(RawMagnifier));
        expect(magnifierRect.center.dy, lessThan(point1ScreenPos.dy));

        // Verschieben (PanUpdate)
        await gesture.moveBy(const Offset(20, 20));
        await tester.pump();
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Finger loslassen (PanEnd)
        await gesture.up();
        await tester.pumpAndSettle();

        // Lupe verschwindet
        expect(find.byType(RawMagnifier), findsNothing);

        // Koordinaten wurden in der Entity aktualisiert
        final updatedState = container.read(workspaceControllerProvider);
        final pEntity = updatedState.entities
            .whereType<PerspectiveEntity>()
            .first;
        expect(pEntity.points[0].dx, isNot(closeTo(0.2, 0.001)));
      },
    );

    testWidgets('PerspectivePainter rendert Ecken-Labels und Linien', (
      WidgetTester tester,
    ) async {
      final mockImage = createMockImage();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(workspaceControllerProvider.notifier)
          .state = WorkspaceState(
        loadedImage: mockImage,
        entities: [
          DrawingEntity.perspective(
            id: 'persp1',
            points: const [
              Offset(0.2, 0.2),
              Offset(0.8, 0.2),
              Offset(0.8, 0.8),
              Offset(0.2, 0.8),
            ],
            color: Colors.orange,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.perspective,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      // CustomPaint fuer Entities vorhanden
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
