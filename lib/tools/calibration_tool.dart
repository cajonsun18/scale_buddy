import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import '../models/drag_detail.dart';
import '../utils/geometry_utils.dart';
import 'workspace_tool.dart';

/// Das Werkzeug für die Kalibrierung.
/// Komplett zustandslos (stateless).
class CalibrationTool extends WorkspaceTool {
  const CalibrationTool();

  static const String defaultCalibrationId = 'calib_1';
  static const double minPointDistance = 10.0;
  static const double hitTestRadius = 24.0;

  @override
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) {
    if (size.width == 0 || size.height == 0) return state;

    final calib = _getOrCreateCalib(state);
    if (calib.p1 != null && calib.p2 != null) {
      return state;
    }

    final normPoint = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );

    CalibrationEntity updatedCalib;
    if (calib.p1 == null) {
      updatedCalib = calib.copyWith(p1: normPoint);
    } else {
      final p1Pixel = calib.p1!.toPixel(size);
      final dist = (p1Pixel - details.localPosition).distance;
      if (dist >= minPointDistance) {
        updatedCalib = calib.copyWith(p2: normPoint);
      } else {
        updatedCalib = calib;
      }
    }

    return _replaceEntity(state, updatedCalib);
  }

  @override
  WorkspaceState onPanStart(
    WorkspaceState state,
    DragStartDetails details,
    Size size,
  ) {
    final calib = _getOrCreateCalib(state);

    double? dist1, dist2;

    if (calib.p1 != null) {
      final p1Pixel = calib.p1!.toPixel(size);
      dist1 = (p1Pixel - details.localPosition).distance;
    }
    if (calib.p2 != null) {
      final p2Pixel = calib.p2!.toPixel(size);
      dist2 = (p2Pixel - details.localPosition).distance;
    }

    DragDetail? dragDetail;
    if (dist1 != null &&
        dist1 <= hitTestRadius &&
        (dist2 == null || dist1 <= dist2)) {
      dragDetail = const DragDetail.calibrationPoint(isP1: true);
    } else if (dist2 != null && dist2 <= hitTestRadius) {
      dragDetail = const DragDetail.calibrationPoint(isP1: false);
    }

    return state.copyWith(activeDragDetail: dragDetail);
  }

  @override
  WorkspaceState onPanUpdate(
    WorkspaceState state,
    DragUpdateDetails details,
    Size size,
  ) {
    final dragDetail = state.activeDragDetail;
    if (dragDetail == null || size.width == 0 || size.height == 0) return state;

    final calib = _getOrCreateCalib(state);
    final newDx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final newDy = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
    final newNormPoint = Offset(newDx, newDy);

    CalibrationEntity updatedCalib = calib;

    final isP1Drag = switch (dragDetail) {
      DragDetailCalibrationPoint(isP1: true) => true,
      DragDetailEntityPoint(pointIndex: 0) => true,
      _ => false,
    };
    final isP2Drag = switch (dragDetail) {
      DragDetailCalibrationPoint(isP1: false) => true,
      DragDetailEntityPoint(pointIndex: 1) => true,
      _ => false,
    };

    if (isP1Drag) {
      if (calib.p2 != null) {
        final newPixel = newNormPoint.toPixel(size);
        final p2Pixel = calib.p2!.toPixel(size);
        if ((newPixel - p2Pixel).distance >= minPointDistance) {
          updatedCalib = calib.copyWith(p1: newNormPoint, isConfirmed: false);
        }
      } else {
        updatedCalib = calib.copyWith(p1: newNormPoint, isConfirmed: false);
      }
    } else if (isP2Drag) {
      if (calib.p1 != null) {
        final newPixel = newNormPoint.toPixel(size);
        final p1Pixel = calib.p1!.toPixel(size);
        if ((newPixel - p1Pixel).distance >= minPointDistance) {
          updatedCalib = calib.copyWith(p2: newNormPoint, isConfirmed: false);
        }
      } else {
        updatedCalib = calib.copyWith(p2: newNormPoint, isConfirmed: false);
      }
    }

    return _replaceEntity(state, updatedCalib);
  }

  @override
  WorkspaceState onPanEnd(
    WorkspaceState state,
    DragEndDetails details,
    Size size,
  ) {
    return state.copyWith(activeDragDetail: null);
  }

  CalibrationEntity _getOrCreateCalib(WorkspaceState state) {
    return state.entities.whereType<CalibrationEntity>().firstOrNull ??
        const DrawingEntity.calibration(id: defaultCalibrationId)
            as CalibrationEntity;
  }

  WorkspaceState _replaceEntity(
    WorkspaceState state,
    CalibrationEntity newCalib,
  ) {
    final newList = List<DrawingEntity>.from(state.entities);
    final index = newList.indexWhere((e) => e.id == newCalib.id);
    if (index >= 0) {
      newList[index] = newCalib;
    } else {
      newList.add(newCalib);
    }
    return state.copyWith(entities: newList);
  }
}
