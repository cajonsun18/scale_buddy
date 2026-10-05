import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/workspace_state.dart';
import '../models/drag_detail.dart';
import '../models/entities/drawing_entity.dart';
import '../utils/geometry_utils.dart';
import 'workspace_tool.dart';

class SelectTool extends WorkspaceTool {
  const SelectTool();

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final tapPoint = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );

    String? hitEntityId;
    const threshold = 0.05; // 5% of screen as hit radius

    for (final entity in state.entities.reversed) {
      if (entity is CalibrationEntity) continue;

      bool hit = entity.map(
        calibration: (_) => false,
        line: (line) {
          if (line.p1 == null || line.p2 == null) return false;
          return GeometryUtils.isPointNearLine(
            tapPoint,
            line.p1!,
            line.p2!,
            threshold,
          );
        },
        rectangle: (rect) {
          if (rect.p1 == null || rect.p2 == null) return false;
          return GeometryUtils.isPointInRect(tapPoint, rect.p1!, rect.p2!);
        },
        polygon: (polygon) {
          if (polygon.points.length < 3) return false;
          return GeometryUtils.isPointInPolygon(tapPoint, polygon.points);
        },
        angle: (angle) {
          if (angle.p1 == null || angle.p2 == null) return false;
          return GeometryUtils.isPointNearLine(
            tapPoint,
            angle.p1!,
            angle.p2!,
            threshold,
          );
        },
        perspective: (_) => false,
      );

      if (hit) {
        hitEntityId = entity.id;
        break;
      }
    }

    if (hitEntityId != null) {
      return state.copyWith(selectedEntityId: hitEntityId);
    }

    // Wenn nichts getroffen wurde, Auswahl aufheben
    return state.copyWith(selectedEntityId: null);
  }

  @override
  WorkspaceState onPanStart(
    WorkspaceState state,
    DragStartDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final tapPoint = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );

    final selectedId = state.selectedEntityId;
    if (selectedId != null) {
      final selectedEntity = state.entities
          .where((e) => e.id == selectedId)
          .firstOrNull;
      if (selectedEntity != null) {
        int? hitPointIndex;
        const pointThreshold = 0.05;

        final points = selectedEntity.map(
          calibration: (_) => <Offset?>[],
          line: (l) => [l.p1, l.p2],
          rectangle: (r) => [r.p1, r.p2], // p1=top-left, p2=bottom-right
          polygon: (p) => p.points,
          angle: (a) => [a.p1, a.p2],
          perspective: (_) => <Offset?>[],
        );

        for (int i = 0; i < points.length; i++) {
          final p = points[i];
          if (p != null && (p - tapPoint).distance <= pointThreshold) {
            hitPointIndex = i;
            break;
          }
        }

        if (hitPointIndex != null) {
          return state.copyWith(
            activeDragDetail: DragDetail.entityPoint(
              entityId: selectedId,
              pointIndex: hitPointIndex,
            ),
          );
        }
      }
    }

    final tapDetails = TapUpDetails(
      kind: details.kind ?? PointerDeviceKind.touch,
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    );
    return onTapUp(state, tapDetails, size).copyWith(activeDragDetail: null);
  }

  @override
  WorkspaceState onPanUpdate(
    WorkspaceState state,
    DragUpdateDetails details,
    Size size,
  ) {
    final selectedId = state.selectedEntityId;
    if (selectedId == null) return state;

    final delta = Offset(
      details.delta.dx / size.width,
      details.delta.dy / size.height,
    );

    final dragDetail = state.activeDragDetail;
    if (dragDetail is DragDetailEntityPoint &&
        dragDetail.entityId == selectedId) {
      // Einzelnen Punkt verschieben
      final pointIdx = (dragDetail).pointIndex;
      return state.updateEntity(selectedId, (entity) {
        return entity.map(
          calibration: (e) => e,
          line: (e) => e.copyWith(
            p1: pointIdx == 0 && e.p1 != null ? e.p1! + delta : e.p1,
            p2: pointIdx == 1 && e.p2 != null ? e.p2! + delta : e.p2,
          ),
          rectangle: (e) => e.copyWith(
            p1: pointIdx == 0 && e.p1 != null ? e.p1! + delta : e.p1,
            p2: pointIdx == 1 && e.p2 != null ? e.p2! + delta : e.p2,
          ),
          polygon: (e) {
            final newPoints = List<Offset>.from(e.points);
            if (pointIdx >= 0 && pointIdx < newPoints.length) {
              newPoints[pointIdx] += delta;
            }
            return e.copyWith(points: newPoints);
          },
          angle: (e) => e.copyWith(
            p1: pointIdx == 0 && e.p1 != null ? e.p1! + delta : e.p1,
            p2: pointIdx == 1 && e.p2 != null ? e.p2! + delta : e.p2,
          ),
          perspective: (e) => e,
        );
      });
    }

    // Ganze Form verschieben
    return state.updateEntity(selectedId, (entity) {
      return entity.map(
        calibration: (e) => e, // Calibration is not moved by SelectTool
        line: (e) => e.copyWith(
          p1: e.p1 != null ? e.p1! + delta : null,
          p2: e.p2 != null ? e.p2! + delta : null,
        ),
        rectangle: (e) => e.copyWith(
          p1: e.p1 != null ? e.p1! + delta : null,
          p2: e.p2 != null ? e.p2! + delta : null,
        ),
        polygon: (e) =>
            e.copyWith(points: e.points.map((p) => p + delta).toList()),
        angle: (e) => e.copyWith(
          p1: e.p1 != null ? e.p1! + delta : null,
          p2: e.p2 != null ? e.p2! + delta : null,
        ),
        perspective: (e) => e,
      );
    });
  }

  @override
  WorkspaceState onPanEnd(
    WorkspaceState state,
    DragEndDetails details,
    Size size,
  ) {
    return state.copyWith(activeDragDetail: null);
  }
}
