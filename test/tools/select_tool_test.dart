import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/drag_detail.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/tools/select_tool.dart';

import 'test_helpers.dart';

void main() {
  group('SelectTool', () {
    const tool = SelectTool();

    test('onTapUp selects an entity if clicked', () {
      final line = DrawingEntity.line(
        id: 'L1',
        p1: const Offset(0.1, 0.1),
        p2: const Offset(0.9, 0.9),
        color: Colors.blue,
      );
      final state = WorkspaceState(entities: [line]);

      // Tap directly on the line
      final hitState = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(50, 50)),
        const Size(100, 100),
      );
      expect(hitState.selectedEntityId, 'L1');

      // Tap far away
      final missState = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(10, 90)),
        const Size(100, 100),
      );
      expect(missState.selectedEntityId, isNull);
    });

    test('onPanStart selects a single point if clicked directly', () {
      final line = DrawingEntity.line(
        id: 'L1',
        p1: const Offset(0.1, 0.1),
        p2: const Offset(0.9, 0.9),
        color: Colors.blue,
      );
      final state = WorkspaceState(entities: [line], selectedEntityId: 'L1');

      // Drag near p1
      final newState = tool.onPanStart(
        state,
        createDragStartDetails(const Offset(11, 11)),
        const Size(100, 100),
      );

      expect(
        newState.activeDragDetail,
        const DragDetail.entityPoint(entityId: 'L1', pointIndex: 0),
      );
    });

    test('onPanUpdate snaps line endpoint directly to cursor position without initial offset', () {
      final line = DrawingEntity.line(
        id: 'L1',
        p1: const Offset(0.1, 0.1),
        p2: const Offset(0.9, 0.9),
        color: Colors.blue,
      ) as LineEntity;
      final state = WorkspaceState(
        entities: [line],
        selectedEntityId: 'L1',
        activeDragDetail: const DragDetail.entityPoint(
          entityId: 'L1',
          pointIndex: 0,
        ),
      );

      // Cursor is moved to (25, 35) on a 100x100 canvas (normalized 0.25, 0.35)
      final newState = tool.onPanUpdate(
        state,
        createDragUpdateDetails(
          const Offset(15, 25),
          localPosition: const Offset(25, 35),
        ),
        const Size(100, 100),
      );

      final updatedLine = newState.entities.first as LineEntity;
      expect(updatedLine.p1!.dx, closeTo(0.25, 0.001));
      expect(updatedLine.p1!.dy, closeTo(0.35, 0.001));
      expect(updatedLine.p2!.dx, 0.9); // Opposite point remains fixed
      expect(updatedLine.p2!.dy, 0.9);
    });

    test(
      'onPanUpdate snaps rectangle corners and keeps opposite corner fixed',
      () {
        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.6, 0.6),
          color: Colors.green,
        );

        // Corner 0: p1 (0.2, 0.2) dragged to (0.15, 0.1) -> opposite is corner 2 (p2: 0.6, 0.6)
        var state = WorkspaceState(
          entities: [rect],
          selectedEntityId: 'R1',
          activeDragDetail: const DragDetail.entityPoint(
            entityId: 'R1',
            pointIndex: 0,
          ),
        );
        var updated = tool.onPanUpdate(
          state,
          createDragUpdateDetails(
            const Offset(5, 5),
            localPosition: const Offset(15, 10),
          ),
          const Size(100, 100),
        );
        var r = updated.entities.first as RectangleEntity;
        expect(r.p1, const Offset(0.15, 0.1));
        expect(r.p2, const Offset(0.6, 0.6));

        // Corner 1: (p2.dx, p1.dy) = (0.6, 0.2) dragged to (0.7, 0.15) -> opposite is corner 3 (p1.dx, p2.dy) = (0.2, 0.6)
        state = WorkspaceState(
          entities: [rect],
          selectedEntityId: 'R1',
          activeDragDetail: const DragDetail.entityPoint(
            entityId: 'R1',
            pointIndex: 1,
          ),
        );
        updated = tool.onPanUpdate(
          state,
          createDragUpdateDetails(
            const Offset(5, 5),
            localPosition: const Offset(70, 15),
          ),
          const Size(100, 100),
        );
        r = updated.entities.first as RectangleEntity;
        expect(r.p1!.dy, closeTo(0.15, 0.001)); // Corner 1 y
        expect(r.p2!.dx, closeTo(0.70, 0.001)); // Corner 1 x
        expect(r.p1!.dx, 0.2); // Corner 3 x unchanged
        expect(r.p2!.dy, 0.6); // Corner 3 y unchanged

        // Corner 2: p2 (0.6, 0.6) dragged to (0.8, 0.85) -> opposite is corner 0 (p1: 0.2, 0.2)
        state = WorkspaceState(
          entities: [rect],
          selectedEntityId: 'R1',
          activeDragDetail: const DragDetail.entityPoint(
            entityId: 'R1',
            pointIndex: 2,
          ),
        );
        updated = tool.onPanUpdate(
          state,
          createDragUpdateDetails(
            const Offset(5, 5),
            localPosition: const Offset(80, 85),
          ),
          const Size(100, 100),
        );
        r = updated.entities.first as RectangleEntity;
        expect(r.p1, const Offset(0.2, 0.2)); // Unchanged
        expect(r.p2, const Offset(0.8, 0.85));

        // Corner 3: (p1.dx, p2.dy) = (0.2, 0.6) dragged to (0.1, 0.75) -> opposite is corner 1 (p2.dx, p1.dy) = (0.6, 0.2)
        state = WorkspaceState(
          entities: [rect],
          selectedEntityId: 'R1',
          activeDragDetail: const DragDetail.entityPoint(
            entityId: 'R1',
            pointIndex: 3,
          ),
        );
        updated = tool.onPanUpdate(
          state,
          createDragUpdateDetails(
            const Offset(5, 5),
            localPosition: const Offset(10, 75),
          ),
          const Size(100, 100),
        );
        r = updated.entities.first as RectangleEntity;
        expect(r.p1!.dx, closeTo(0.10, 0.001)); // Corner 3 x
        expect(r.p2!.dy, closeTo(0.75, 0.001)); // Corner 3 y
        expect(r.p2!.dx, 0.6); // Corner 1 x unchanged
        expect(r.p1!.dy, 0.2); // Corner 1 y unchanged
      },
    );

    test('onPanUpdate snaps polygon vertex directly to cursor position', () {
      const polygon = DrawingEntity.polygon(
        id: 'P1',
        points: [Offset(0.1, 0.1), Offset(0.5, 0.1), Offset(0.3, 0.5)],
        color: Colors.purple,
      );
      final state = WorkspaceState(
        entities: [polygon],
        selectedEntityId: 'P1',
        activeDragDetail: const DragDetail.entityPoint(
          entityId: 'P1',
          pointIndex: 1,
        ),
      );

      final newState = tool.onPanUpdate(
        state,
        createDragUpdateDetails(
          const Offset(5, 5),
          localPosition: const Offset(65, 20),
        ),
        const Size(100, 100),
      );

      final updatedPoly = newState.entities.first as PolygonEntity;
      expect(updatedPoly.points[0], const Offset(0.1, 0.1));
      expect(updatedPoly.points[1].dx, closeTo(0.65, 0.001));
      expect(updatedPoly.points[1].dy, closeTo(0.20, 0.001));
      expect(updatedPoly.points[2], const Offset(0.3, 0.5));
    });

    test('onPanUpdate snaps angle endpoint directly to cursor position', () {
      const angle = DrawingEntity.angle(
        id: 'A1',
        p1: Offset(0.2, 0.2),
        p2: Offset(0.7, 0.4),
        color: Colors.orange,
      );
      final state = WorkspaceState(
        entities: [angle],
        selectedEntityId: 'A1',
        activeDragDetail: const DragDetail.entityPoint(
          entityId: 'A1',
          pointIndex: 1,
        ),
      );

      final newState = tool.onPanUpdate(
        state,
        createDragUpdateDetails(
          const Offset(10, 10),
          localPosition: const Offset(75, 45),
        ),
        const Size(100, 100),
      );

      final updatedAngle = newState.entities.first as AngleEntity;
      expect(updatedAngle.p1, const Offset(0.2, 0.2));
      expect(updatedAngle.p2!.dx, closeTo(0.75, 0.001));
      expect(updatedAngle.p2!.dy, closeTo(0.45, 0.001));
    });

    test(
      'onPanUpdate moves the entire shape relatively if no point is selected',
      () {
        final line = DrawingEntity.line(
          id: 'L1',
          p1: const Offset(0.1, 0.1),
          p2: const Offset(0.9, 0.9),
          color: Colors.blue,
        ) as LineEntity;
        final state = WorkspaceState(
          entities: [line],
          selectedEntityId: 'L1',
          activeDragDetail: null, // Entire shape drag
        );

        final newState = tool.onPanUpdate(
          state,
          createDragUpdateDetails(
            const Offset(10, 10),
            localPosition: const Offset(50, 50),
          ),
          const Size(100, 100),
        );

        final updatedLine = newState.entities.first as LineEntity;
        expect(updatedLine.p1!.dx, closeTo(0.2, 0.001));
        expect(updatedLine.p1!.dy, closeTo(0.2, 0.001));
        expect(updatedLine.p2!.dx, closeTo(1.0, 0.001));
        expect(updatedLine.p2!.dy, closeTo(1.0, 0.001));
      },
    );

    test(
      'onPanEnd clears activeDragDetail while preserving updated entity state',
      () {
        const line = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.3, 0.4),
          p2: Offset(0.8, 0.9),
          color: Colors.blue,
        );
        final state = WorkspaceState(
          entities: [line],
          selectedEntityId: 'L1',
          activeDragDetail: const DragDetail.entityPoint(
            entityId: 'L1',
            pointIndex: 0,
          ),
        );

        final endState = tool.onPanEnd(
          state,
          DragEndDetails(),
          const Size(100, 100),
        );

        expect(endState.activeDragDetail, isNull);
        expect(endState.entities.first, line);
      },
    );

    test('onPanUpdate clamps dragged point within [0.0, 1.0]', () {
      const line = DrawingEntity.line(
        id: 'L1',
        p1: Offset(0.3, 0.4),
        p2: Offset(0.8, 0.9),
        color: Colors.blue,
      );
      final state = WorkspaceState(
        entities: [line],
        selectedEntityId: 'L1',
        activeDragDetail: const DragDetail.entityPoint(
          entityId: 'L1',
          pointIndex: 0,
        ),
      );

      // Drag way outside positive and negative canvas
      final clampedState = tool.onPanUpdate(
        state,
        createDragUpdateDetails(
          const Offset(200, 200),
          localPosition: const Offset(150, -50),
        ),
        const Size(100, 100),
      );

      final updatedLine = clampedState.entities.first as LineEntity;
      expect(updatedLine.p1!.dx, 1.0); // clamped from 1.5 to 1.0
      expect(updatedLine.p1!.dy, 0.0); // clamped from -0.5 to 0.0
    });
  });
}
