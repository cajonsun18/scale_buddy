import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/painters/drawing_entity_painter.dart';

import 'dart:ui' as ui;

void main() {
  group('Entity Painters', () {
    test('painters report correct visibility per workflow step', () {
      const calibPainter = CalibrationPainter();
      expect(calibPainter.isVisibleInStep(WorkflowStepType.calibrate), isTrue);
      expect(calibPainter.isVisibleInStep(WorkflowStepType.measure), isFalse);

      const linePainter = LinePainter();
      expect(linePainter.isVisibleInStep(WorkflowStepType.measure), isTrue);
      expect(linePainter.isVisibleInStep(WorkflowStepType.export), isTrue);
      expect(linePainter.isVisibleInStep(WorkflowStepType.calibrate), isFalse);

      const polyPainter = PolygonPainter();
      expect(polyPainter.isVisibleInStep(WorkflowStepType.measure), isTrue);
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

    test('EntityPainterDispatcher does not paint calibration entity in measure step', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(400, 800);

      final context = PaintContext(
        activeStep: WorkflowStepType.measure,
        primaryColor: Colors.blue,
        successColor: Colors.green,
        pointColor: Colors.white,
        isMobile: true,
      );

      const calibEntity = CalibrationEntity(
        id: 'calib_1',
        p1: Offset(0.2, 0.2),
        p2: Offset(0.8, 0.8),
        enteredDistance: 2.10,
        isConfirmed: true,
      );

      expect(
        () => EntityPainterDispatcher.paintEntity(
          canvas,
          size,
          calibEntity,
          context,
        ),
        returnsNormally,
      );

      const painter = CalibrationPainter();
      expect(painter.isVisibleInStep(WorkflowStepType.measure), isFalse);
    });

    test('CalibrationPainter paints across mobile states and desktop mode without throwing', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const mobileSize = Size(400, 800);
      const desktopSize = Size(1000, 800);

      final mobileContext = PaintContext(
        activeStep: WorkflowStepType.calibrate,
        primaryColor: const Color(0xFF38BDF8),
        successColor: const Color(0xFF10B981),
        pointColor: Colors.white,
        isMobile: true,
      );

      const painter = CalibrationPainter();

      // 1. Mobile with 1 point
      const calib1 = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.3, 0.4),
      ) as CalibrationEntity;
      expect(
        () => painter.paint(canvas, mobileSize, calib1, mobileContext),
        returnsNormally,
      );

      // 2. Mobile with 2 points & unconfirmed
      const calib2 = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.3, 0.2),
        p2: Offset(0.3, 0.7),
        enteredDistance: 2.10,
        selectedUnit: 'm',
      ) as CalibrationEntity;
      expect(
        () => painter.paint(canvas, mobileSize, calib2, mobileContext),
        returnsNormally,
      );

      // 3. Mobile confirmed state with checkmark & custom label offset
      const calibConfirmed = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.3, 0.2),
        p2: Offset(0.3, 0.7),
        enteredDistance: 2.10,
        selectedUnit: 'm',
        isConfirmed: true,
        customLabelOffset: Offset(0.1, 0.1),
      ) as CalibrationEntity;
      expect(
        () => painter.paint(canvas, mobileSize, calibConfirmed, mobileContext),
        returnsNormally,
      );

      // 4. Desktop mode
      final desktopContext = PaintContext(
        activeStep: WorkflowStepType.calibrate,
        primaryColor: const Color(0xFF38BDF8),
        successColor: const Color(0xFF10B981),
        pointColor: Colors.white,
        isMobile: false,
      );
      expect(
        () => painter.paint(canvas, desktopSize, calib2, desktopContext),
        returnsNormally,
      );
    });

    test(
      'HandlePainter draws standard and mobile handles without throwing',
      () {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => HandlePainter.drawStandard(
            canvas,
            const Offset(50, 50),
            fillColor: Colors.white,
            borderColor: Colors.blue,
          ),
          returnsNormally,
        );

        expect(
          () => HandlePainter.drawStandardList(
            canvas,
            [const Offset(10, 10), const Offset(20, 20)],
            fillColor: Colors.white,
            borderColor: Colors.red,
          ),
          returnsNormally,
        );

        expect(
          () => HandlePainter.drawMobile(
            canvas,
            const Offset(60, 60),
            strokeColor: Colors.cyan,
            drawHalo: true,
          ),
          returnsNormally,
        );

        expect(
          () => HandlePainter.drawMobile(
            canvas,
            const Offset(70, 70),
            strokeColor: Colors.cyan,
            drawHalo: false,
          ),
          returnsNormally,
        );
      },
    );

    test('LinePainter, RectanglePainter, PolygonPainter and AnglePainter paint handles', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(500, 500);
      final context = PaintContext(
        activeStep: WorkflowStepType.measure,
        primaryColor: Colors.blue,
        successColor: Colors.green,
        pointColor: Colors.white,
      );

      const line = DrawingEntity.line(
        id: 'l1',
        p1: Offset(0.1, 0.1),
        p2: Offset(0.9, 0.9),
        color: Colors.blue,
      ) as LineEntity;
      expect(
        () => const LinePainter().paint(canvas, size, line, context),
        returnsNormally,
      );

      const rect = DrawingEntity.rectangle(
        id: 'r1',
        p1: Offset(0.2, 0.2),
        p2: Offset(0.8, 0.8),
        color: Colors.amber,
      ) as RectangleEntity;
      expect(
        () => const RectanglePainter().paint(canvas, size, rect, context),
        returnsNormally,
      );

      const poly = DrawingEntity.polygon(
        id: 'p1',
        points: [Offset(0.1, 0.1), Offset(0.5, 0.1), Offset(0.3, 0.4)],
        isClosed: true,
        color: Colors.green,
      ) as PolygonEntity;
      expect(
        () => const PolygonPainter().paint(canvas, size, poly, context),
        returnsNormally,
      );

      const angle = DrawingEntity.angle(
        id: 'a1',
        p1: Offset(0.5, 0.5),
        p2: Offset(0.8, 0.8),
        color: Colors.orange,
      ) as AngleEntity;
      expect(
        () => const AnglePainter().paint(canvas, size, angle, context),
        returnsNormally,
      );
    });

    test('PerspectivePainter paints in desktop and mobile modes', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(600, 400);

      const perspective = DrawingEntity.perspective(
        id: 'persp_1',
        points: [
          Offset(0.1, 0.1),
          Offset(0.9, 0.1),
          Offset(0.8, 0.8),
          Offset(0.2, 0.8),
        ],
        color: Colors.orange,
      ) as PerspectiveEntity;

      final desktopContext = PaintContext(
        activeStep: WorkflowStepType.perspective,
        primaryColor: Colors.blue,
        successColor: Colors.green,
        pointColor: Colors.white,
        isMobile: false,
      );
      expect(
        () => const PerspectivePainter().paint(
          canvas,
          size,
          perspective,
          desktopContext,
        ),
        returnsNormally,
      );

      final mobileContext = PaintContext(
        activeStep: WorkflowStepType.perspective,
        primaryColor: Colors.blue,
        successColor: Colors.green,
        pointColor: Colors.white,
        isMobile: true,
      );
      expect(
        () => const PerspectivePainter().paint(
          canvas,
          size,
          perspective,
          mobileContext,
        ),
        returnsNormally,
      );

      // 3 points dashed preview in mobile
      const perspective3Points = DrawingEntity.perspective(
        id: 'persp_3',
        points: [Offset(0.1, 0.1), Offset(0.9, 0.1), Offset(0.8, 0.8)],
        color: Colors.orange,
      ) as PerspectiveEntity;
      expect(
        () => const PerspectivePainter().paint(
          canvas,
          size,
          perspective3Points,
          mobileContext,
        ),
        returnsNormally,
      );
    });

    test('LinePainter and RectanglePainter paint in mobile mode (Zustand 2 and Zustand 3)', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 800);
      final mobileContext = PaintContext(
        activeStep: WorkflowStepType.measure,
        primaryColor: const Color(0xFF38BDF8),
        successColor: const Color(0xFF10B981),
        pointColor: Colors.white,
        isMobile: true,
      );

      // 1. Line: Point 1 set (Zustand 2)
      const linePoint1 = DrawingEntity.line(
        id: 'L1',
        p1: Offset(0.3, 0.4),
        p2: null,
        color: Color(0xFF38BDF8),
      ) as LineEntity;
      expect(
        () =>
            const LinePainter().paint(canvas, size, linePoint1, mobileContext),
        returnsNormally,
      );

      // 2. Line: Completed (Zustand 3)
      const lineCompleted = DrawingEntity.line(
        id: 'L1',
        p1: Offset(0.3, 0.4),
        p2: Offset(0.7, 0.4),
        color: Color(0xFF38BDF8),
      ) as LineEntity;
      expect(
        () => const LinePainter().paint(
          canvas,
          size,
          lineCompleted,
          mobileContext,
        ),
        returnsNormally,
      );

      // 3. Rectangle: Point 1 set (Zustand 2)
      const rectPoint1 = DrawingEntity.rectangle(
        id: 'R1',
        p1: Offset(0.2, 0.3),
        p2: null,
        color: Color(0xFF10B981),
      ) as RectangleEntity;
      expect(
        () => const RectanglePainter().paint(
          canvas,
          size,
          rectPoint1,
          mobileContext,
        ),
        returnsNormally,
      );

      // 4. Rectangle: Completed (Zustand 3)
      const rectCompleted = DrawingEntity.rectangle(
        id: 'R1',
        p1: Offset(0.2, 0.3),
        p2: Offset(0.8, 0.7),
        color: Color(0xFF10B981),
      ) as RectangleEntity;
      expect(
        () => const RectanglePainter().paint(
          canvas,
          size,
          rectCompleted,
          mobileContext,
        ),
        returnsNormally,
      );

      // 5. Polygon: Point 1 set (Zustand 2)
      const polyPoint1 = DrawingEntity.polygon(
        id: 'P1',
        points: [Offset(0.2, 0.3)],
        color: Color(0xFFA855F7),
      ) as PolygonEntity;
      expect(
        () => const PolygonPainter().paint(
          canvas,
          size,
          polyPoint1,
          mobileContext,
        ),
        returnsNormally,
      );

      // 6. Polygon: Multiple points open
      const polyOpen = DrawingEntity.polygon(
        id: 'P1',
        points: [Offset(0.2, 0.3), Offset(0.5, 0.3), Offset(0.5, 0.6)],
        color: Color(0xFFA855F7),
      ) as PolygonEntity;
      expect(
        () =>
            const PolygonPainter().paint(canvas, size, polyOpen, mobileContext),
        returnsNormally,
      );

      // 7. Polygon: Completed (Zustand 3)
      const polyCompleted = PolygonEntity(
        id: 'P1',
        points: [Offset(0.2, 0.3), Offset(0.5, 0.3), Offset(0.5, 0.6)],
        color: Color(0xFFA855F7),
        isClosed: true,
      );
      expect(
        () => const PolygonPainter().paint(
          canvas,
          size,
          polyCompleted,
          mobileContext,
        ),
        returnsNormally,
      );

      // 8. Angle: Point 1 set (Zustand 2)
      const anglePoint1 = DrawingEntity.angle(
        id: 'A1',
        p1: Offset(0.2, 0.5),
        p2: null,
        color: Color(0xFFF59E0B),
      ) as AngleEntity;
      expect(
        () => const AnglePainter().paint(
          canvas,
          size,
          anglePoint1,
          mobileContext,
        ),
        returnsNormally,
      );

      // 9. Angle: Completed (Zustand 3)
      const angleCompleted = DrawingEntity.angle(
        id: 'A1',
        p1: Offset(0.2, 0.5),
        p2: Offset(0.6, 0.4),
        color: Color(0xFFF59E0B),
      ) as AngleEntity;
      expect(
        () => const AnglePainter().paint(
          canvas,
          size,
          angleCompleted,
          mobileContext,
        ),
        returnsNormally,
      );
    });
  });
}
