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
    testWidgets(
      'Rectangle side lengths selection highlighting reflects selectedEntityId',
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

        final state = WorkspaceState(
          entities: [calib, rect],
          selectedEntityId: null, // NOT SELECTED initially
        );

        final controller = _TestWorkspaceController(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(() => controller),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        // Initially not selected
        var labelFinders = find.byType(MeasurementLabelWidget);
        expect(labelFinders, findsNWidgets(3));
        for (final label in tester.widgetList<MeasurementLabelWidget>(
          labelFinders,
        )) {
          expect(label.isSelected, isFalse);
        }

        // Now select the rectangle
        controller.state = state.copyWith(selectedEntityId: 'R1');
        await tester.pumpAndSettle();

        // All 3 labels have isSelected == true
        labelFinders = find.byType(MeasurementLabelWidget);
        expect(labelFinders, findsNWidgets(3));
        for (final label in tester.widgetList<MeasurementLabelWidget>(
          labelFinders,
        )) {
          expect(label.isSelected, isTrue);
        }
      },
    );

    testWidgets(
      'Dragging a measurement pill updates customLabelOffset and moves only the label, leaving entity points unchanged',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4), // (200, 400) px
          p2: const Offset(0.6, 0.4), // (600, 400) px -> midpoint (400, 400)
          color: const Color(0xFF38BDF8),
        );

        final state = WorkspaceState(
          entities: [calib, line],
          selectedEntityId: 'L1',
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
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        final initialCenter = tester.getCenter(labelFinder);
        // Default position: (400, 400 - 32) = (400, 368)
        expect(initialCenter.dx, closeTo(400.0, 0.1));
        expect(initialCenter.dy, closeTo(368.0, 0.1));

        // Drag the label by (60, 40) using tester.drag
        await tester.drag(labelFinder, const Offset(60, 40));
        await tester.pumpAndSettle();

        // 1. Verify entity's points p1 and p2 did NOT change
        final currentState = container.read(workspaceControllerProvider);
        final currentLine = currentState.entities.whereType<LineEntity>().first;
        expect(currentLine.p1, const Offset(0.2, 0.4));
        expect(currentLine.p2, const Offset(0.6, 0.4));

        // 2. Verify customLabelOffset is set on entity
        expect(currentLine.customLabelOffset, isNotNull);
        expect(currentLine.customLabelOffset!.dx, greaterThan(0.0));
        expect(currentLine.customLabelOffset!.dy, greaterThan(0.0));

        // 3. Verify label position updated on screen according to customLabelOffset
        final newCenter = tester.getCenter(labelFinder);
        expect(
          newCenter.dx,
          closeTo(
            initialCenter.dx + currentLine.customLabelOffset!.dx * 1000,
            0.1,
          ),
        );
        expect(
          newCenter.dy,
          closeTo(
            initialCenter.dy + currentLine.customLabelOffset!.dy * 1000,
            0.1,
          ),
        );
      },
    );

    testWidgets(
      'Double tap on displaced pill resets custom offset and snaps pill back to default position',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4),
          p2: const Offset(0.6, 0.4),
          color: const Color(0xFF38BDF8),
          customLabelOffset: const Offset(0.1, 0.08), // Already displaced
        );

        final state = WorkspaceState(entities: [calib, line]);

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
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        // Initially displaced at (400 + 100, 368 + 80) = (500, 448)
        final displacedCenter = tester.getCenter(labelFinder);
        expect(displacedCenter.dx, closeTo(500.0, 0.5));
        expect(displacedCenter.dy, closeTo(448.0, 0.5));

        // Double tap on the label
        await tester.tap(labelFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(labelFinder);
        await tester.pumpAndSettle();

        // Verify customLabelOffset is reset to null
        final currentState = container.read(workspaceControllerProvider);
        final currentLine = currentState.entities.whereType<LineEntity>().first;
        expect(currentLine.customLabelOffset, isNull);

        // Verify label snapped back to default position (400, 368)
        final resetCenter = tester.getCenter(labelFinder);
        expect(resetCenter.dx, closeTo(400.0, 0.5));
        expect(resetCenter.dy, closeTo(368.0, 0.5));
      },
    );

    testWidgets('Elastic leader line connects displaced pill to shape anchor', (
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
        p1: const Offset(0.3, 0.3), // (300, 300)
        p2: const Offset(0.5, 0.5), // (500, 500) -> center (400, 400)
        color: Colors.green,
        customLabelOffset: const Offset(0.15, 0.15), // displaced to (550, 550)
      );

      final angle = DrawingEntity.angle(
        id: 'A1',
        p1: const Offset(0.2, 0.2), // apex (200, 200)
        p2: const Offset(0.25, 0.2),
        color: Colors.orange,
        customLabelOffset: const Offset(0.1, -0.05), // displaced
      );

      final state = WorkspaceState(entities: [calib, rect, angle]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceControllerProvider.overrideWith(
              () => _TestWorkspaceController(state),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SizedBox(
                width: 1000,
                height: 1000,
                child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
              ),
            ),
          ),
        ),
      );

      final customPaints = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      final leaderPaint = customPaints
          .where((cp) => cp.painter is MeasurementLeaderLinesPainter)
          .firstOrNull;
      expect(leaderPaint, isNotNull);
      final painter = leaderPaint!.painter as MeasurementLeaderLinesPainter;

      // Rectangle leader line should start at center (400, 400) and end at (550, 550)
      final rectLine = painter.lines.firstWhere(
        (l) => l.start == const Offset(400, 400),
      );
      expect(rectLine.end, const Offset(550, 550));

      // Angle leader line should start at apex (200, 200)
      final angleLine = painter.lines.firstWhere(
        (l) => l.start == const Offset(200, 200),
      );
      expect(angleLine, isNotNull);
    });

    testWidgets(
      'Desktop mouse cursor switches to grab on hover and grabbing during drag',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4),
          p2: const Offset(0.6, 0.4),
          color: const Color(0xFF38BDF8),
        );

        final state = WorkspaceState(entities: [calib, line]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        // Verify initial cursor is SystemMouseCursors.grab
        final mouseRegionBefore = tester.widget<MouseRegion>(
          find
              .descendant(of: labelFinder, matching: find.byType(MouseRegion))
              .first,
        );
        expect(mouseRegionBefore.cursor, SystemMouseCursors.grab);

        // Start drag gesture
        final gesture = await tester.startGesture(
          tester.getCenter(labelFinder),
        );
        await gesture.moveBy(const Offset(20, 20));
        await tester.pump();

        // While dragging, cursor is SystemMouseCursors.grabbing
        final mouseRegionDuring = tester.widget<MouseRegion>(
          find
              .descendant(of: labelFinder, matching: find.byType(MouseRegion))
              .first,
        );
        expect(mouseRegionDuring.cursor, SystemMouseCursors.grabbing);

        // Complete gesture
        await gesture.up();
        await tester.pumpAndSettle();

        // After drag, cursor returns to SystemMouseCursors.grab
        final mouseRegionAfter = tester.widget<MouseRegion>(
          find
              .descendant(of: labelFinder, matching: find.byType(MouseRegion))
              .first,
        );
        expect(mouseRegionAfter.cursor, SystemMouseCursors.grab);
      },
    );

    testWidgets(
      'Line measurement badge has 32px orthogonal offset and leader line',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4), // (200, 400) px
          p2: const Offset(
            0.6,
            0.4,
          ), // (600, 400) px -> horizontal, midpoint (400, 400)
          color: const Color(0xFF38BDF8),
        );

        final state = WorkspaceState(entities: [calib, line]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        // Verify label is rendered
        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        // Center should be (400, 400 - 32) = (400, 368)
        final center = tester.getCenter(labelFinder);
        expect(center.dx, 400.0);
        expect(center.dy, 368.0);

        // Verify leader line painter is rendered with custom paint
        final customPaints = tester.widgetList<CustomPaint>(
          find.byType(CustomPaint),
        );
        final leaderPaint = customPaints
            .where((cp) => cp.painter is MeasurementLeaderLinesPainter)
            .firstOrNull;
        expect(leaderPaint, isNotNull);
        final painter = leaderPaint!.painter as MeasurementLeaderLinesPainter;
        expect(painter.lines.length, 1);
        expect(painter.lines.first.start, const Offset(400.0, 400.0));
        expect(painter.lines.first.end, const Offset(400.0, 368.0));
      },
    );

    testWidgets(
      'Short line (< 100px) badge bounding box does not intersect P1 or P2',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // 60px horizontal line
        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.3), // (200, 300) px
          p2: const Offset(0.26, 0.3), // (260, 300) px -> 60px distance
          color: const Color(0xFF38BDF8),
        );

        final state = WorkspaceState(entities: [calib, line]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        final badgeRect = tester.getRect(labelFinder);
        const p1 = Offset(200, 300);
        const p2 = Offset(260, 300);

        // Neither P1 nor P2 are within the badge bounding box
        expect(badgeRect.contains(p1), isFalse);
        expect(badgeRect.contains(p2), isFalse);

        // Even with 10px handle radius, no overlap occurs
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: p1, radius: 10)),
          isFalse,
        );
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: p2, radius: 10)),
          isFalse,
        );
      },
    );

    testWidgets('Line measurement badge auto-flips downward at top edge', (
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

      // Line placed at y = 20px (close to top edge of 1000x1000 canvas)
      final line = DrawingEntity.line(
        id: 'L1',
        p1: const Offset(0.2, 0.02), // (200, 20) px
        p2: const Offset(0.4, 0.02), // (400, 20) px -> midpoint (300, 20)
        color: const Color(0xFF38BDF8),
      );

      final state = WorkspaceState(entities: [calib, line]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceControllerProvider.overrideWith(
              () => _TestWorkspaceController(state),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SizedBox(
                width: 1000,
                height: 1000,
                child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
              ),
            ),
          ),
        ),
      );

      final labelFinder = find.byType(MeasurementLabelWidget);
      expect(labelFinder, findsOneWidget);

      // Should flip downward: (300, 20 + 32) = (300, 52)
      final center = tester.getCenter(labelFinder);
      expect(center.dx, 300.0);
      expect(center.dy, 52.0);

      final badgeRect = tester.getRect(labelFinder);
      expect(badgeRect.top, greaterThanOrEqualTo(0.0));
    });

    testWidgets(
      'Offset and leader lines behave consistently on mobile screen width',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.5), // (80, 400) px in 400x800
          p2: const Offset(
            0.8,
            0.5,
          ), // (320, 400) px in 400x800 -> midpoint (200, 400)
          color: const Color(0xFF38BDF8),
        );

        final state = WorkspaceState(entities: [calib, line]);

        // Mobile screen: 400 x 800
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 800,
                  child: MeasurementLabelsOverlay(size: Size(400, 800)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        // Center should be (200, 400 - 32) = (200, 368)
        final center = tester.getCenter(labelFinder);
        expect(center.dx, 200.0);
        expect(center.dy, 368.0);
      },
    );

    testWidgets(
      'Rectangle edge badges keep safety margin from corners and do not overlap corner handles',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // Narrow 40px wide, 60px tall rectangle
        final rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: const Offset(0.2, 0.3), // (200, 300) px
          p2: const Offset(0.24, 0.36), // (240, 360) px
          color: Colors.red,
        );

        final state = WorkspaceState(
          entities: [calib, rect],
          selectedEntityId: 'R1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinders = find.byType(MeasurementLabelWidget);
        expect(labelFinders, findsNWidgets(3)); // Area, Width, Height

        final corners = [
          const Offset(200, 300),
          const Offset(240, 300),
          const Offset(200, 360),
          const Offset(240, 360),
        ];

        for (int i = 0; i < 3; i++) {
          final badgeRect = tester.getRect(labelFinders.at(i));
          for (final corner in corners) {
            expect(
              badgeRect.contains(corner),
              isFalse,
              reason:
                  'Badge $i at $badgeRect should not contain corner $corner',
            );
            expect(
              badgeRect.overlaps(Rect.fromCircle(center: corner, radius: 10)),
              isFalse,
              reason:
                  'Badge $i at $badgeRect should not overlap handle at $corner',
            );
          }
        }
      },
    );

    testWidgets(
      'Compact polygon renders badge with leader line and no vertex overlap',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // Compact triangle
        final poly = DrawingEntity.polygon(
          id: 'P1',
          points: const [
            Offset(0.2, 0.2),
            Offset(0.26, 0.2),
            Offset(0.23, 0.225),
          ],
          color: Colors.green,
          isClosed: true,
        );

        final state = WorkspaceState(entities: [calib, poly]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        final badgeRect = tester.getRect(labelFinder);
        final vertices = [
          const Offset(200, 200),
          const Offset(260, 200),
          const Offset(230, 225),
        ];
        for (final v in vertices) {
          expect(badgeRect.contains(v), isFalse);
          expect(
            badgeRect.overlaps(Rect.fromCircle(center: v, radius: 10)),
            isFalse,
          );
        }

        // Verify leader line exists
        final customPaints = tester.widgetList<CustomPaint>(
          find.byType(CustomPaint),
        );
        final leaderPaint = customPaints
            .where((cp) => cp.painter is MeasurementLeaderLinesPainter)
            .firstOrNull;
        expect(leaderPaint, isNotNull);
        final painter = leaderPaint!.painter as MeasurementLeaderLinesPainter;
        expect(painter.lines.isNotEmpty, isTrue);
      },
    );

    testWidgets(
      'Angle badge is placed with sufficient radius and avoids apex and arm handles',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // Short angle: 45px arm
        final angle = DrawingEntity.angle(
          id: 'A1',
          p1: const Offset(0.3, 0.3), // (300, 300) px
          p2: const Offset(0.345, 0.3), // (345, 300) px
          color: Colors.orange,
        );

        final state = WorkspaceState(entities: [calib, angle]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final labelFinder = find.byType(MeasurementLabelWidget);
        expect(labelFinder, findsOneWidget);

        final badgeRect = tester.getRect(labelFinder);
        const apex = Offset(300, 300);
        const armEnd = Offset(345, 300);

        expect(badgeRect.contains(apex), isFalse);
        expect(badgeRect.contains(armEnd), isFalse);
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: apex, radius: 10)),
          isFalse,
        );
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: armEnd, radius: 10)),
          isFalse,
        );
      },
    );

    testWidgets(
      'Selective ghosting dims foreign pill to 0.15 opacity and enables IgnorePointer when overlapping handle of selected line',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // L1: selected line, endpoints at (200, 400) and (600, 400)
        final line1 = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4),
          p2: const Offset(0.6, 0.4),
          color: const Color(0xFF38BDF8),
        );

        // L2: foreign line, pill deliberately placed at (200, 400) via customLabelOffset
        // Default pos of L2 at (200, 600 - 32) = (200, 568), so offset of (0, -0.168) places it at (200, 400)
        final line2 = DrawingEntity.line(
          id: 'L2',
          p1: const Offset(0.1, 0.6),
          p2: const Offset(0.3, 0.6),
          color: Colors.green,
          customLabelOffset: const Offset(0.0, -0.168),
        );

        // L3: foreign line far away at (800, 800)
        final line3 = DrawingEntity.line(
          id: 'L3',
          p1: const Offset(0.7, 0.8),
          p2: const Offset(0.9, 0.8),
          color: Colors.purple,
        );

        final state = WorkspaceState(
          entities: [calib, line1, line2, line3],
          selectedEntityId: 'L1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        // Find L2's label (contains S2)
        final l2Finder = find.ancestor(
          of: find.textContaining('S2:'),
          matching: find.byType(AnimatedOpacity),
        );
        expect(l2Finder, findsOneWidget);
        final l2Opacity = tester.widget<AnimatedOpacity>(l2Finder);
        expect(l2Opacity.opacity, 0.15);

        final l2IgnorePointer = tester.widget<IgnorePointer>(
          find.descendant(of: l2Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l2IgnorePointer.ignoring, isTrue);

        // L1 (selected): opacity 1.0, ignoring: false
        final l1Finder = find.ancestor(
          of: find.textContaining('S1:'),
          matching: find.byType(AnimatedOpacity),
        );
        expect(l1Finder, findsOneWidget);
        final l1Opacity = tester.widget<AnimatedOpacity>(l1Finder);
        expect(l1Opacity.opacity, 1.0);
        final l1IgnorePointer = tester.widget<IgnorePointer>(
          find.descendant(of: l1Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l1IgnorePointer.ignoring, isFalse);

        // L3 (distant): opacity 1.0, ignoring: false
        final l3Finder = find.ancestor(
          of: find.textContaining('S3:'),
          matching: find.byType(AnimatedOpacity),
        );
        expect(l3Finder, findsOneWidget);
        final l3Opacity = tester.widget<AnimatedOpacity>(l3Finder);
        expect(l3Opacity.opacity, 1.0);
        final l3IgnorePointer = tester.widget<IgnorePointer>(
          find.descendant(of: l3Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l3IgnorePointer.ignoring, isFalse);
      },
    );

    testWidgets(
      'Foreign pill overlapping selected pill has 0.15 opacity and IgnorePointer',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // L1: selected line, pill at (400, 368)
        final line1 = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4),
          p2: const Offset(0.6, 0.4),
          color: const Color(0xFF38BDF8),
        );

        // L2: foreign line, pill placed at (400, 368) overlapping L1's pill
        final line2 = DrawingEntity.line(
          id: 'L2',
          p1: const Offset(0.1, 0.6),
          p2: const Offset(0.3, 0.6), // default pos (200, 568)
          color: Colors.green,
          customLabelOffset: const Offset(
            0.2,
            -0.2,
          ), // places label at (400, 368)
        );

        final state = WorkspaceState(
          entities: [calib, line1, line2],
          selectedEntityId: 'L1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final l2Finder = find.ancestor(
          of: find.textContaining('S2:'),
          matching: find.byType(AnimatedOpacity),
        );
        final l2Opacity = tester.widget<AnimatedOpacity>(l2Finder);
        expect(l2Opacity.opacity, 0.15);

        final l2IgnorePointer = tester.widget<IgnorePointer>(
          find.descendant(of: l2Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l2IgnorePointer.ignoring, isTrue);
      },
    );

    testWidgets(
      'Deselection restores 1.0 opacity and interaction to previously ghosted pill',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line1 = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4),
          p2: const Offset(0.6, 0.4),
          color: const Color(0xFF38BDF8),
        );

        final line2 = DrawingEntity.line(
          id: 'L2',
          p1: const Offset(0.1, 0.6),
          p2: const Offset(0.3, 0.6),
          color: Colors.green,
          customLabelOffset: const Offset(0.0, -0.168),
        );

        final selectedState = WorkspaceState(
          entities: [calib, line1, line2],
          selectedEntityId: 'L1',
        );

        final controller = _TestWorkspaceController(selectedState);
        final container = ProviderContainer(
          overrides: [
            workspaceControllerProvider.overrideWith(() => controller),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        // Before deselection: L2 is ghosted at 0.15
        final l2Finder = find.ancestor(
          of: find.textContaining('S2:'),
          matching: find.byType(AnimatedOpacity),
        );
        expect(tester.widget<AnimatedOpacity>(l2Finder).opacity, 0.15);

        // Deselect
        controller.selectEntity(null);
        await tester.pumpAndSettle();

        // After deselection: L2 is restored to 1.0 and ignoring is false
        final l2AfterOpacity = tester.widget<AnimatedOpacity>(l2Finder);
        expect(l2AfterOpacity.opacity, 1.0);

        final l2AfterIgnore = tester.widget<IgnorePointer>(
          find.descendant(of: l2Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l2AfterIgnore.ignoring, isFalse);
      },
    );

    testWidgets(
      'Touch and click at overlapping handle position passes through ghosted pill',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        final line1 = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.2, 0.4),
          p2: const Offset(0.6, 0.4),
          color: const Color(0xFF38BDF8),
        );

        final line2 = DrawingEntity.line(
          id: 'L2',
          p1: const Offset(0.1, 0.6),
          p2: const Offset(0.3, 0.6),
          color: Colors.green,
          customLabelOffset: const Offset(0.0, -0.168), // at (200, 400)
        );

        final line3 = DrawingEntity.line(
          id: 'L3',
          p1: const Offset(0.7, 0.8),
          p2: const Offset(0.9, 0.8),
          color: Colors.purple,
        );

        final state = WorkspaceState(
          entities: [calib, line1, line2, line3],
          selectedEntityId: 'L1',
        );

        final controller = _TestWorkspaceController(state);
        final container = ProviderContainer(
          overrides: [
            workspaceControllerProvider.overrideWith(() => controller),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        // Tap directly at (200, 400) where L2's pill covers L1's handle
        await tester.tapAt(const Offset(200, 400));
        await tester.pumpAndSettle();

        // L2 was NOT selected because it was ignoring pointer!
        expect(
          container.read(workspaceControllerProvider).selectedEntityId,
          'L1',
        );

        // Now tap at non-ghosted pill L3
        final l3Finder = find.textContaining('S3:');
        await tester.tap(l3Finder);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // L3 is selected because it was not ghosted
        expect(
          container.read(workspaceControllerProvider).selectedEntityId,
          'L3',
        );
      },
    );

    testWidgets(
      'Selected rectangle protects all 4 corner handles against foreign pills',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.0, 0.0),
          p2: const Offset(0.0, 0.1),
          isConfirmed: true,
          enteredDistance: 1.0,
          selectedUnit: 'm',
        );

        // R1: selected rectangle, corners at (200, 200), (400, 200), (400, 400), (200, 400)
        final rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: const Offset(0.2, 0.2),
          p2: const Offset(0.4, 0.4),
          color: Colors.red,
        );

        // L2: foreign line, pill overlapping top-right corner (400, 200)
        final line2 = DrawingEntity.line(
          id: 'L2',
          p1: const Offset(0.3, 0.3),
          p2: const Offset(0.5, 0.3), // default pos (400, 268)
          color: Colors.green,
          customLabelOffset: const Offset(
            0.0,
            -0.068,
          ), // places label at (400, 200)
        );

        final state = WorkspaceState(
          entities: [calib, rect, line2],
          selectedEntityId: 'R1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final l2Finder = find.ancestor(
          of: find.textContaining('S1:'),
          matching: find.byType(AnimatedOpacity),
        );
        final l2Opacity = tester.widget<AnimatedOpacity>(l2Finder);
        expect(l2Opacity.opacity, 0.15);
        final l2Ignore = tester.widget<IgnorePointer>(
          find.descendant(of: l2Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l2Ignore.ignoring, isTrue);
      },
    );

    testWidgets(
      'Foreign pill overlapping calibration handle is ghosted when calibration is selected',
      (WidgetTester tester) async {
        final calib = DrawingEntity.calibration(
          id: 'C1',
          p1: const Offset(0.2, 0.2), // (200, 200)
          p2: const Offset(0.6, 0.2), // (600, 200)
          isConfirmed: true,
          enteredDistance: 2.0,
          selectedUnit: 'm',
        );

        // L1: foreign line, pill overlapping calibration handle P1 (200, 200)
        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.1, 0.2),
          p2: const Offset(0.3, 0.2), // default pos (200, 168)
          color: Colors.green,
          customLabelOffset: const Offset(
            0.0,
            0.032,
          ), // places label at (200, 200)
        );

        final state = WorkspaceState(
          entities: [calib, line],
          selectedEntityId: 'C1',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workspaceControllerProvider.overrideWith(
                () => _TestWorkspaceController(state),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: MeasurementLabelsOverlay(size: Size(1000, 1000)),
                ),
              ),
            ),
          ),
        );

        final l1Finder = find.ancestor(
          of: find.textContaining('S1:'),
          matching: find.byType(AnimatedOpacity),
        );
        final l1Opacity = tester.widget<AnimatedOpacity>(l1Finder);
        expect(l1Opacity.opacity, 0.15);
        final l1Ignore = tester.widget<IgnorePointer>(
          find.descendant(of: l1Finder, matching: find.byType(IgnorePointer)),
        );
        expect(l1Ignore.ignoring, isTrue);
      },
    );
  });
}

class _TestWorkspaceController extends WorkspaceController {
  WorkspaceState _testState;

  _TestWorkspaceController(this._testState);

  @override
  WorkspaceState build() {
    return _testState;
  }

  @override
  void selectEntity(String? id) {
    _testState = _testState.copyWith(selectedEntityId: id);
    state = _testState;
  }

  @override
  void moveEntityLabel(String id, Offset delta, Size size) {
    super.moveEntityLabel(id, delta, size);
    _testState = state;
  }

  @override
  void resetEntityLabelOffset(String id) {
    super.resetEntityLabelOffset(id);
    _testState = state;
  }
}
