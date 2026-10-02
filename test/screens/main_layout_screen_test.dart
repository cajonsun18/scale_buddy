import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets(
    'MainLayoutScreen shows dialog when leaving unconfirmed calibration',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScaleBuddyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to Calibration step (Step 3)
      await tester.tap(find.text('Kalibrieren').first);
      await tester.pumpAndSettle();
      expect(find.text('Schritt 3 von 4'), findsOneWidget);

      // Inject an unconfirmed calibration state
      final controller = container.read(workspaceControllerProvider.notifier);
      controller.addOrUpdateEntity(
        const DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.5, 0.5),
          isConfirmed: false,
        ),
      );
      await tester.pumpAndSettle();

      // Try to go to Step 4
      await tester.tap(find.text('Messen').first);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Ungespeicherte Änderungen'), findsOneWidget);
      expect(
        find.text(
          'Du hast Punkte für den Maßstab gesetzt, diese aber noch nicht bestätigt. Möchtest du die Änderungen wirklich verwerfen und den Schritt verlassen?',
        ),
        findsOneWidget,
      );

      // Tap "Abbrechen"
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Should still be on step 3
      expect(find.text('Schritt 3 von 4'), findsOneWidget);

      // Try to go to Step 4 again
      await tester.tap(find.text('Messen').first);
      await tester.pumpAndSettle();

      // Tap "Verwerfen"
      await tester.tap(find.text('Verwerfen'));
      await tester.pumpAndSettle();

      // Should now be on step 4
      expect(find.text('Schritt 4 von 4'), findsOneWidget);

      // The calibration entity should be removed
      final state = container.read(workspaceControllerProvider);
      expect(state.entities.whereType<CalibrationEntity>().isEmpty, isTrue);
    },
  );

  testWidgets(
    'MainLayoutScreen automatically selects CalibrationTool when switching to calibrate step',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ScaleBuddyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure we are in a state where calibration can be entered without dialog
      final controller = container.read(workspaceControllerProvider.notifier);
      controller.clearCalibration();

      // Go to Step 4 first (Messen)
      await tester.tap(find.text('Messen').first);
      await tester.pumpAndSettle();

      // Change tool manually in step 4
      await tester.tap(find.text('Fläche (Frei)').first);
      await tester.pumpAndSettle();

      final activeToolBefore = container.read(activeToolProvider);
      expect(activeToolBefore, isNot(isA<CalibrationTool>()));

      // Now go to Step 3 (Kalibrieren)
      await tester.tap(find.text('Kalibrieren').first);
      await tester.pumpAndSettle();

      // Verify active tool is now CalibrationTool
      final activeToolAfter = container.read(activeToolProvider);
      expect(activeToolAfter, isA<CalibrationTool>());
    },
  );

  testWidgets('MainLayoutScreen ESC key aborts current drawing operation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ScaleBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Go to Step 4 (Messen)
    await tester.tap(find.text('Messen').first);
    await tester.pumpAndSettle();

    // Select Distance Tool
    await tester.tap(find.text('Länge').first);
    await tester.pumpAndSettle();

    final controller = container.read(workspaceControllerProvider.notifier);

    // Simulate placing one point by using distance tool manually
    // We can also just send a tap to the WorkspaceImageView stack
    // Let's send a tap to the center of the image area
    // Actually we need an image loaded to tap on WorkspaceImageView.
    // Let's just mock an active tool state by sending a tap to controller directly.
    controller.handleTapUp(
      TapUpDetails(
        kind: PointerDeviceKind.mouse,
        globalPosition: const Offset(100, 100),
        localPosition: const Offset(100, 100),
      ),
      const Size(1000, 1000),
    );

    // Now there should be one distance entity with p1 but no p2
    final stateAfterTap = container.read(workspaceControllerProvider);
    final line = stateAfterTap.entities.whereType<LineEntity>().firstOrNull;
    expect(line, isNotNull);
    expect(line!.p1, isNotNull);
    expect(line.p2, isNull);

    // Now send the ESC key
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // The partial entity should be removed!
    final finalState = container.read(workspaceControllerProvider);
    final remainingLines = finalState.entities.whereType<LineEntity>();
    expect(remainingLines.isEmpty, isTrue);
  });
}
