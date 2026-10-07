import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/calibration_input_widget.dart';

void main() {
  Widget createWidgetUnderTest(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: CalibrationInputWidget()),
      ),
    );
  }

  testWidgets('CalibrationInputWidget - invalid input shows error', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    final controller = container.read(workspaceControllerProvider.notifier);

    // Add a calibration entity that is not confirmed
    controller.addOrUpdateEntity(
      const DrawingEntity.calibration(
        id: CalibrationTool.defaultCalibrationId,
        p1: Offset(0, 0),
        p2: Offset(10, 10),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest(container));
    await tester.pumpAndSettle();

    // Enter invalid text
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Expect error text
    expect(find.text('Ungültig'), findsOneWidget);

    // Verify state did not change to confirmed
    final state = container.read(workspaceControllerProvider);
    final calib = state.entities.whereType<CalibrationEntity>().first;
    expect(calib.isConfirmed, isFalse);
    expect(calib.enteredDistance, isNull);
  });

  testWidgets('CalibrationInputWidget - valid input updates state', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    final controller = container.read(workspaceControllerProvider.notifier);

    controller.addOrUpdateEntity(
      const DrawingEntity.calibration(
        id: CalibrationTool.defaultCalibrationId,
        p1: Offset(0, 0),
        p2: Offset(10, 10),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest(container));
    await tester.pumpAndSettle();

    // Enter valid text
    await tester.enterText(find.byType(TextField), '5.0');

    // Tap the confirm button (check icon)
    final checkButton = find.byIcon(Icons.check);
    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    // Verify state changed to confirmed
    final state = container.read(workspaceControllerProvider);
    final calib = state.entities.whereType<CalibrationEntity>().first;
    expect(calib.isConfirmed, isTrue);
    expect(calib.enteredDistance, 5.0);
    expect(calib.selectedUnit, 'm');

    // Verify it switches to read-only mode
    expect(find.byType(TextField), findsNothing);
    expect(find.text('5 m'), findsOneWidget); // formatted text
  });
}
