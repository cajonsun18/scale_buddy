import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import 'geometry_utils.dart';

/// Zentrales Berechnungsmodul für Messwerte, Flächen, Längen, Winkel
/// und deren Positionierung auf dem Canvas sowie im PDF-Bericht.
class MeasurementCalculator {
  /// Formats distance in meters: `1.23 m`
  static String formatDistance(double distMeters) =>
      '${distMeters.toStringAsFixed(2)} m';

  /// Formats area in square meters: `4.56 m²`
  static String formatArea(double areaSquareMeters) =>
      '${areaSquareMeters.toStringAsFixed(2)} m²';

  /// Formats angle in degrees: `45.0°`
  static String formatAngle(double angleDeg) =>
      '${angleDeg.toStringAsFixed(1)}°';

  /// Calculates the real-world distance in meters between two normalized points.
  static double? calculateDistance(
    Offset p1,
    Offset p2,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null) return null;
    final p1Pix = p1.toPixel(size);
    final p2Pix = p2.toPixel(size);
    return (p2Pix - p1Pix).distance / pixelsPerMeter;
  }

  /// Calculates the real-world area in square meters of a rectangle defined by two opposite corners.
  static double? calculateRectangleArea(
    Offset p1,
    Offset p2,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null) return null;
    final widthMeters = ((p2.dx - p1.dx).abs() * size.width) / pixelsPerMeter;
    final heightMeters = ((p2.dy - p1.dy).abs() * size.height) / pixelsPerMeter;
    return widthMeters * heightMeters;
  }

  /// Calculates the real-world area in square meters of a closed polygon.
  static double? calculatePolygonArea(
    List<Offset> points,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null || points.length < 3) return null;
    final areaPix = GeometryUtils.calculatePolygonAreaPixel(points, size);
    return areaPix / (pixelsPerMeter * pixelsPerMeter);
  }

  /// Calculates the angle in degrees relative to the horizontal axis.
  static double calculateAngle(Offset p1, Offset p2, Size size) {
    final p1Pix = p1.toPixel(size);
    final p2Pix = p2.toPixel(size);
    return GeometryUtils.calculateAngleToHorizontal(p1Pix, p2Pix);
  }

  /// Returns the formatted measurement string for the given entity.
  static String? getMeasurementText(
    DrawingEntity entity,
    Size size,
    double? pixelsPerMeter,
  ) {
    return entity.map(
      calibration: (_) => null,
      perspective: (_) => null,
      line: (line) {
        if (line.p1 == null || line.p2 == null) return null;
        final dist = calculateDistance(
          line.p1!,
          line.p2!,
          size,
          pixelsPerMeter,
        );
        return dist != null ? formatDistance(dist) : null;
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final area = calculateRectangleArea(
          rect.p1!,
          rect.p2!,
          size,
          pixelsPerMeter,
        );
        return area != null ? formatArea(area) : null;
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final area = calculatePolygonArea(poly.points, size, pixelsPerMeter);
        return area != null ? formatArea(area) : null;
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final angleDeg = calculateAngle(angle.p1!, angle.p2!, size);
        return formatAngle(angleDeg);
      },
    );
  }

  /// Formatted width text (top edge) for rectangle.
  static String? getRectangleWidthText(
    RectangleEntity rect,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null || rect.p1 == null || rect.p2 == null) {
      return null;
    }
    final widthMeters =
        ((rect.p2!.dx - rect.p1!.dx).abs() * size.width) / pixelsPerMeter;
    return formatDistance(widthMeters);
  }

  /// Formatted height text (left edge) for rectangle.
  static String? getRectangleHeightText(
    RectangleEntity rect,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null || rect.p1 == null || rect.p2 == null) {
      return null;
    }
    final heightMeters =
        ((rect.p2!.dy - rect.p1!.dy).abs() * size.height) / pixelsPerMeter;
    return formatDistance(heightMeters);
  }

  /// Label position for the top edge of a rectangle.
  static Offset? getRectangleWidthLabelPosition(
    RectangleEntity rect,
    Size size,
  ) {
    if (rect.p1 == null || rect.p2 == null) return null;
    final centerPix = getMeasurementLabelPosition(rect, size);
    if (centerPix == null) return null;
    return Offset(centerPix.dx, rect.p1!.dy * size.height);
  }

  /// Label position for the left edge of a rectangle.
  static Offset? getRectangleHeightLabelPosition(
    RectangleEntity rect,
    Size size,
  ) {
    if (rect.p1 == null || rect.p2 == null) return null;
    final centerPix = getMeasurementLabelPosition(rect, size);
    if (centerPix == null) return null;
    return Offset(rect.p1!.dx * size.width, centerPix.dy);
  }

  /// Returns the pixel coordinates where the main label should be drawn.
  static Offset? getMeasurementLabelPosition(DrawingEntity entity, Size size) {
    return entity.map(
      calibration: (_) => null,
      perspective: (_) => null,
      line: (line) {
        if (line.p1 == null || line.p2 == null) return null;
        final p1Pix = line.p1!.toPixel(size);
        final p2Pix = line.p2!.toPixel(size);
        return Offset((p1Pix.dx + p2Pix.dx) / 2, (p1Pix.dy + p2Pix.dy) / 2);
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final p1Pix = rect.p1!.toPixel(size);
        final p2Pix = rect.p2!.toPixel(size);
        return Offset((p1Pix.dx + p2Pix.dx) / 2, (p1Pix.dy + p2Pix.dy) / 2);
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final centroidNorm = GeometryUtils.calculatePolygonCentroid(
          poly.points,
        );
        return centroidNorm.toPixel(size);
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final p1Pix = angle.p1!.toPixel(size);
        final p2Pix = angle.p2!.toPixel(size);
        final distance = (p2Pix - p1Pix).distance;
        final dx = p2Pix.dx - p1Pix.dx;
        final dy = p2Pix.dy - p1Pix.dy;
        final direction = dx >= 0 ? 1.0 : -1.0;
        final baseAngle = direction > 0 ? 0.0 : pi;
        final angleRad = atan2(dy, dx);

        double sweepAngle = angleRad - baseAngle;
        while (sweepAngle > pi) {
          sweepAngle -= 2 * pi;
        }
        while (sweepAngle < -pi) {
          sweepAngle += 2 * pi;
        }

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
