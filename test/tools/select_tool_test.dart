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

    test(
      'onPanUpdate moves a single point if DragDetailEntityPoint is active',
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
          activeDragDetail: const DragDetail.entityPoint(
            entityId: 'L1',
            pointIndex: 0,
          ),
        );

        final newState = tool.onPanUpdate(
          state,
          createDragUpdateDetails(const Offset(10, 0)),
          const Size(100, 100),
        );

        final updatedLine = newState.entities.first as LineEntity;
        expect(updatedLine.p1!.dx, closeTo(0.2, 0.001));
        expect(updatedLine.p1!.dy, closeTo(0.1, 0.001));
        expect(updatedLine.p2!.dx, 0.9); // Unchanged
      },
    );

    test('onPanUpdate moves the entire shape if no point is selected', () {
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
        createDragUpdateDetails(const Offset(10, 10)),
        const Size(100, 100),
      );

      final updatedLine = newState.entities.first as LineEntity;
      expect(updatedLine.p1!.dx, closeTo(0.2, 0.001));
      expect(updatedLine.p1!.dy, closeTo(0.2, 0.001));
      expect(updatedLine.p2!.dx, closeTo(1.0, 0.001));
      expect(updatedLine.p2!.dy, closeTo(1.0, 0.001));
    });
  });
}
