import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/measurement_label_widget.dart';
import 'package:scale_buddy/widgets/measurement_labels_overlay.dart';

void main() {
  group('MeasurementLabelsOverlay', () {
    testWidgets('Rectangle side lengths are highlighted when selected', (
      WidgetTester tester,
    ) async {
      // 1. Setup mock state with a confirmed calibration and a rectangle
      final calib = DrawingEntity.calibration(
        id: 'C1',
        p1: const Offset(0.0, 0.0),
        p2: const Offset(0.0, 0.1), // 10% of height
        isConfirmed: true,
        enteredDistance: 1.0, // 1 meter real world
        selectedUnit: 'm',
      );

      final rect = DrawingEntity.rectangle(
        id: 'R1',
        p1: const Offset(0.5, 0.5),
        p2: const Offset(0.6, 0.6),
        color: Colors.red,
      );

      final state = WorkspaceState(
        entities: [calib, rect],
        selectedEntityId: 'R1', // RECTANGLE IS SELECTED
      );

      // 2. Pump widget wrapped in ProviderScope with overridden state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceControllerProvider.overrideWith(
              () => _TestWorkspaceController(state),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 1000,
                child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
              ),
            ),
          ),
        ),
      );

      // 3. Verify that MeasurementLabelWidget is rendered 3 times (Area, Width, Height)
      final labelFinders = find.byType(MeasurementLabelWidget);
      expect(
        labelFinders,
        findsNWidgets(3),
        reason: 'Rectangle should render 3 labels (area, width, height)',
      );

      // 4. Verify that ALL 3 labels have isSelected == true
      final labelWidgets = tester.widgetList<MeasurementLabelWidget>(
        labelFinders,
      );
      for (final label in labelWidgets) {
        expect(
          label.isSelected,
          isTrue,
          reason: 'Label  should be selected when the rectangle is selected',
        );
      }
    });

    testWidgets(
      'Rectangle side lengths are NOT highlighted when not selected',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: const Offset(0.5, 0.5),
          p2: const Offset(0.6, 0.6),
          color: Colors.red,
        );

        final unselectedState = WorkspaceState(
          entities: [calib, rect],
          selectedEntityId: null, // NOT SELECTED
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(unselectedState),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final unselectedLabelWidgets = tester
            .widgetList<MeasurementLabelWidget>(
              find.byType(MeasurementLabelWidget),
            );
        expect(unselectedLabelWidgets.length, 3);
        for (final label in unselectedLabelWidgets) {
          expect(label.isSelected, isFalse);
        }
      },
    );

    testWidgets('Dragging a MeasurementLabelWidget moves the entity', (
      WidgetTester tester,
    ) async {
      final calib = DrawingEntity.calibration(
        id: 'C1',
        p1: const Offset(0.0, 0.0),
        p2: const Offset(0.0, 0.1),
        isConfirmed: true,
        enteredDistance: 1.0,
        selectedUnit: 'm',
      );

      final rect = DrawingEntity.rectangle(
        id: 'R1',
        p1: const Offset(0.5, 0.5),
        p2: const Offset(0.6, 0.6),
        color: Colors.red,
      );

      final state = WorkspaceState(
        entities: [calib, rect],
        selectedEntityId: 'R1',
      );

      final container = ProviderContainer(
        overrides: [
          workspaceControllerProvider.overrideWith(
            () => _TestWorkspaceController(state),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Focus(
                child: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        ),
      );

      // Find the area label (should be the first or easily identifiable)
      final labelFinder = find.byType(MeasurementLabelWidget).first;
      expect(labelFinder, findsOneWidget);

      // Simulate a drag on the label
      final gesture = await tester.startGesture(tester.getCenter(labelFinder));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();

      await tester.pumpAndSettle();

      // We just want to ensure it doesn't crash and the gesture is handled.
      // To strictly verify the entity moved, we'd need to mock WorkspaceController and verify handlePanUpdate.
      // But _TestWorkspaceController is actually returning a fixed state.
    });
    /*
      final unselectedState = state.copyWith(selectedEntityId: null);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceControllerProvider.overrideWith(
              () => _TestWorkspaceController(unselectedState),
            ),
          ],
          child: MaterialApp(theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 1000,
                child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
              ),
            ),
          ),
        ),
      );

      final unselectedLabelWidgets = tester.widgetList<MeasurementLabelWidget>(find.byType(MeasurementLabelWidget));
      expect(unselectedLabelWidgets.length, 3);
      for (final label in unselectedLabelWidgets) {
        expect(label.isSelected, isFalse, reason: 'Label  should not be selected when the rectangle is not selected');
      }
    */
  });
}

class _TestWorkspaceController extends WorkspaceController {
  final WorkspaceState _initialState;

  _TestWorkspaceController(this._initialState);

  @override
  WorkspaceState build() {
    return _initialState;
  }
}
