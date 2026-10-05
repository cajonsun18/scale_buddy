import 'package:flutter/material.dart';

import '../models/drag_detail.dart';
import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import 'workspace_tool.dart';

class PerspectiveTool extends WorkspaceTool {
  const PerspectiveTool();

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final normPoint = normalizePosition(details.localPosition, size);

    // Find the existing perspective entity
    final perspective = state.entities
        .whereType<PerspectiveEntity>()
        .lastOrNull;

    if (perspective == null) {
      // Start a new perspective entity
      final newId = 'Persp${DateTime.now().millisecondsSinceEpoch}';
      final newEntity = DrawingEntity.perspective(
        id: newId,
        points: [normPoint],
        color: Colors.orange,
      ) as PerspectiveEntity;

      return state
          .addOrUpdateEntity(newEntity)
          .copyWith(selectedEntityId: newId);
    } else {
      if (perspective.points.length < 4) {
        // Add point
        return state.updateEntity(perspective.id, (entity) {
          if (entity is PerspectiveEntity) {
            return entity.copyWith(points: [...entity.points, normPoint]);
          }
          return entity;
        });
      }
    }
    return state;
  }

  @override
  WorkspaceState onPanStart(
    WorkspaceState state,
    DragStartDetails details,
    Size size,
  ) {
    // Find if we touched near any point of the perspective entity
    final perspective = state.entities
        .whereType<PerspectiveEntity>()
        .lastOrNull;

    if (perspective == null) return state;

    final normPoint = normalizePosition(details.localPosition, size);

    // Find closest point
    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < perspective.points.length; i++) {
      final p = perspective.points[i];
      final pPix = Offset(p.dx * size.width, p.dy * size.height);
      final touchPix = Offset(
        normPoint.dx * size.width,
        normPoint.dy * size.height,
      );
      final dist = (pPix - touchPix).distance;
      if (dist < 30.0 && dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    if (closestIndex != -1) {
      return state.copyWith(
        activeDragDetail: DragDetail.entityPoint(
          entityId: perspective.id,
          pointIndex: closestIndex,
        ),
      );
    }

    return state;
  }

  @override
  WorkspaceState onPanUpdate(
    WorkspaceState state,
    DragUpdateDetails details,
    Size size,
  ) {
    final dragDetail = state.activeDragDetail;
    if (dragDetail == null || dragDetail is! DragDetailEntityPoint) {
      return state;
    }

    final perspective = state.entities
        .whereType<PerspectiveEntity>()
        .where((e) => e.id == dragDetail.entityId)
        .firstOrNull;

    if (perspective != null) {
      final normPoint = normalizePosition(details.localPosition, size);

      return state.updateEntity(perspective.id, (entity) {
        if (entity is PerspectiveEntity) {
          final newPoints = List<Offset>.from(entity.points);
          if (dragDetail.pointIndex >= 0 &&
              dragDetail.pointIndex < newPoints.length) {
            newPoints[dragDetail.pointIndex] = normPoint;
          }
          return entity.copyWith(points: newPoints);
        }
        return entity;
      });
    }

    return state;
  }

  @override
  WorkspaceState onPanEnd(
    WorkspaceState state,
    DragEndDetails details,
    Size size,
  ) {
    return state.copyWith(activeDragDetail: null);
  }

  @override
  WorkspaceState onCancel(WorkspaceState state) {
    final perspective = state.entities
        .whereType<PerspectiveEntity>()
        .lastOrNull;
    if (perspective != null) {
      return state.removeEntity(perspective.id);
    }
    return state;
  }
}
