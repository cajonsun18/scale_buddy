import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workspace_state.dart';

void main() {
  testWidgets('Workflow menu cards switch and open on click', (
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

    final controller = container.read(workspaceControllerProvider.notifier);
    final mockImage = LoadedImageInfo(
      fileName: 'dummy.png',
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
        96,
        0,
        2,
        0,
        0,
        5,
        0,
        1,
        13,
        10,
        43,
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
      width: 100,
      height: 100,
      fileSizeBytes: 100,
    );
    final perspective = DrawingEntity.perspective(
      id: 'P1',
      points: const [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)],
      color: Colors.blue,
    );
    final calib = DrawingEntity.calibration(
      id: 'C1',
      p1: const Offset(0.1, 0.1),
      p2: const Offset(0.2, 0.2),
      isConfirmed: true,
      enteredDistance: 1.0,
    );

    // ignore: invalid_use_of_visible_for_testing_member
    controller.state = WorkspaceState(
      loadedImage: mockImage,
      entities: [perspective, calib],
    );
    await tester.pumpAndSettle();

    expect(find.text('Datei laden'), findsAtLeastNWidgets(1));
    expect(find.text('Perspektive korrigieren'), findsAtLeastNWidgets(1));
    expect(find.text('Kalibrieren'), findsAtLeastNWidgets(1));
    expect(find.text('Messen'), findsAtLeastNWidgets(1));
    expect(find.text('Export & Bericht'), findsAtLeastNWidgets(1));

    expect(find.text('Schritt 4 von 5'), findsOneWidget);
  });
}
