import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/models/drag_detail.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';

void main() {
  group('CalibrationTool', () {
    const tool = CalibrationTool();
    const size = Size(1000, 1000);

    test('onTapUp sets p1 when empty', () {
      const state = WorkspaceState();
      final details = createTapUpDetails(const Offset(100, 100));

      final newState = tool.onTapUp(state, details, size);

      final calib = newState.entities
          .whereType<CalibrationEntity>()
          .firstOrNull;
      expect(calib, isNotNull);
      expect(calib?.p1, const Offset(0.1, 0.1));
      expect(calib?.p2, isNull);
    });

    test('onTapUp sets p2 if p1 exists and distance is sufficient', () {
      const state = WorkspaceState(
        entities: [
          DrawingEntity.calibration(
            id: CalibrationTool.defaultCalibrationId,
            p1: Offset(0.1, 0.1), // 100, 100 in pixels
          ),
        ],
      );

      final details = createTapUpDetails(const Offset(300, 100));

      final newState = tool.onTapUp(state, details, size);

      final calib = newState.entities.whereType<CalibrationEntity>().first;
      expect(calib.p1, const Offset(0.1, 0.1));
      expect(calib.p2, const Offset(0.3, 0.1));
    });

    test('onTapUp ignores p2 if too close to p1', () {
      const state = WorkspaceState(
        entities: [
          DrawingEntity.calibration(
            id: CalibrationTool.defaultCalibrationId,
            p1: Offset(0.1, 0.1),
          ),
        ],
      );

      // Distance is 5px (< minPointDistance)
      final details = createTapUpDetails(const Offset(105, 100));

      final newState = tool.onTapUp(state, details, size);

      final calib = newState.entities.whereType<CalibrationEntity>().first;
      expect(calib.p1, const Offset(0.1, 0.1));
      expect(calib.p2, isNull);
    });

    test('onPanStart detects hit on p1', () {
      const state = WorkspaceState(
        entities: [
          DrawingEntity.calibration(
            id: CalibrationTool.defaultCalibrationId,
            p1: Offset(0.1, 0.1),
          ),
        ],
      );

      final details = DragStartDetails(
        localPosition: const Offset(102, 102), // within hitTestRadius
        globalPosition: const Offset(102, 102),
      );

      final newState = tool.onPanStart(state, details, size);
      expect(
        newState.activeDragDetail,
        const DragDetail.calibrationPoint(isP1: true),
      );
    });

    test('onPanUpdate moves p1 and unconfirms', () {
      const state = WorkspaceState(
        activeDragDetail: DragDetail.calibrationPoint(isP1: true),
        entities: [
          DrawingEntity.calibration(
            id: CalibrationTool.defaultCalibrationId,
            p1: Offset(0.1, 0.1),
            isConfirmed: true,
          ),
        ],
      );

      final details = DragUpdateDetails(
        localPosition: const Offset(200, 200),
        globalPosition: const Offset(200, 200),
      );

      final newState = tool.onPanUpdate(state, details, size);
      final calib = newState.entities.whereType<CalibrationEntity>().first;

      expect(calib.p1, const Offset(0.2, 0.2));
      expect(calib.isConfirmed, isFalse);
    });

    test('onPanEnd clears activeDragDetail', () {
      const state = WorkspaceState(
        activeDragDetail: DragDetail.calibrationPoint(isP1: true),
      );

      final details = DragEndDetails();
      final newState = tool.onPanEnd(state, details, size);

      expect(newState.activeDragDetail, isNull);
    });
  });
}
