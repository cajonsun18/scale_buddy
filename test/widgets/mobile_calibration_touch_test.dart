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
import 'package:scale_buddy/tools/calibration_tool.dart';
import 'package:scale_buddy/widgets/calibration_input_widget.dart';
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
        67,
        74,
        150,
        0,
        0,
        1,
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
        84,
        69,
        85,
        174,
        66,
        96,
        130,
        91,
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

  group('Mobile Calibration Touch, Magnifier & Dimension Line Tests', () {
    testWidgets(
      'Test: Tippen auf das Bild platziert Punkt 1 und Punkt 2 mit jeweiligen Labels und aktualisiert Workflow-State',
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
            .setTool(const CalibrationTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Anfangszustand: initial (0 Punkte)
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.initial,
        );

        final center = tester.getCenter(find.byType(WorkspaceImageView));

        // 1. Punkt tippen
        await tester.tapAt(center + const Offset(-40, -40));
        await tester.pumpAndSettle();

        var state = container.read(workspaceControllerProvider);
        var calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
        expect(calib?.p1, isNotNull);
        expect(calib?.p2, isNull);
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.onePoint,
        );

        // Handle für Punkt 1 vorhanden (mit Mindest-Touch-Fläche 44x44 pt)
        final p1HandleFinder = find.byKey(
          const ValueKey('point_handle_calib_1_0'),
        );
        expect(p1HandleFinder, findsOneWidget);
        final p1Size = tester.getSize(p1HandleFinder);
        expect(p1Size.width, greaterThanOrEqualTo(44.0));
        expect(p1Size.height, greaterThanOrEqualTo(44.0));

        // 2. Punkt tippen
        await tester.tapAt(center + const Offset(40, 40));
        await tester.pumpAndSettle();

        state = container.read(workspaceControllerProvider);
        calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
        expect(calib?.p1, isNotNull);
        expect(calib?.p2, isNotNull);
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.twoPointsInput,
        );

        // Handle für Punkt 2 ebenfalls vorhanden
        final p2HandleFinder = find.byKey(
          const ValueKey('point_handle_calib_1_1'),
        );
        expect(p2HandleFinder, findsOneWidget);
        final p2Size = tester.getSize(p2HandleFinder);
        expect(p2Size.width, greaterThanOrEqualTo(44.0));
        expect(p2Size.height, greaterThanOrEqualTo(44.0));

        // Weiteres Tippen fügt keinen 3. Punkt hinzu
        await tester.tapAt(center);
        await tester.pumpAndSettle();
        final finalCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(finalCalib.p1, calib!.p1);
        expect(finalCalib.p2, calib.p2);
      },
    );

    testWidgets(
      'Test: Drag-Geste an einem Punkt aktiviert die 2.0x-Lupe mit vertikalem Offset',
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
            const DrawingEntity.calibration(
              id: 'calib_1',
              p1: Offset(0.3, 0.3),
              p2: Offset(0.7, 0.7),
            ),
          ],
        );
        container
            .read(activeToolProvider.notifier)
            .setTool(const CalibrationTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Lupe vor Berührung nicht sichtbar
        expect(find.byType(RawMagnifier), findsNothing);

        // Punkt 1 Handle finden
        final handle1 = find.byKey(const ValueKey('point_handle_calib_1_0'));
        expect(handle1, findsOneWidget);

        final point1ScreenPos = tester.getCenter(handle1);
        final gesture = await tester.startGesture(point1ScreenPos);
        await tester.pump();
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();

        // Lupe erscheint!
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Vergrößerung beträgt exakt 2.0x
        final rawMagnifier = tester.widget<RawMagnifier>(
          find.byType(RawMagnifier),
        );
        expect(rawMagnifier.magnificationScale, 2.0);

        // Position der Lupe: Schwebt mit vertikalem Versatz oberhalb des Berührungspunktes
        final magnifierRect = tester.getRect(find.byType(RawMagnifier));
        expect(magnifierRect.center.dy, lessThan(point1ScreenPos.dy));

        // Weiteres Ziehen hält Lupe aktiv
        await gesture.moveBy(const Offset(10, 10));
        await tester.pump();
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Finger loslassen
        await gesture.up();
        await tester.pumpAndSettle();

        // Lupe verschwindet flüssig
        expect(find.byType(RawMagnifier), findsNothing);

        // Koordinaten in der Entity wurden aktualisiert
        final updatedCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(updatedCalib.p1!.dx, isNot(closeTo(0.3, 0.001)));
      },
    );

    testWidgets(
      'Test: Vorhandensein von 2 Punkten rendert Bemaßungslinie & unterdrückt CalibrationInputWidget auf Mobilgeräten',
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
            const DrawingEntity.calibration(
              id: 'calib_1',
              p1: Offset(0.4, 0.2),
              p2: Offset(0.4, 0.8),
              enteredDistance: 2.10,
              selectedUnit: 'm',
            ),
          ],
        );
        container
            .read(activeToolProvider.notifier)
            .setTool(const CalibrationTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Auf Mobilgeräten wird das schwebende Desktop-Input-Widget auf dem Canvas ausgeblendet
        expect(find.byType(CalibrationInputWidget), findsNothing);

        // CustomPaint für Bemaßungslinie und Badge ist aktiv
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets(
      'Test: Auf Desktop (>= 800 dp) wird das CalibrationInputWidget auf dem Canvas angezeigt',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
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
            const DrawingEntity.calibration(
              id: 'calib_1',
              p1: Offset(0.4, 0.2),
              p2: Offset(0.4, 0.8),
            ),
          ],
        );
        container
            .read(activeToolProvider.notifier)
            .setTool(const CalibrationTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: false,
          ),
        );
        await tester.pumpAndSettle();

        // Auf Desktop ist das CalibrationInputWidget vorhanden
        expect(find.byType(CalibrationInputWidget), findsOneWidget);
      },
    );
  });
}
