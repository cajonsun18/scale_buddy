import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:scale_buddy/models/drag_detail.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/tools/perspective_tool.dart';

void main() {
  group('PerspectiveTool', () {
    const tool = PerspectiveTool();
    const size = Size(1000, 1000);

    test('onTapUp creates a new PerspectiveEntity with one point', () {
      const state = WorkspaceState();
      final details = createTapUpDetails(const Offset(100, 200));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final entity = newState.entities.first as PerspectiveEntity;
      expect(entity.points.length, 1);
      expect(entity.points.first, const Offset(0.1, 0.2));
      expect(newState.selectedEntityId, entity.id);
    });

    test('onTapUp adds points up to 4 points', () {
      WorkspaceState state = const WorkspaceState();

      // Tap 1
      state = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(100, 100)),
        size,
      );
      // Tap 2
      state = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(900, 100)),
        size,
      );
      // Tap 3
      state = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(900, 900)),
        size,
      );
      // Tap 4
      state = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(100, 900)),
        size,
      );

      final entity = state.entities.first as PerspectiveEntity;
      expect(entity.points.length, 4);
      expect(entity.points[3], const Offset(0.1, 0.9));

      // Tap 5 (should be ignored)
      state = tool.onTapUp(
        state,
        createTapUpDetails(const Offset(500, 500)),
        size,
      );
      final entityAfter = state.entities.first as PerspectiveEntity;
      expect(entityAfter.points.length, 4); // Still 4
    });

    test('onPanStart selects point if clicked near it', () {
      final initialEntity = DrawingEntity.perspective(
        id: '1',
        points: [const Offset(0.1, 0.1), const Offset(0.9, 0.1)],
        color: Colors.orange,
      ) as PerspectiveEntity;

      final state = WorkspaceState(entities: [initialEntity]);

      // Drag near the second point (0.9, 0.1) -> (900, 100)
      final details = createDragStartDetails(
        const Offset(910, 100),
      ); // within 30px threshold

      final newState = tool.onPanStart(state, details, size);

      expect(newState.activeDragDetail, isNotNull);
      expect(newState.activeDragDetail, isA<DragDetailEntityPoint>());
      final dragDetail = newState.activeDragDetail as DragDetailEntityPoint;
      expect(dragDetail.entityId, '1');
      expect(dragDetail.pointIndex, 1); // Second point
    });

    test('onPanUpdate moves the selected point', () {
      final initialEntity = DrawingEntity.perspective(
        id: '1',
        points: [const Offset(0.1, 0.1), const Offset(0.9, 0.1)],
        color: Colors.orange,
      ) as PerspectiveEntity;

      final state = WorkspaceState(
        entities: [initialEntity],
        activeDragDetail: const DragDetail.entityPoint(
          entityId: '1',
          pointIndex: 1,
        ),
      );

      // Drag to (800, 200) -> 0.8, 0.2
      final details = createDragUpdateDetails(
        const Offset(-100, 100), // delta
        localPosition: const Offset(800, 200),
      );

      final newState = tool.onPanUpdate(state, details, size);

      final updatedEntity = newState.entities.first as PerspectiveEntity;
      expect(updatedEntity.points[1], const Offset(0.8, 0.2));
    });
  });
}
