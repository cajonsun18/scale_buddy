import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import 'geometry_utils.dart';

class MeasurementCalculator {
  /// Returns the formatted measurement string for the given entity.
  static String? getMeasurementText(
    DrawingEntity entity,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null) return null;

    return entity.map(
      calibration: (_) => null,
      perspective: (_) => null,
      line: (line) {
        if (line.p1 == null || line.p2 == null) return null;
        final p1Pix = Offset(
          line.p1!.dx * size.width,
          line.p1!.dy * size.height,
        );
        final p2Pix = Offset(
          line.p2!.dx * size.width,
          line.p2!.dy * size.height,
        );
        final distMeters = (p2Pix - p1Pix).distance / pixelsPerMeter;
        return '${distMeters.toStringAsFixed(2)} m';
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final p1Pix = Offset(
          rect.p1!.dx * size.width,
          rect.p1!.dy * size.height,
        );
        final p2Pix = Offset(
          rect.p2!.dx * size.width,
          rect.p2!.dy * size.height,
        );
        final area =
            ((p2Pix.dx - p1Pix.dx).abs() / pixelsPerMeter) *
            ((p2Pix.dy - p1Pix.dy).abs() / pixelsPerMeter);
        return '${area.toStringAsFixed(2)} m²';
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final areaPix = GeometryUtils.calculatePolygonAreaPixel(
          poly.points,
          size,
        );
        final areaMeters = areaPix / (pixelsPerMeter * pixelsPerMeter);
        return '${areaMeters.toStringAsFixed(2)} m²';
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final p1Pix = Offset(
          angle.p1!.dx * size.width,
          angle.p1!.dy * size.height,
        );
        final p2Pix = Offset(
          angle.p2!.dx * size.width,
          angle.p2!.dy * size.height,
        );
        final angleDeg = GeometryUtils.calculateAngleToHorizontal(p1Pix, p2Pix);
        return '${angleDeg.toStringAsFixed(1)}°';
      },
    );
  }

  /// Returns the pixel coordinates where the label should be drawn.
  static Offset? getMeasurementLabelPosition(DrawingEntity entity, Size size) {
    return entity.map(
      calibration: (_) => null,
      perspective: (_) => null,
      line: (line) {
        if (line.p1 == null || line.p2 == null) return null;
        final p1Pix = Offset(
          line.p1!.dx * size.width,
          line.p1!.dy * size.height,
        );
        final p2Pix = Offset(
          line.p2!.dx * size.width,
          line.p2!.dy * size.height,
        );
        return Offset((p1Pix.dx + p2Pix.dx) / 2, (p1Pix.dy + p2Pix.dy) / 2);
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final p1Pix = Offset(
          rect.p1!.dx * size.width,
          rect.p1!.dy * size.height,
        );
        final p2Pix = Offset(
          rect.p2!.dx * size.width,
          rect.p2!.dy * size.height,
        );
        return Offset((p1Pix.dx + p2Pix.dx) / 2, (p1Pix.dy + p2Pix.dy) / 2);
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final centroidNorm = GeometryUtils.calculatePolygonCentroid(
          poly.points,
        );
        return Offset(
          centroidNorm.dx * size.width,
          centroidNorm.dy * size.height,
        );
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final p1Pix = Offset(
          angle.p1!.dx * size.width,
          angle.p1!.dy * size.height,
        );
        final p2Pix = Offset(
          angle.p2!.dx * size.width,
          angle.p2!.dy * size.height,
        );
        final distance = (p2Pix - p1Pix).distance;
        final dx = p2Pix.dx - p1Pix.dx;
        final dy = p2Pix.dy - p1Pix.dy;
        final direction = dx >= 0 ? 1.0 : -1.0;
        final baseAngle = direction > 0 ? 0.0 : pi;
        final angleRad = atan2(dy, dx);

        double sweepAngle = angleRad - baseAngle;
        while (sweepAngle > pi) sweepAngle -= 2 * pi;
        while (sweepAngle < -pi) sweepAngle += 2 * pi;

        final midAngleRad = baseAngle + (sweepAngle / 2);
        final labelRadius = distance * 0.4;
        return Offset(
          p1Pix.dx + cos(midAngleRad) * labelRadius,
          p1Pix.dy + sin(midAngleRad) * labelRadius,
        );
      },
    );
  }

  /// Returns the type label for the measurement table
  static String? getMeasurementTypeLabel(DrawingEntity entity) {
    return entity.map(
      calibration: (_) => null,
      perspective: (_) => null,
      line: (_) => 'Linie (Länge)',
      rectangle: (_) => 'Rechteck (Fläche)',
      polygon: (_) => 'Polygon (Fläche)',
      angle: (_) => 'Winkel',
    );
  }
}
