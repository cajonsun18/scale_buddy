import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workflow_step.dart';

class PaintContext {
  final WorkflowStepType activeStep;
  final Color primaryColor;
  final Color successColor;
  final Color pointColor;
  final String? selectedEntityId;
  final bool isMobile;

  PaintContext({
    required this.activeStep,
    required this.primaryColor,
    required this.successColor,
    required this.pointColor,
    this.selectedEntityId,
    this.isMobile = false,
  });

  double getStrokeWidth(String id) => id == selectedEntityId ? 4.0 : 2.0;
}

abstract class DrawingEntityPainter<T extends DrawingEntity> {
  const DrawingEntityPainter();
  bool isVisibleInStep(WorkflowStepType step);
  void paint(Canvas canvas, Size size, T entity, PaintContext context);
}

class CalibrationPainter extends DrawingEntityPainter<CalibrationEntity> {
  const CalibrationPainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.calibrate;

  @override
  void paint(
    Canvas canvas,
    Size size,
    CalibrationEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    final color = entity.isConfirmed
        ? context.successColor
        : context.primaryColor;
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = context.pointColor
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;
    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }
}

class LinePainter extends DrawingEntityPainter<LineEntity> {
  const LinePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    LineEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    final paintLine = Paint()
      ..color = entity.color
      ..strokeWidth = context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = context.pointColor
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = entity.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;
    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }
}

class PolygonPainter extends DrawingEntityPainter<PolygonEntity> {
  const PolygonPainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    PolygonEntity entity,
    PaintContext context,
  ) {
    if (entity.points.isEmpty) return;

    final paintLine = Paint()
      ..color = entity.color
      ..strokeWidth = context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = entity.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final firstPoint = Offset(
      entity.points.first.dx * size.width,
      entity.points.first.dy * size.height,
    );
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < entity.points.length; i++) {
      final p = Offset(
        entity.points[i].dx * size.width,
        entity.points[i].dy * size.height,
      );
      path.lineTo(p.dx, p.dy);
    }

    if (entity.isClosed) {
      path.close();
      canvas.drawPath(path, paintFill);
    }

    canvas.drawPath(path, paintLine);

    final paintPoint = Paint()
      ..color = context.pointColor
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = entity.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final normPoint in entity.points) {
      final p = Offset(normPoint.dx * size.width, normPoint.dy * size.height);
      canvas.drawCircle(p, 5.0, paintPoint);
      canvas.drawCircle(p, 5.0, paintPointBorder);
    }
  }
}

class RectanglePainter extends DrawingEntityPainter<RectangleEntity> {
  const RectanglePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    RectangleEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    final paintLine = Paint()
      ..color = entity.color
      ..strokeWidth = context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = entity.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final paintPoint = Paint()
      ..color = context.pointColor
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = entity.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;
    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      final rectShape = Rect.fromPoints(p1Pixel, p2Pixel);
      canvas.drawRect(rectShape, paintFill);
      canvas.drawRect(rectShape, paintLine);
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }
}

class AnglePainter extends DrawingEntityPainter<AngleEntity> {
  const AnglePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    AngleEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    final paintLine = Paint()
      ..color = entity.color
      ..strokeWidth = context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintHelper = Paint()
      ..color = entity.color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = context.pointColor
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = entity.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;

    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);

      final distance = (p2Pixel - p1Pixel).distance;
      if (distance > 0) {
        final dx = p2Pixel.dx - p1Pixel.dx;
        final dy = p2Pixel.dy - p1Pixel.dy;

        final direction = dx >= 0 ? 1.0 : -1.0;
        final helperEnd = Offset(
          p1Pixel.dx + (distance * direction),
          p1Pixel.dy,
        );

        const dashWidth = 5.0;
        const dashSpace = 5.0;
        double currentX = p1Pixel.dx;
        if (direction > 0) {
          while (currentX < helperEnd.dx) {
            canvas.drawLine(
              Offset(currentX, p1Pixel.dy),
              Offset(min(currentX + dashWidth, helperEnd.dx), p1Pixel.dy),
              paintHelper,
            );
            currentX += dashWidth + dashSpace;
          }
        } else {
          while (currentX > helperEnd.dx) {
            canvas.drawLine(
              Offset(currentX, p1Pixel.dy),
              Offset(max(currentX - dashWidth, helperEnd.dx), p1Pixel.dy),
              paintHelper,
            );
            currentX -= dashWidth + dashSpace;
          }
        }

        final rect = Rect.fromCircle(center: p1Pixel, radius: distance * 0.3);
        final baseAngle = direction > 0 ? 0.0 : pi;

        final angleRad = atan2(dy, dx);
        final sweepAngle = angleRad - baseAngle;

        double normalizedSweep = sweepAngle;
        while (normalizedSweep > pi) {
          normalizedSweep -= 2 * pi;
        }
        while (normalizedSweep < -pi) {
          normalizedSweep += 2 * pi;
        }

        canvas.drawArc(rect, baseAngle, normalizedSweep, false, paintLine);

        final arrowEndX = p1Pixel.dx + cos(angleRad) * (distance * 0.3);
        final arrowEndY = p1Pixel.dy + sin(angleRad) * (distance * 0.3);

        final tangentAngle =
            angleRad + (normalizedSweep > 0 ? pi / 2 : -pi / 2);

        const arrowLength = 10.0;
        const arrowAngle = pi / 6;

        final arrowP1 = Offset(
          arrowEndX + cos(tangentAngle + pi + arrowAngle) * arrowLength,
          arrowEndY + sin(tangentAngle + pi + arrowAngle) * arrowLength,
        );
        final arrowP2 = Offset(
          arrowEndX + cos(tangentAngle + pi - arrowAngle) * arrowLength,
          arrowEndY + sin(tangentAngle + pi - arrowAngle) * arrowLength,
        );

        canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP1, paintLine);
        canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP2, paintLine);
      }
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }
}

