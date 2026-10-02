import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import 'workspace_tool.dart';

class AngleTool extends WorkspaceTool {
  const AngleTool();

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final normPoint = normalizePosition(details.localPosition, size);

    // Find the currently open angle line (where p2 is null)
    final openAngle = state.entities
        .whereType<AngleEntity>()
        .where((a) => a.p2 == null)
        .lastOrNull;

    if (openAngle == null) {
      // Start a new angle line
      final newId = 'A${DateTime.now().millisecondsSinceEpoch}';
      final newAngle = DrawingEntity.angle(
        id: newId,
        p1: normPoint,
        p2: null,
        color: Colors.purple, // Distinct color for angles
      ) as AngleEntity;

      return state
          .addOrUpdateEntity(newAngle)
          .copyWith(selectedEntityId: newId);
    } else {
      // Add second point to existing angle line
      return state.updateEntity(openAngle.id, (entity) {
        if (entity is AngleEntity) {
          return entity.copyWith(p2: normPoint);
        }
        return entity;
      });
    }
  }

  @override
  WorkspaceState onCancel(WorkspaceState state) {
    final openAngle = state.entities
        .whereType<AngleEntity>()
        .where((a) => a.p2 == null)
        .lastOrNull;
    if (openAngle != null) {
      return state.removeEntity(openAngle.id);
    }
    return state;
  }
}
