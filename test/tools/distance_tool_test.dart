import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/tools/distance_tool.dart';

void main() {
  group('DistanceTool', () {
    const tool = DistanceTool();
    const size = Size(1000, 1000);

    test('onTapUp creates a new LineEntity if none is open', () {
      const state = WorkspaceState();
      final details = createTapUpDetails(const Offset(100, 200));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final entity = newState.entities.first;
      expect(entity, isA<LineEntity>());

      final line = entity as LineEntity;
      expect(line.p1, const Offset(0.1, 0.2));
      expect(line.p2, isNull);

      expect(newState.selectedEntityId, line.id);
    });

    test('onTapUp sets p2 of the active open line', () {
      final initialLine = DrawingEntity.line(
        id: '1',
        p1: const Offset(0.1, 0.2),
        p2: null,
        color: Colors.blue,
      ) as LineEntity;
      final state = WorkspaceState(
        entities: [initialLine],
        selectedEntityId: '1',
      );

      final details = createTapUpDetails(const Offset(300, 400));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final line = newState.entities.first as LineEntity;
      expect(line.p1, const Offset(0.1, 0.2)); // p1 remains unchanged
      expect(line.p2, const Offset(0.3, 0.4)); // p2 is updated
    });

    test('onTapUp creates a second line if the first is complete', () {
      final initialLine = DrawingEntity.line(
        id: '1',
        p1: const Offset(0.1, 0.2),
        p2: const Offset(0.3, 0.4),
        color: Colors.blue,
      ) as LineEntity;
      final state = WorkspaceState(entities: [initialLine]);

      final details = createTapUpDetails(const Offset(500, 500));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 2);
      final line2 = newState.entities.last as LineEntity;
      expect(line2.id, isNot('1'));
      expect(line2.p1, const Offset(0.5, 0.5));
      expect(line2.p2, isNull);
    });
  });
}
