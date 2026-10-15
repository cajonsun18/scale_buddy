import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import '../theme/measure_tool_colors.dart';
import 'workspace_tool.dart';

class PolygonTool extends WorkspaceTool {
  const PolygonTool();

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final normPoint = normalizePosition(details.localPosition, size);

    // Find the currently open polygon
    final openPolygon = state.entities
        .whereType<PolygonEntity>()
        .where((p) => !p.isClosed)
        .lastOrNull;

    if (openPolygon == null) {
      // Start a new polygon
      final newId = 'P${DateTime.now().millisecondsSinceEpoch}';
      final newPolygon = DrawingEntity.polygon(
        id: newId,
        points: [normPoint],
        color: MeasureToolColors.polygon,
      ) as PolygonEntity;

      return state
          .addOrUpdateEntity(newPolygon)
          .copyWith(selectedEntityId: newId);
    } else {
      // Add point to existing polygon
      final firstPoint = openPolygon.points.first;
      final startPix = Offset(
        firstPoint.dx * size.width,
        firstPoint.dy * size.height,
      );

      final distance = (details.localPosition - startPix).distance;

      // Hit-Radius to close the polygon on start point (e.g. 28 pixels)
      if (distance < 28.0) {
        if (openPolygon.points.length >= 3) {
          return state
              .updateEntity(openPolygon.id, (entity) {
                if (entity is PolygonEntity) {
                  return entity.copyWith(isClosed: true);
                }
                return entity;
              })
              .copyWith(selectedEntityId: null);
        } else {
          // Ignore clicks too close to the start if we don't have enough points yet
          return state;
        }
      }

      // Hit-Radius to close the polygon via double tap or click on last point
      if (openPolygon.points.length >= 3) {
        final lastPoint = openPolygon.points.last;
        final lastPix = Offset(
          lastPoint.dx * size.width,
          lastPoint.dy * size.height,
        );
        final distanceToLast = (details.localPosition - lastPix).distance;
        if (distanceToLast < 28.0) {
          return state
              .updateEntity(openPolygon.id, (entity) {
                if (entity is PolygonEntity) {
                  return entity.copyWith(isClosed: true);
                }
                return entity;
              })
              .copyWith(selectedEntityId: null);
        }
      }

      return state.updateEntity(openPolygon.id, (entity) {
        if (entity is PolygonEntity) {
          return entity.copyWith(points: [...entity.points, normPoint]);
        }
        return entity;
      });
    }
  }

  @override
  WorkspaceState onCancel(WorkspaceState state) {
    final openPolygon = state.entities
        .whereType<PolygonEntity>()
        .where((p) => !p.isClosed)
        .lastOrNull;
    if (openPolygon != null) {
      return state
          .removeEntity(openPolygon.id)
          .copyWith(selectedEntityId: null);
    }
    return state;
  }
}
