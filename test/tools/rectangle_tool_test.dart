import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/tools/rectangle_tool.dart';

void main() {
  group('RectangleTool', () {
    const tool = RectangleTool();
    const size = Size(1000, 1000);

    test('onTapUp creates a new RectangleEntity if none is open', () {
      const state = WorkspaceState();
      final details = createTapUpDetails(const Offset(100, 200));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final entity = newState.entities.first;
      expect(entity, isA<RectangleEntity>());

      final rect = entity as RectangleEntity;
      expect(rect.p1, const Offset(0.1, 0.2));
      expect(rect.p2, isNull);

      expect(newState.selectedEntityId, rect.id);
    });

    test('onTapUp sets p2 of the active open rectangle', () {
      final initialRect = DrawingEntity.rectangle(
        id: '1',
        p1: const Offset(0.1, 0.2),
        p2: null,
        color: Colors.orange,
      ) as RectangleEntity;
      final state = WorkspaceState(
        entities: [initialRect],
        selectedEntityId: '1',
      );

      final details = createTapUpDetails(const Offset(300, 400));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final rect = newState.entities.first as RectangleEntity;
      expect(rect.p1, const Offset(0.1, 0.2)); // p1 remains unchanged
      expect(rect.p2, const Offset(0.3, 0.4)); // p2 is updated
    });
  });
}
