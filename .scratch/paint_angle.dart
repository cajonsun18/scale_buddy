import 'dart:math';
import 'package:flutter/material.dart';
import '../models/entities/drawing_entity.dart';

void _paintAngle(Canvas canvas, Size size, AngleEntity angle, double strokeWidth) {
  final p1 = angle.p1;
  final p2 = angle.p2;

  if (p1 == null && p2 == null) return;

  final paintLine = Paint()
    ..color = angle.color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final paintHelper = Paint()
    ..color = angle.color.withValues(alpha: 0.5)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  final paintPoint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  final paintPointBorder = Paint()
    ..color = angle.color
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
      final helperEnd = Offset(p1Pixel.dx + (distance * direction), p1Pixel.dy);
      
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
      while (normalizedSweep > pi) normalizedSweep -= 2 * pi;
      while (normalizedSweep < -pi) normalizedSweep += 2 * pi;
      
      canvas.drawArc(rect, baseAngle, normalizedSweep, false, paintLine);

      // Arrowhead
      final arrowEndX = p1Pixel.dx + cos(angleRad) * (distance * 0.3);
      final arrowEndY = p1Pixel.dy + sin(angleRad) * (distance * 0.3);
      
      final tangentAngle = angleRad + (normalizedSweep > 0 ? pi / 2 : -pi / 2);
      
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
