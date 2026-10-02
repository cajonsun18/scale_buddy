import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/tools/angle_tool.dart';

void main() {
  group('AngleTool', () {
    const tool = AngleTool();
    const size = Size(1000, 1000);

    test('onTapUp creates a new AngleEntity if none is open', () {
      const state = WorkspaceState();
      final details = createTapUpDetails(const Offset(100, 200));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final entity = newState.entities.first;
      expect(entity, isA<AngleEntity>());

      final angle = entity as AngleEntity;
      expect(angle.p1, const Offset(0.1, 0.2));
      expect(angle.p2, isNull);

      expect(newState.selectedEntityId, angle.id);
    });

    test('onTapUp sets p2 of the active open angle', () {
      final initialAngle = DrawingEntity.angle(
        id: '1',
        p1: const Offset(0.1, 0.2),
        p2: null,
        color: Colors.purple,
      ) as AngleEntity;
      final state = WorkspaceState(
        entities: [initialAngle],
        selectedEntityId: '1',
      );

      final details = createTapUpDetails(const Offset(300, 400));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final angle = newState.entities.first as AngleEntity;
      expect(angle.p1, const Offset(0.1, 0.2)); // p1 remains unchanged
      expect(angle.p2, const Offset(0.3, 0.4)); // p2 is updated
    });
  });
}
