import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:scale_buddy/theme/app_theme.dart';

class TestWorkspaceController extends WorkspaceController {
  final WorkspaceState _initialState;
  TestWorkspaceController(this._initialState);

  @override
  WorkspaceState build() => _initialState;
}

class MockCanvas extends Mock implements Canvas {}

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
      isCalibrateStep: false,
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
      isCalibrateStep: true,
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
        bytes: Uint8List.fromList([
          // 1x1 transparent png
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
        ]),
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
}
