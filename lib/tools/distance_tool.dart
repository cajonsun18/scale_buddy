import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import '../theme/measure_tool_colors.dart';
import 'workspace_tool.dart';

class DistanceTool extends WorkspaceTool {
  const DistanceTool();

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final normPoint = normalizePosition(details.localPosition, size);

    // Find the currently open line (where p2 is null)
    final openLine = state.entities
        .whereType<LineEntity>()
        .where((l) => l.p2 == null)
        .lastOrNull;

    if (openLine == null) {
      // Start a new line
      final newId = 'L${DateTime.now().millisecondsSinceEpoch}';
      final newLine = DrawingEntity.line(
        id: newId,
        p1: normPoint,
        p2: null,
        color: MeasureToolColors.distance,
      ) as LineEntity;

      return state.addOrUpdateEntity(newLine).copyWith(selectedEntityId: newId);
    } else {
      // Add second point to existing line
      return state
          .updateEntity(openLine.id, (entity) {
            if (entity is LineEntity) {
              return entity.copyWith(p2: normPoint);
            }
            return entity;
          })
          .copyWith(selectedEntityId: null);
    }
  }

  @override
  WorkspaceState onCancel(WorkspaceState state) {
    final openLine = state.entities
        .whereType<LineEntity>()
        .where((l) => l.p2 == null)
        .lastOrNull;
    if (openLine != null) {
      return state.removeEntity(openLine.id).copyWith(selectedEntityId: null);
    }
    return state;
  }
}
