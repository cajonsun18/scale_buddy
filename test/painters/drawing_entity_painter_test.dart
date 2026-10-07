import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/painters/drawing_entity_painter.dart';

import 'dart:ui' as ui;

void main() {
  group('Entity Painters', () {
    test('CalibrationPainter visibility', () {
      const painter = CalibrationPainter();
      expect(painter.isVisibleInStep(WorkflowStepType.calibrate), isTrue);
      expect(painter.isVisibleInStep(WorkflowStepType.measure), isFalse);
    });

    test('LinePainter visibility', () {
      const painter = LinePainter();
      expect(painter.isVisibleInStep(WorkflowStepType.measure), isTrue);
      expect(painter.isVisibleInStep(WorkflowStepType.export), isTrue);
      expect(painter.isVisibleInStep(WorkflowStepType.calibrate), isFalse);
    });

    test('PolygonPainter visibility', () {
      const painter = PolygonPainter();
      expect(painter.isVisibleInStep(WorkflowStepType.measure), isTrue);
    });

    test('EntityPainterDispatcher does not throw when painting', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(100, 100);

      final context = PaintContext(
        activeStep: WorkflowStepType.measure,
        primaryColor: Colors.blue,
        successColor: Colors.green,
        pointColor: Colors.white,
      );

      final lineEntity = DrawingEntity.line(
        id: '1',
        p1: const Offset(0, 0),
        p2: const Offset(1, 1),
        color: Colors.red,
      );

      expect(
        () => EntityPainterDispatcher.paintEntity(
          canvas,
          size,
          lineEntity,
          context,
        ),
        returnsNormally,
      );
    });
  });
}
