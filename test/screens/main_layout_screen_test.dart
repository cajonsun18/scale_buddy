import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';

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
}
