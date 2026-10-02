import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import 'workspace_tool.dart';

class RectangleTool extends WorkspaceTool {
  const RectangleTool();

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final normPoint = normalizePosition(details.localPosition, size);

    // Find the currently open rectangle (where p2 is null)
    final openRect = state.entities
        .whereType<RectangleEntity>()
        .where((r) => r.p2 == null)
        .lastOrNull;

    if (openRect == null) {
      // Start a new rectangle
      final newId = 'R${DateTime.now().millisecondsSinceEpoch}';
      final newRect = DrawingEntity.rectangle(
        id: newId,
        p1: normPoint,
        p2: null,
        color: Colors.orange,
      ) as RectangleEntity;

      return state.addOrUpdateEntity(newRect).copyWith(selectedEntityId: newId);
    } else {
      // Add second point to existing rectangle, ensuring p1 is top-left and p2 is bottom-right
      return state.updateEntity(openRect.id, (entity) {
        if (entity is RectangleEntity && entity.p1 != null) {
          final p1 = entity.p1!;
          final minX = p1.dx < normPoint.dx ? p1.dx : normPoint.dx;
          final minY = p1.dy < normPoint.dy ? p1.dy : normPoint.dy;
          final maxX = p1.dx > normPoint.dx ? p1.dx : normPoint.dx;
          final maxY = p1.dy > normPoint.dy ? p1.dy : normPoint.dy;

          return entity.copyWith(
            p1: Offset(minX, minY),
            p2: Offset(maxX, maxY),
          );
        }
        return entity;
      });
    }
  }

  @override
  WorkspaceState onCancel(WorkspaceState state) {
    final openRect = state.entities
        .whereType<RectangleEntity>()
        .where((r) => r.p2 == null)
        .lastOrNull;
    if (openRect != null) {
      return state.removeEntity(openRect.id);
    }
    return state;
  }
}