class PerspectivePainter extends DrawingEntityPainter<PerspectiveEntity> {
  const PerspectivePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.perspective;

  @override
  void paint(
    Canvas canvas,
    Size size,
    PerspectiveEntity entity,
    PaintContext context,
  ) {
    if (entity.points.isEmpty) return;

    final isMobile = context.isMobile;
    final strokeColor = isMobile ? const Color(0xFF38BDF8) : entity.color;
    final fillColor = isMobile
        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
        : entity.color.withValues(alpha: 0.2);

    final paintLine = Paint()
      ..color = strokeColor
      ..strokeWidth = isMobile ? 2.5 : context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final firstPoint = Offset(
      entity.points.first.dx * size.width,
      entity.points.first.dy * size.height,
    );
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < entity.points.length; i++) {
      final p = Offset(
        entity.points[i].dx * size.width,
        entity.points[i].dy * size.height,
      );
      path.lineTo(p.dx, p.dy);
    }

    if (entity.points.length == 4) {
      path.close();
      canvas.drawPath(path, paintFill);
    }

    canvas.drawPath(path, paintLine);

    // Gestrichelte Linie zur Andeutung der Schließung (bei 3 Punkten)
    if (isMobile && entity.points.length == 3) {
      final p3 = Offset(
        entity.points[2].dx * size.width,
        entity.points[2].dy * size.height,
      );
      _drawDashedLine(
        canvas,
        p3,
        firstPoint,
        strokeColor.withValues(alpha: 0.6),
      );
    }

    // Punkte zeichnen
    final paintPointFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintOuterRing = Paint()
      ..color = isMobile ? strokeColor.withValues(alpha: 0.35) : strokeColor
      ..strokeWidth = isMobile ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    final paintPointBorder = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < entity.points.length; i++) {
      final normPoint = entity.points[i];
      final p = Offset(normPoint.dx * size.width, normPoint.dy * size.height);

      if (isMobile) {
        // Leuchtend blauer/cyanfarbener Kreis-Marker mit weißem Zentrum und transparentem Außenring
        canvas.drawCircle(p, 9.0, paintOuterRing);
        canvas.drawCircle(p, 5.0, paintPointFill);
        canvas.drawCircle(p, 5.0, paintPointBorder);

        // Dezentes Label ("Ecke 1", "Ecke 2", ...)
        _drawCornerLabel(canvas, size, p, i + 1, entity.points);
      } else {
        canvas.drawCircle(p, 6.0, paintPointFill);
        canvas.drawCircle(p, 6.0, paintPointBorder);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double drawn = 0.0;

    while (drawn < distance) {
      final startFraction = drawn / distance;
      final endFraction = min((drawn + dashWidth) / distance, 1.0);

      canvas.drawLine(
        Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
        Offset(p1.dx + dx * endFraction, p1.dy + dy * endFraction),
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  void _drawCornerLabel(
    Canvas canvas,
    Size size,
    Offset point,
    int index,
    List<Offset> allPoints,
  ) {
    final textSpan = TextSpan(
      text: 'Ecke $index',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Positionierung mit leichtem Offset, damit es nicht direkt auf dem Punkt liegt
    double labelX = point.dx + 12;
    double labelY = point.dy + 8;

    // Verhindern, dass Label aus dem Canvas ragt
    if (labelX + textPainter.width > size.width - 4) {
      labelX = point.dx - textPainter.width - 12;
    }
    if (labelY + textPainter.height > size.height - 4) {
      labelY = point.dy - textPainter.height - 8;
    }

    textPainter.paint(canvas, Offset(labelX, labelY));
  }
}

class EntityPainterDispatcher {
  static const _calibrationPainter = CalibrationPainter();
  static const _linePainter = LinePainter();
  static const _polygonPainter = PolygonPainter();
  static const _rectanglePainter = RectanglePainter();
  static const _anglePainter = AnglePainter();
  static const _perspectivePainter = PerspectivePainter();

  static void paintEntity(
    Canvas canvas,
    Size size,
    DrawingEntity entity,
    PaintContext context,
  ) {
    entity.map(
      calibration: (e) {
        if (_calibrationPainter.isVisibleInStep(context.activeStep)) {
          _calibrationPainter.paint(canvas, size, e, context);
        }
      },
      line: (e) {
        if (_linePainter.isVisibleInStep(context.activeStep)) {
          _linePainter.paint(canvas, size, e, context);
        }
      },
      polygon: (e) {
        if (_polygonPainter.isVisibleInStep(context.activeStep)) {
          _polygonPainter.paint(canvas, size, e, context);
        }
      },
      rectangle: (e) {
        if (_rectanglePainter.isVisibleInStep(context.activeStep)) {
          _rectanglePainter.paint(canvas, size, e, context);
        }
      },
      angle: (e) {
        if (_anglePainter.isVisibleInStep(context.activeStep)) {
          _anglePainter.paint(canvas, size, e, context);
        }
      },
      perspective: (e) {
        if (_perspectivePainter.isVisibleInStep(context.activeStep)) {
          _perspectivePainter.paint(canvas, size, e, context);
        }
      },
    );
  }
}
