import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/tools/polygon_tool.dart';

void main() {
  group('PolygonTool', () {
    const tool = PolygonTool();
    const size = Size(1000, 1000);

    test('onTapUp creates a new PolygonEntity if none is open', () {
      const state = WorkspaceState();
      final details = createTapUpDetails(const Offset(100, 200));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final entity = newState.entities.first;
      expect(entity, isA<PolygonEntity>());

      final polygon = entity as PolygonEntity;
      expect(polygon.points.length, 1);
      expect(polygon.points.first, const Offset(0.1, 0.2));
      expect(polygon.isClosed, false);
      expect(newState.selectedEntityId, polygon.id);
    });

    test('onTapUp adds a point to an existing open PolygonEntity', () {
      final initialPolygon = DrawingEntity.polygon(
        id: '1',
        points: [const Offset(0.1, 0.2)],
        color: Colors.green,
      ) as PolygonEntity;
      final state = WorkspaceState(
        entities: [initialPolygon],
        selectedEntityId: '1',
      );

      final details = createTapUpDetails(const Offset(300, 400));

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final polygon = newState.entities.first as PolygonEntity;
      expect(polygon.points.length, 2);
      expect(polygon.points[0], const Offset(0.1, 0.2));
      expect(polygon.points[1], const Offset(0.3, 0.4));
      expect(polygon.isClosed, false);
    });

    test('onTapUp closes the polygon if clicked near start point and has >= 3 points', () {
      final initialPolygon = DrawingEntity.polygon(
        id: '1',
        points: [
          const Offset(0.1, 0.2), // Start point
          const Offset(0.3, 0.2), // Point 2
          const Offset(0.3, 0.4), // Point 3
        ],
        color: Colors.green,
      ) as PolygonEntity;
      final state = WorkspaceState(
        entities: [initialPolygon],
        selectedEntityId: '1',
      );

      // Click near the start point (0.1 * 1000 = 100, 0.2 * 1000 = 200)
      final details = TapUpDetails(
        localPosition: const Offset(
          105,
          205,
        ), // Distance is sqrt(25 + 25) = ~7.07 < 20
        globalPosition: const Offset(105, 205),
        kind: PointerDeviceKind.touch,
      );

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final polygon = newState.entities.first as PolygonEntity;
      expect(polygon.points.length, 3); // Does not add the point, just closes
      expect(polygon.isClosed, true);
    });

    test('onTapUp does not close the polygon if clicked near start point but has < 3 points', () {
      final initialPolygon = DrawingEntity.polygon(
        id: '1',
        points: [
          const Offset(0.1, 0.2), // Start point
          const Offset(0.3, 0.2), // Point 2
        ],
        color: Colors.green,
      ) as PolygonEntity;
      final state = WorkspaceState(
        entities: [initialPolygon],
        selectedEntityId: '1',
      );

      // Click near the start point (0.1 * 1000 = 100, 0.2 * 1000 = 200)
      final details = TapUpDetails(
        localPosition: const Offset(105, 205), // Distance < 20
        globalPosition: const Offset(105, 205),
        kind: PointerDeviceKind.touch,
      );

      final newState = tool.onTapUp(state, details, size);

      expect(newState.entities.length, 1);
      final polygon = newState.entities.first as PolygonEntity;
      expect(polygon.points.length, 2); // Ignores the click because it cannot be closed yet and is too close to start
      expect(polygon.isClosed, false);
    });
  });
}
