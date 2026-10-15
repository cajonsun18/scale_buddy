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

        // Position of magnifier is above finger (smaller Y coordinate)
        final magnifierRect = tester.getRect(find.byType(RawMagnifier));
        expect(magnifierRect.center.dy, lessThan(cornerScreenPos.dy));

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
  });
}
