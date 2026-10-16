import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:flutter/gestures.dart';

class TestWorkspaceController extends WorkspaceController {
  WorkspaceState _initialState;
  TestWorkspaceController(this._initialState);

  @override
  WorkspaceState build() => _initialState;

  @override
  void moveEntityLabel(String id, Offset delta, Size size) {
    super.moveEntityLabel(id, delta, size);
    _initialState = state;
  }

  @override
  void resetEntityLabelOffset(String id) {
    super.resetEntityLabelOffset(id);
    _initialState = state;
  }
}

class MockCanvas extends Mock implements Canvas {}

final samplePngBytes = Uint8List.fromList([
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
  96,
  0,
  2,
  0,
  0,
  5,
  0,
  1,
  226,
  38,
  5,
  155,
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
]);

void main() {
  setUpAll(() {
    registerFallbackValue(const Offset(0, 0));
    registerFallbackValue(Paint());
    registerFallbackValue(const Rect.fromLTWH(0, 0, 0, 0));
    registerFallbackValue(Path());
  });

  final testEntities = <DrawingEntity>[
    const DrawingEntity.line(
      id: 'line1',
      color: Colors.red,
      p1: Offset(0, 0),
      p2: Offset(1, 1),
    ),
    const DrawingEntity.rectangle(
      id: 'rect1',
      color: Colors.blue,
      p1: Offset(0, 0),
      p2: Offset(1, 1),
    ),
    const DrawingEntity.polygon(
      id: 'poly1',
      color: Colors.green,
      points: [Offset(0, 0), Offset(1, 0), Offset(0, 1)],
      isClosed: true,
    ),
    const DrawingEntity.angle(
      id: 'angle1',
      color: Colors.yellow,
      p1: Offset(0, 0),
      p2: Offset(1, 1),
    ),
    const DrawingEntity.calibration(
      id: 'calib1',
      p1: Offset(0, 0),
      p2: Offset(1, 1),
    ),
  ];

  test('EntitiesPainter draws all entities when not in calibrate step', () {
    final painter = EntitiesPainter(
      entities: testEntities,
      activeStep: WorkflowStepType.measure,
      primaryColor: Colors.blue,
      successColor: Colors.green,
      pointColor: Colors.white,
    );

    final mockCanvas = MockCanvas();
    painter.paint(mockCanvas, const Size(100, 100));

    // Verify drawing commands were called
    verify(() => mockCanvas.drawLine(any(), any(), any()))
        .called(greaterThan(0));
    verify(() => mockCanvas.drawRect(any(), any())).called(greaterThan(0));
    verify(() => mockCanvas.drawPath(any(), any())).called(greaterThan(0));
  });

  test('EntitiesPainter hides non-calibration entities in calibrate step', () {
    final painter = EntitiesPainter(
      entities: testEntities,
      activeStep: WorkflowStepType.calibrate,
      primaryColor: Colors.blue,
      successColor: Colors.green,
      pointColor: Colors.white,
    );

    final mockCanvas = MockCanvas();
    painter.paint(mockCanvas, const Size(100, 100));

    // Calibration line has p1 and p2, so it will draw a line and 4 circles (point + border for each).
    // It should not draw any rects or paths.
    verifyNever(() => mockCanvas.drawRect(any(), any()));
    verifyNever(() => mockCanvas.drawPath(any(), any()));
    verifyNever(() => mockCanvas.drawArc(any(), any(), any(), any(), any()));

    // Verify line was drawn for the calibration entity only (which is 1 line)
    // The measurement lines, polygon lines, angle lines shouldn't be drawn.
    verify(() => mockCanvas.drawLine(any(), any(), any())).called(1);
  });

  testWidgets('Middle mouse drag pans the image', (WidgetTester tester) async {
    final testState = WorkspaceState(
      loadedImage: LoadedImageInfo(
        fileName: 'test.png',
        fileSizeBytes: 100,
        bytes: samplePngBytes,
        width: 1,
        height: 1,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        workspaceControllerProvider.overrideWith(
          () => TestWorkspaceController(testState),
        ),
      ],
    );
    addTearDown(container.dispose);

    final transformationController = container.read(
      transformationControllerProvider,
    );
    expect(transformationController.value.entry(0, 3), 0.0); // dx
    expect(transformationController.value.entry(1, 3), 0.0); // dy

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: WorkspaceImageView(activeStep: WorkflowStepType.measure),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the interactive viewer / stack
    final stack = find.byType(Stack).first;
    expect(stack, findsOneWidget);

    // Simulate middle mouse pan
    final gesture = await tester.startGesture(
      tester.getCenter(stack),
      pointer: 1,
      buttons: kMiddleMouseButton,
    );
    await gesture.moveBy(const Offset(50, 60));
    await gesture.up();

    await tester.pumpAndSettle();

    // Verify matrix was updated
    expect(transformationController.value.entry(0, 3), 50.0); // dx
    expect(transformationController.value.entry(1, 3), 60.0); // dy
  });

  testWidgets(
    'Desktop calibration input card renders at orthogonal offset with leader line',
    (WidgetTester tester) async {
      const calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.2, 0.5),
        p2: Offset(0.6, 0.5),
        enteredDistance: 2.0,
        selectedUnit: 'm',
      );

      final testState = WorkspaceState(
        loadedImage: LoadedImageInfo(
          fileName: 'test.png',
          fileSizeBytes: 100,
          bytes: samplePngBytes,
          width: 800,
          height: 600,
        ),
        entities: [calib],
      );

      final container = ProviderContainer(
        overrides: [
          workspaceControllerProvider.overrideWith(
            () => TestWorkspaceController(testState),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: WorkspaceImageView(
                  activeStep: WorkflowStepType.calibrate,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card is rendered
      final cardFinder = find.byKey(const ValueKey('calib_input_card'));
      expect(cardFinder, findsOneWidget);

      // Card is positioned at orthogonal offset: midpoint is (0.4, 0.5), offset upwards by 32px
      // Leader line is drawn
      final leaderLineFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter != null &&
            widget.painter.runtimeType.toString() ==
                'MeasurementLeaderLinesPainter',
      );
      expect(leaderLineFinder, findsOneWidget);
    },
  );

  testWidgets(
    'Desktop calibration input card drag moves label and double-tap resets offset',
    (WidgetTester tester) async {
      const calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.2, 0.5),
        p2: Offset(0.6, 0.5),
        enteredDistance: 2.0,
        selectedUnit: 'm',
      );

      final testState = WorkspaceState(
        loadedImage: LoadedImageInfo(
          fileName: 'test.png',
          fileSizeBytes: 100,
          bytes: samplePngBytes,
          width: 800,
          height: 600,
        ),
        entities: [calib],
      );

      final container = ProviderContainer(
        overrides: [
          workspaceControllerProvider.overrideWith(
            () => TestWorkspaceController(testState),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: WorkspaceImageView(
                  activeStep: WorkflowStepType.calibrate,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dragHandle = find.byIcon(Icons.drag_indicator);
      expect(dragHandle, findsOneWidget);

      // Drag card
      await tester.drag(
        dragHandle,
        const Offset(40, 50),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      var state = container.read(workspaceControllerProvider);
      var currentCalib = state.entities.whereType<CalibrationEntity>().first;
      expect(currentCalib.customLabelOffset, isNotNull);

      // Double tap to reset
      await tester.tap(dragHandle);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(dragHandle);
      await tester.pumpAndSettle();

      state = container.read(workspaceControllerProvider);
      currentCalib = state.entities.whereType<CalibrationEntity>().first;
      expect(currentCalib.customLabelOffset, isNull);
    },
  );

  testWidgets(
    'Desktop calibration card is ghosted when foreign entity is selected and collides with card',
    (WidgetTester tester) async {
      // Calibration line: midpoint at (400, 300), base position with 32px offset = (400, 268)
      const calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.25, 0.5), // (200, 300)
        p2: Offset(0.75, 0.5), // (600, 300)
        enteredDistance: 2.0,
        selectedUnit: 'm',
      );

      // Foreign selected line: P1 handle at (400, 268) exactly on the calibration card
      const line = DrawingEntity.line(
        id: 'line_1',
        p1: Offset(0.5, 0.4466667), // (400, ~268)
        p2: Offset(0.8, 0.4466667),
        color: Colors.blue,
      );

      final testState = WorkspaceState(
        loadedImage: LoadedImageInfo(
          fileName: 'test.png',
          fileSizeBytes: 100,
          bytes: samplePngBytes,
          width: 800,
          height: 600,
        ),
        entities: [calib, line],
        selectedEntityId: 'line_1',
      );

      final container = ProviderContainer(
        overrides: [
          workspaceControllerProvider.overrideWith(
            () => TestWorkspaceController(testState),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: WorkspaceImageView(
                  activeStep: WorkflowStepType.calibrate,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.ancestor(
        of: find.byKey(const ValueKey('calib_input_card')),
        matching: find.byType(AnimatedOpacity),
      );
      final opacityWidget = tester.widget<AnimatedOpacity>(cardFinder.first);
      expect(opacityWidget.opacity, 0.15);

      final ignoreFinder = find.descendant(
        of: cardFinder.first,
        matching: find.byType(IgnorePointer),
      );
      final ignoreWidget = tester.widget<IgnorePointer>(ignoreFinder.first);
      expect(ignoreWidget.ignoring, isTrue);
    },
  );
}
