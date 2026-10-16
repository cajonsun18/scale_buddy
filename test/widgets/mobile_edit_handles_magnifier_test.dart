import 'dart:typed_data';
import 'dart:ui';

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
import 'package:scale_buddy/tools/select_tool.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';

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
        98,
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
        home: Scaffold(body: WorkspaceImageView(activeStep: activeStep)),
      ),
    );
  }

  group('Mobile Edit Handles & Magnifier Tests', () {
    testWidgets(
      'When rectangle is selected in measure step, 4 handles appear with >= 44x44 pt interaction area',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.6, 0.6),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [rect],
          selectedEntityId: 'R1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // 4 Handles for rectangle corners (0, 1, 2, 3)
        for (int i = 0; i < 4; i++) {
          final handleFinder = find.byKey(ValueKey('point_handle_R1_$i'));
          expect(handleFinder, findsOneWidget);

          final handleSize = tester.getSize(handleFinder);
          expect(handleSize.width, greaterThanOrEqualTo(44.0));
          expect(handleSize.height, greaterThanOrEqualTo(44.0));
        }
      },
    );

    testWidgets(
      'Dragging a rectangle corner shows 2x magnifier with crosshairs above touch position, resizes rect, and hides on release',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.6, 0.6),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [rect],
          selectedEntityId: 'R1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Magnifier initially not visible
        expect(find.byType(RawMagnifier), findsNothing);

        // Find corner 2 (bottom-right: p2)
        final handleFinder = find.byKey(const ValueKey('point_handle_R1_2'));
        expect(handleFinder, findsOneWidget);

        final cornerScreenPos = tester.getCenter(handleFinder);
        final gesture = await tester.startGesture(cornerScreenPos);
        await tester.pump();
        await gesture.moveBy(const Offset(40, 40));
        await tester.pump();

        // Magnifier is visible!
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Magnifier zoom scale matches AppTheme.magnifierScale (2.0)
        final magnifier = tester.widget<RawMagnifier>(
          find.byType(RawMagnifier),
        );
        expect(magnifier.magnificationScale, AppTheme.magnifierScale);
        expect(magnifier.magnificationScale, 2.0);

        // Position of magnifier is 70px above finger on mobile
        final currentPointerPos = cornerScreenPos + const Offset(40, 40);
        final magnifierRect = tester.getRect(find.byType(RawMagnifier));
        expect(
          magnifierRect.center.dy,
          closeTo(currentPointerPos.dy - 70.0, 0.001),
        );
        expect(magnifierRect.center.dx, closeTo(currentPointerPos.dx, 0.001));
        expect(magnifier.focalPointOffset, const Offset(0, 70.0));
        expect(magnifier.size, const Size(80.0, 80.0));

        // Crosshair is rendered in magnifier
        final crosshairFinder = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter != null &&
              w.painter.runtimeType.toString() == '_CrosshairPainter',
        );
        expect(crosshairFinder, findsOneWidget);

        // Move further
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Release touch
        await gesture.up();
        await tester.pumpAndSettle();

        // Magnifier disappears
        expect(find.byType(RawMagnifier), findsNothing);

        // Entity was resized (p2 moved)
        final updatedState = container.read(workspaceControllerProvider);
        final updatedRect = updatedState.entities
            .whereType<RectangleEntity>()
            .first;
        expect(updatedRect.p2!.dx, isNot(closeTo(0.6, 0.001)));
        expect(updatedRect.p2!.dy, isNot(closeTo(0.6, 0.001)));
      },
    );

    testWidgets(
      'On Desktop (width >= 800), magnifier has 0px vertical offset and focalPointOffset is Offset.zero',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.6, 0.6),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [rect],
          selectedEntityId: 'R1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: false,
          ),
        );
        await tester.pumpAndSettle();

        final handleFinder = find.byKey(const ValueKey('point_handle_R1_2'));
        expect(handleFinder, findsOneWidget);

        final cornerScreenPos = tester.getCenter(handleFinder);
        final gesture = await tester.startGesture(
          cornerScreenPos,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await gesture.moveBy(const Offset(40, 40));
        await tester.pump();

        expect(find.byType(RawMagnifier), findsOneWidget);

        final magnifier = tester.widget<RawMagnifier>(
          find.byType(RawMagnifier),
        );
        expect(magnifier.magnificationScale, 2.0);
        expect(magnifier.size, const Size(80.0, 80.0));
        expect(magnifier.focalPointOffset, Offset.zero);

        // Position of magnifier on desktop is exactly centered at pointer position (0px offset)
        final magnifierRect = tester.getRect(find.byType(RawMagnifier));
        final currentPointerPos = cornerScreenPos + const Offset(40, 40);
        expect(magnifierRect.center.dx, closeTo(currentPointerPos.dx, 0.001));
        expect(magnifierRect.center.dy, closeTo(currentPointerPos.dy, 0.001));

        // Crosshair is rendered
        final crosshairFinder = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter != null &&
              w.painter.runtimeType.toString() == '_CrosshairPainter',
        );
        expect(crosshairFinder, findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'When line is selected in measure step, 2 handles appear and can be dragged',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const line = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.2, 0.3),
          p2: Offset(0.7, 0.3),
          color: Color(0xFF38BDF8),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [line],
          selectedEntityId: 'L1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('point_handle_L1_0')), findsOneWidget);
        expect(find.byKey(const ValueKey('point_handle_L1_1')), findsOneWidget);

        // Drag point 1
        final p1Finder = find.byKey(const ValueKey('point_handle_L1_1'));
        final gesture = await tester.startGesture(tester.getCenter(p1Finder));
        await tester.pump();
        await gesture.moveBy(const Offset(40, 40));
        await tester.pump();

        expect(find.byType(RawMagnifier), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'Handle drag with initial touch offset snaps point directly to pointer with zero drift',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const line = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.2, 0.3),
          p2: Offset(0.7, 0.3),
          color: Color(0xFF38BDF8),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [line],
          selectedEntityId: 'L1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        final p2HandleFinder = find.byKey(const ValueKey('point_handle_L1_1'));
        final handleCenter = tester.getCenter(p2HandleFinder);

        // Touch slightly off-center (e.g. +14, +12 px away from handle center)
        final offCenterTouch = handleCenter + const Offset(14, 12);
        final gesture = await tester.startGesture(offCenterTouch);
        await tester.pump();

        // First move triggers onPanStart
        await gesture.moveBy(const Offset(40, 40));
        await tester.pump();

        // Second move triggers onPanUpdate
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();

        final currentPointerPos = offCenterTouch + const Offset(70, 70);

        // Magnifier is active
        expect(find.byType(RawMagnifier), findsOneWidget);

        // Endpoint p2 must match the pointer position directly (normalized to image overlay)
        final overlayFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ImageWithPointsOverlay',
        );
        final overlayBox = tester.renderObject<RenderBox>(overlayFinder);
        final localPointerPos = overlayBox.globalToLocal(currentPointerPos);
        final expectedNorm = Offset(
          localPointerPos.dx / overlayBox.size.width,
          localPointerPos.dy / overlayBox.size.height,
        );

        final updatedLine = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<LineEntity>()
            .first;
        expect(updatedLine.p2!.dx, closeTo(expectedNorm.dx, 0.001));
        expect(updatedLine.p2!.dy, closeTo(expectedNorm.dy, 0.001));
        // Opposite point p1 unchanged
        expect(updatedLine.p1, const Offset(0.2, 0.3));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'Dragging a rectangle corner keeps opposite corner fixed and snaps dragged corner to pointer',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.6, 0.6),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [rect],
          selectedEntityId: 'R1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Drag Corner 1: top-right corner (p2.dx, p1.dy) = (0.6, 0.2)
        // Opposite is Corner 3: (p1.dx, p2.dy) = (0.2, 0.6)
        final corner1Finder = find.byKey(const ValueKey('point_handle_R1_1'));
        final corner1Center = tester.getCenter(corner1Finder);

        final gesture = await tester.startGesture(corner1Center);
        await tester.pump();
        await gesture.moveBy(const Offset(40, -30));
        await tester.pump();
        await gesture.moveBy(const Offset(10, -10));
        await tester.pump();

        expect(find.byType(RawMagnifier), findsOneWidget);

        final overlayFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ImageWithPointsOverlay',
        );
        final overlayBox = tester.renderObject<RenderBox>(overlayFinder);
        final targetPos = corner1Center + const Offset(50, -40);
        final localPointerPos = overlayBox.globalToLocal(targetPos);
        final expectedDx = localPointerPos.dx / overlayBox.size.width;
        final expectedDy = localPointerPos.dy / overlayBox.size.height;

        final updatedRect = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<RectangleEntity>()
            .first;

        // Dragged corner matches pointer
        expect(updatedRect.p2!.dx, closeTo(expectedDx, 0.001));
        expect(updatedRect.p1!.dy, closeTo(expectedDy, 0.001));

        // Opposite corner 3 remains fixed at (0.2, 0.6)
        expect(updatedRect.p1!.dx, closeTo(0.2, 0.001));
        expect(updatedRect.p2!.dy, closeTo(0.6, 0.001));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'Dragging a polygon vertex snaps it directly to the pointer position',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const poly = DrawingEntity.polygon(
          id: 'P1',
          points: [Offset(0.2, 0.2), Offset(0.6, 0.2), Offset(0.4, 0.6)],
          color: Color(0xFF8B5CF6),
          isClosed: true,
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [poly],
          selectedEntityId: 'P1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        final vertexFinder = find.byKey(const ValueKey('point_handle_P1_1'));
        final vertexCenter = tester.getCenter(vertexFinder);

        final gesture = await tester.startGesture(vertexCenter);
        await tester.pump();
        await gesture.moveBy(const Offset(30, 40));
        await tester.pump();
        await gesture.moveBy(const Offset(10, 10));
        await tester.pump();

        expect(find.byType(RawMagnifier), findsOneWidget);

        final overlayFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ImageWithPointsOverlay',
        );
        final overlayBox = tester.renderObject<RenderBox>(overlayFinder);
        final targetPos = vertexCenter + const Offset(40, 50);
        final localPointerPos = overlayBox.globalToLocal(targetPos);
        final expectedNorm = Offset(
          localPointerPos.dx / overlayBox.size.width,
          localPointerPos.dy / overlayBox.size.height,
        );

        final updatedPoly = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<PolygonEntity>()
            .first;

        expect(updatedPoly.points[1].dx, closeTo(expectedNorm.dx, 0.001));
        expect(updatedPoly.points[1].dy, closeTo(expectedNorm.dy, 0.001));
        // Other vertices unchanged
        expect(updatedPoly.points[0], const Offset(0.2, 0.2));
        expect(updatedPoly.points[2], const Offset(0.4, 0.6));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'Dragging an angle endpoint snaps it directly to the pointer position',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const angle = DrawingEntity.angle(
          id: 'A1',
          p1: Offset(0.3, 0.3),
          p2: Offset(0.7, 0.5),
          color: Color(0xFFF59E0B),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [angle],
          selectedEntityId: 'A1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        final handleFinder = find.byKey(const ValueKey('point_handle_A1_1'));
        final handleCenter = tester.getCenter(handleFinder);

        final gesture = await tester.startGesture(handleCenter);
        await tester.pump();
        await gesture.moveBy(const Offset(-40, 30));
        await tester.pump();
        await gesture.moveBy(const Offset(-10, 10));
        await tester.pump();

        expect(find.byType(RawMagnifier), findsOneWidget);

        final overlayFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ImageWithPointsOverlay',
        );
        final overlayBox = tester.renderObject<RenderBox>(overlayFinder);
        final targetPos = handleCenter + const Offset(-50, 40);
        final localPointerPos = overlayBox.globalToLocal(targetPos);
        final expectedNorm = Offset(
          localPointerPos.dx / overlayBox.size.width,
          localPointerPos.dy / overlayBox.size.height,
        );

        final updatedAngle = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<AngleEntity>()
            .first;

        expect(updatedAngle.p2!.dx, closeTo(expectedNorm.dx, 0.001));
        expect(updatedAngle.p2!.dy, closeTo(expectedNorm.dy, 0.001));
        expect(updatedAngle.p1, const Offset(0.3, 0.3));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'Dragging the body of a shape moves it relatively and does NOT activate magnifier',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const line = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.2, 0.3),
          p2: Offset(0.8, 0.3),
          color: Color(0xFF38BDF8),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [line],
          selectedEntityId: 'L1',
        );
        container.read(activeToolProvider.notifier).setTool(const SelectTool());

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.measure,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        final overlayFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ImageWithPointsOverlay',
        );
        final overlayBox = tester.renderObject<RenderBox>(overlayFinder);
        // Midpoint of line: (0.5, 0.3)
        final midpoint = overlayBox.localToGlobal(
          Offset(0.5 * overlayBox.size.width, 0.3 * overlayBox.size.height),
        );

        // Drag the body of the line
        final gesture = await tester.startGesture(midpoint);
        await tester.pump();
        await gesture.moveBy(const Offset(30, 20));
        await tester.pump();
        await gesture.moveBy(const Offset(20, 20));
        await tester.pump();

        // NO magnifier should be shown during body drag!
        expect(find.byType(RawMagnifier), findsNothing);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);

        // Entire line moved relatively (by second move delta 20, 20)
        final deltaNorm = Offset(
          20 / overlayBox.size.width,
          20 / overlayBox.size.height,
        );
        final updatedLine = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<LineEntity>()
            .first;

        expect(updatedLine.p1!.dx, closeTo(0.2 + deltaNorm.dx, 0.001));
        expect(updatedLine.p1!.dy, closeTo(0.3 + deltaNorm.dy, 0.001));
        expect(updatedLine.p2!.dx, closeTo(0.8 + deltaNorm.dx, 0.001));
        expect(updatedLine.p2!.dy, closeTo(0.3 + deltaNorm.dy, 0.001));
      },
    );
  });
}
