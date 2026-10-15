import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/entities/drawing_entity.dart';
import 'geometry_utils.dart';

/// Zentrales Berechnungsmodul für Messwerte, Flächen, Längen, Winkel
/// und deren Positionierung auf dem Canvas sowie im PDF-Bericht.
class MeasurementCalculator {
  /// Formats distance in meters: `1.23 m` or `1,23 m`
  static String formatDistance(double distMeters, {bool useComma = false}) {
    final s = distMeters.toStringAsFixed(2);
    return '${useComma ? s.replaceAll('.', ',') : s} m';
  }

  /// Formats area in square meters: `4.56 m²` or `4,56 m²`
  static String formatArea(double areaSquareMeters, {bool useComma = false}) {
    final s = areaSquareMeters.toStringAsFixed(2);
    return '${useComma ? s.replaceAll('.', ',') : s} m²';
  }

  /// Formats angle in degrees: `45.0°` or `45,0°`
  static String formatAngle(double angleDeg, {bool useComma = false}) {
    final s = angleDeg.toStringAsFixed(1);
    return '${useComma ? s.replaceAll('.', ',') : s}°';
  }

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
    double? pixelsPerMeter, {
    int? index,
    bool useComma = false,
  }) {
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
        if (dist == null) return null;
        final prefix = index != null ? 'S$index: ' : '';
        return '$prefix${formatDistance(dist, useComma: useComma)}';
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final area = calculateRectangleArea(
          rect.p1!,
          rect.p2!,
          size,
          pixelsPerMeter,
        );
        if (area == null) return null;
        final prefix = index != null ? 'F$index: ' : '';
        return '$prefix${formatArea(area, useComma: useComma)}';
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final area = calculatePolygonArea(poly.points, size, pixelsPerMeter);
        if (area == null) return null;
        final prefix = index != null ? 'P$index: ' : '';
        return '$prefix${formatArea(area, useComma: useComma)}';
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final angleDeg = calculateAngle(angle.p1!, angle.p2!, size);
        final prefix = index != null ? 'W$index: ' : '';
        return '$prefix${formatAngle(angleDeg, useComma: useComma)}';
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
        final labelRadius = max(distance * 0.35, 35.0);
        return Offset(
          p1Pix.dx + cos(midAngleRad) * labelRadius,
          p1Pix.dy + sin(midAngleRad) * labelRadius - 16.0,
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

  /// Returns the formatted mobile measurement badge text with prefix (e.g. `S1: 1,04 m`, `F1: 4,00 m²`, `P1: 6,40 m²`, `W1: 4,2°`)
  static String? getMobileMeasurementBadgeText(
    DrawingEntity entity,
    Size size,
    double? pixelsPerMeter, {
    int index = 1,
    bool useComma = true,
  }) {
    return getMeasurementText(
      entity,
      size,
      pixelsPerMeter,
      index: index,
      useComma: useComma,
    );
  }

  /// Formatted width text (top edge) for rectangle on mobile (e.g. `1,74 m`).
  static String? getMobileRectangleWidthBadgeText(
    RectangleEntity rect,
    Size size,
    double? pixelsPerMeter, {
    bool useComma = true,
  }) {
    if (pixelsPerMeter == null || rect.p1 == null || rect.p2 == null) {
      return null;
    }
    final widthMeters =
        ((rect.p2!.dx - rect.p1!.dx).abs() * size.width) / pixelsPerMeter;
    return formatDistance(widthMeters, useComma: useComma);
  }

  /// Calculates the real-world perimeter in meters of a rectangle.
  static double? calculateRectanglePerimeter(
    Offset p1,
    Offset p2,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null) return null;
    final widthMeters = ((p2.dx - p1.dx).abs() * size.width) / pixelsPerMeter;
    final heightMeters = ((p2.dy - p1.dy).abs() * size.height) / pixelsPerMeter;
    return 2 * (widthMeters + heightMeters);
  }

  /// Calculates the real-world perimeter in meters of a closed polygon.
  static double? calculatePolygonPerimeter(
    List<Offset> points,
    Size size,
    double? pixelsPerMeter,
  ) {
    if (pixelsPerMeter == null || points.length < 2) return null;
    double totalPix = 0.0;
    for (int i = 0; i < points.length; i++) {
      final pCurrent = points[i].toPixel(size);
      final pNext = points[(i + 1) % points.length].toPixel(size);
      totalPix += (pNext - pCurrent).distance;
    }
    return totalPix / pixelsPerMeter;
  }

  /// Returns the short identifier for the entity (e.g. `F1`, `S1`, `P1`, `W1`).
  static String getMobileEntityIdentifier(
    DrawingEntity entity,
    List<DrawingEntity> allEntities,
  ) {
    return entity.map(
      calibration: (_) => 'CAL',
      perspective: (_) => 'PERSP',
      line: (l) {
        final lines = allEntities.whereType<LineEntity>().toList();
        final idx = lines.indexOf(l);
        return 'S${idx >= 0 ? idx + 1 : 1}';
      },
      rectangle: (r) {
        final rects = allEntities.whereType<RectangleEntity>().toList();
        final idx = rects.indexOf(r);
        return 'F${idx >= 0 ? idx + 1 : 1}';
      },
      polygon: (p) {
        final polys = allEntities.whereType<PolygonEntity>().toList();
        final idx = polys.indexOf(p);
        return 'P${idx >= 0 ? idx + 1 : 1}';
      },
      angle: (a) {
        final angles = allEntities.whereType<AngleEntity>().toList();
        final idx = angles.indexOf(a);
        return 'W${idx >= 0 ? idx + 1 : 1}';
      },
    );
  }

  /// Returns the type name of the entity for badge / status (e.g. `Rechteck`, `Strecke`, `Polygon`, `Dachwinkel`).
  static String getMobileEntityTypeName(
    DrawingEntity entity, {
    AppLocalizations? l10n,
  }) {
    return entity.map(
      calibration: (_) => l10n?.measureTypeCalibration ?? 'Kalibrierung',
      perspective: (_) => l10n?.measureTypePerspective ?? 'Perspektive',
      line: (_) => l10n?.measureTypeDistance ?? 'Strecke',
      rectangle: (_) => l10n?.measureTypeRectangle ?? 'Rechteck',
      polygon: (_) => l10n?.measureTypePolygon ?? 'Polygon',
      angle: (_) => l10n?.measureTypeAngle ?? 'Dachwinkel',
    );
  }

  /// Returns the title line in the inspector (e.g. `F1 · Rechteckfläche`).
  static String getMobileEntityTitle(
    DrawingEntity entity,
    List<DrawingEntity> allEntities, {
    AppLocalizations? l10n,
  }) {
    final identifier = getMobileEntityIdentifier(entity, allEntities);
    return entity.map(
      calibration: (_) =>
          '$identifier · ${l10n?.measureTypeCalibration ?? 'Kalibrierung'}',
      perspective: (_) =>
          '$identifier · ${l10n?.measureTypePerspective ?? 'Perspektive'}',
      line: (_) =>
          l10n?.measureTitleLine(identifier) ?? '$identifier · Streckenlänge',
      rectangle: (_) =>
          l10n?.measureTitleRectangle(identifier) ??
          '$identifier · Rechteckfläche',
      polygon: (_) =>
          l10n?.measureTitlePolygon(identifier) ??
          '$identifier · Polygonfläche',
      angle: (_) =>
          l10n?.measureTitleAngle(identifier) ?? '$identifier · Dachwinkel',
    );
  }

  /// Returns the detailed measurement description for the mobile inspector
  /// (e.g. `Fläche: 4,00 m² · Umfang: 8,08 m · 1,74 × 2,30 m`).
  static String? getMobileEntityDetails(
    DrawingEntity entity,
    Size size,
    double? pixelsPerMeter, {
    AppLocalizations? l10n,
    bool useComma = true,
  }) {
    if (pixelsPerMeter == null) return null;

    final lengthLabel = l10n?.measureInspectorLengthLabel ?? 'Länge';
    final areaLabel = l10n?.measureInspectorAreaLabel ?? 'Fläche';
    final perimeterLabel = l10n?.measureInspectorPerimeterLabel ?? 'Umfang';
    final angleLabel = l10n?.measureInspectorAngleLabel ?? 'Winkel';

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
        if (dist == null) return null;
        return '$lengthLabel: ${formatDistance(dist, useComma: useComma)}';
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final widthMeters =
            ((rect.p2!.dx - rect.p1!.dx).abs() * size.width) / pixelsPerMeter;
        final heightMeters =
            ((rect.p2!.dy - rect.p1!.dy).abs() * size.height) / pixelsPerMeter;
        final area = widthMeters * heightMeters;
        final perimeter = 2 * (widthMeters + heightMeters);

        final areaStr = formatArea(area, useComma: useComma);
        final perimStr = formatDistance(perimeter, useComma: useComma);
        final wStr = formatDistance(
          widthMeters,
          useComma: useComma,
        ).replaceAll(' m', '');
        final hStr = formatDistance(heightMeters, useComma: useComma);

        return '$areaLabel: $areaStr · $perimeterLabel: $perimStr · $wStr × $hStr';
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final area = calculatePolygonArea(poly.points, size, pixelsPerMeter);
        final perimeter = calculatePolygonPerimeter(
          poly.points,
          size,
          pixelsPerMeter,
        );
        if (area == null || perimeter == null) return null;
        return '$areaLabel: ${formatArea(area, useComma: useComma)} · $perimeterLabel: ${formatDistance(perimeter, useComma: useComma)}';
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final angleDeg = calculateAngle(angle.p1!, angle.p2!, size);
        return '$angleLabel: ${formatAngle(angleDeg, useComma: useComma)}';
      },
    );
  }
}
