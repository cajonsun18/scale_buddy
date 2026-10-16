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
      calibration: (calib) {
        final unit = calib.selectedUnit;
        if (calib.enteredDistance != null && calib.enteredDistance! > 0) {
          final s = calib.enteredDistance!.toStringAsFixed(2);
          final formatted = useComma ? s.replaceAll('.', ',') : s;
          return calib.isConfirmed ? '✓ $formatted $unit' : '$formatted $unit';
        }
        return calib.isConfirmed ? '✓ -- $unit' : '-- $unit';
      },
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

  /// Schwellenwert für das Umklappen des oberen Rechteck-Breiten-Badges (in Pixel).
  static const double rectangleWidthFlipThreshold = 35.0;

  /// Schwellenwert für das Umklappen des linken Rechteck-Höhen-Badges (in Pixel).
  static const double rectangleHeightFlipThreshold = 60.0;

  /// Berechnet die Platzierung für das Breiten-Badge eines Rechtecks (oben oder unten umgeklappt).
  static RectangleBadgePlacement? getRectangleWidthBadgePlacement(
    RectangleEntity rect,
    Size size,
  ) {
    if (rect.p1 == null || rect.p2 == null) return null;
    final p1Pix = rect.p1!.toPixel(size);
    final p2Pix = rect.p2!.toPixel(size);
    final centerX = (p1Pix.dx + p2Pix.dx) / 2;
    final minY = min(p1Pix.dy, p2Pix.dy);
    final maxY = max(p1Pix.dy, p2Pix.dy);
    final isFlipped = minY < rectangleWidthFlipThreshold;

    final y = isFlipped ? maxY : minY;
    final translation = isFlipped
        ? const Offset(-0.5, 0.6)
        : const Offset(-0.5, -1.6);

    return RectangleBadgePlacement(
      position: Offset(centerX, y),
      isFlipped: isFlipped,
      widgetTranslation: translation,
    );
  }

  /// Berechnet die Platzierung für das Höhen-Badge eines Rechtecks (links oder rechts umgeklappt).
  static RectangleBadgePlacement? getRectangleHeightBadgePlacement(
    RectangleEntity rect,
    Size size,
  ) {
    if (rect.p1 == null || rect.p2 == null) return null;
    final p1Pix = rect.p1!.toPixel(size);
    final p2Pix = rect.p2!.toPixel(size);
    final minX = min(p1Pix.dx, p2Pix.dx);
    final maxX = max(p1Pix.dx, p2Pix.dx);
    final centerY = (p1Pix.dy + p2Pix.dy) / 2;
    final isFlipped = minX < rectangleHeightFlipThreshold;

    final x = isFlipped ? maxX : minX;
    final translation = isFlipped
        ? const Offset(0.4, -0.5)
        : const Offset(-1.4, -0.5);

    return RectangleBadgePlacement(
      position: Offset(x, centerY),
      isFlipped: isFlipped,
      widgetTranslation: translation,
    );
  }

  /// Gibt die Standard-Position für das Breiten-Label eines Rechtecks zurück (Mitte obere Kante).
  static Offset? getRectangleWidthLabelPosition(
    RectangleEntity rect,
    Size size,
  ) {
    if (rect.p1 == null || rect.p2 == null) return null;
    final p1Pix = rect.p1!.toPixel(size);
    final p2Pix = rect.p2!.toPixel(size);
    return Offset((p1Pix.dx + p2Pix.dx) / 2, min(p1Pix.dy, p2Pix.dy));
  }

  /// Gibt die Standard-Position für das Höhen-Label eines Rechtecks zurück (Mitte linke Kante).
  static Offset? getRectangleHeightLabelPosition(
    RectangleEntity rect,
    Size size,
  ) {
    if (rect.p1 == null || rect.p2 == null) return null;
    final p1Pix = rect.p1!.toPixel(size);
    final p2Pix = rect.p2!.toPixel(size);
    return Offset(min(p1Pix.dx, p2Pix.dx), (p1Pix.dy + p2Pix.dy) / 2);
  }

  /// Geschätzte maximale Breite der Mess-Pille für Kollisionsprüfungen.
  static const double defaultPillWidth = 140.0;

  /// Geschätzte Höhe der Mess-Pille für Kollisionsprüfungen.
  static const double defaultPillHeight = 32.0;

  /// Schutzradius für Kontrollpunkte/Anfasser.
  static const double defaultHandleRadius = 14.0;

  /// Schutzradius für Kontrollpunkte/Anfasser bei Selektions-Ghosting auf dem Desktop.
  static const double desktopHandleProtectionRadius = 18.0;

  /// Schutzradius für Kontrollpunkte/Anfasser bei Selektions-Ghosting auf Mobile/Touch.
  static const double mobileHandleProtectionRadius = 24.0;

  /// Opazität für kollidierende Fremdpillen im Selektionsmodus.
  static const double ghostedPillOpacity = 0.15;

  /// Berechnet die Flächen-Label-Position für ein Rechteck.
  /// Bei sehr kompakten Rechtecken weicht die Pille nach außen ab,
  /// sodass die Eckpunkte frei bleiben.
  static Offset calculateRectangleAreaLabelPosition(
    Offset p1Pix,
    Offset p2Pix,
    Size size, {
    double pillWidth = defaultPillWidth,
    double pillHeight = defaultPillHeight,
    double handleRadius = defaultHandleRadius,
  }) {
    final minX = min(p1Pix.dx, p2Pix.dx);
    final maxX = max(p1Pix.dx, p2Pix.dx);
    final minY = min(p1Pix.dy, p2Pix.dy);
    final maxY = max(p1Pix.dy, p2Pix.dy);
    final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);

    final corners = [
      Offset(minX, minY),
      Offset(maxX, minY),
      Offset(minX, maxY),
      Offset(maxX, maxY),
    ];

    bool collides(Offset candidate) {
      final rect = Rect.fromCenter(
        center: candidate,
        width: pillWidth,
        height: pillHeight,
      );
      for (final c in corners) {
        if (rect.overlaps(Rect.fromCircle(center: c, radius: handleRadius))) {
          return true;
        }
      }
      return false;
    }

    if (!collides(center)) {
      return center;
    }

    final belowCandidate = Offset(center.dx, maxY + pillHeight / 2 + 14.0);
    if (!collides(belowCandidate) &&
        belowCandidate.dy + pillHeight / 2 <= size.height) {
      return belowCandidate;
    }

    final rightCandidate = Offset(maxX + pillWidth / 2 + 14.0, center.dy);
    if (!collides(rightCandidate) &&
        rightCandidate.dx + pillWidth / 2 <= size.width) {
      return rightCandidate;
    }

    final aboveCandidate = Offset(center.dx, minY - pillHeight / 2 - 14.0);
    if (!collides(aboveCandidate) && aboveCandidate.dy - pillHeight / 2 >= 0) {
      return aboveCandidate;
    }

    return center;
  }

  /// Berechnet die Label-Position für ein Polygon.
  /// Liegt das Zentrum zu nah an einem Eckpunkt (kompaktes oder schmales Polygon),
  /// weicht die Pille ab, sodass kein Eckpunkt überdeckt wird.
  static Offset calculatePolygonLabelPosition(
    List<Offset> pointsPix,
    Size size, {
    double pillWidth = defaultPillWidth,
    double pillHeight = defaultPillHeight,
    double handleRadius = defaultHandleRadius,
  }) {
    if (pointsPix.isEmpty) return Offset.zero;
    if (pointsPix.length == 1) return pointsPix.first;

    final centroidNorm = GeometryUtils.calculatePolygonCentroid(
      pointsPix
          .map((p) => Offset(p.dx / size.width, p.dy / size.height))
          .toList(),
    );
    final centroid = centroidNorm.toPixel(size);

    bool collides(Offset candidate) {
      final rect = Rect.fromCenter(
        center: candidate,
        width: pillWidth,
        height: pillHeight,
      );
      for (final p in pointsPix) {
        if (rect.overlaps(Rect.fromCircle(center: p, radius: handleRadius))) {
          return true;
        }
      }
      return false;
    }

    bool isInsideCanvas(Offset candidate) {
      final halfW = pillWidth / 2;
      final halfH = pillHeight / 2;
      return candidate.dx - halfW >= 0 &&
          candidate.dx + halfW <= size.width &&
          candidate.dy - halfH >= 0 &&
          candidate.dy + halfH <= size.height;
    }

    if (!collides(centroid) && isInsideCanvas(centroid)) {
      return centroid;
    }

    const directions = [
      Offset(0, -1),
      Offset(1, -1),
      Offset(-1, -1),
      Offset(0, 1),
      Offset(1, 1),
      Offset(-1, 1),
      Offset(1, 0),
      Offset(-1, 0),
    ];

    Offset? bestCandidate;
    double bestDistance = double.infinity;

    for (final dir in directions) {
      final normDir = dir / dir.distance;
      for (double dist = 24.0; dist <= 120.0; dist += 6.0) {
        final candidate = centroid + normDir * dist;
        if (!collides(candidate) && isInsideCanvas(candidate)) {
          if (dist < bestDistance) {
            bestDistance = dist;
            bestCandidate = candidate;
          }
          break;
        }
      }
    }

    return bestCandidate ?? centroid;
  }

  /// Berechnet die Label-Position für eine Winkelmessung.
  /// Platziert die Pille auf der Winkelhalbierenden mit ausreichendem Radius,
  /// sodass weder der Scheitelpunkt (p1) noch der Schenkel-Endpunkt (p2) überdeckt werden.
  static Offset calculateAngleLabelPosition(
    Offset p1Pix,
    Offset p2Pix,
    Size size, {
    double pillWidth = defaultPillWidth,
    double pillHeight = defaultPillHeight,
    double handleRadius = defaultHandleRadius,
  }) {
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
    final unitRay = Offset(cos(midAngleRad), sin(midAngleRad));

    bool collidesWithHandles(Offset candidate) {
      final rect = Rect.fromCenter(
        center: candidate,
        width: pillWidth,
        height: pillHeight,
      );
      if (rect.overlaps(Rect.fromCircle(center: p1Pix, radius: handleRadius))) {
        return true;
      }
      if (distance > 0 &&
          rect.overlaps(Rect.fromCircle(center: p2Pix, radius: handleRadius))) {
        return true;
      }
      return false;
    }

    double radius = max(60.0, distance * 0.45);

    for (int i = 0; i < 30; i++) {
      final candidate = p1Pix + unitRay * radius;
      if (!collidesWithHandles(candidate)) {
        return candidate;
      }
      radius += 8.0;
    }

    return p1Pix + unitRay * radius;
  }

  /// Standardmäßiger orthogonaler Versatz für Strecken-Labels (in Pixel).
  static const double defaultLineLabelOffset = 32.0;

  /// Geschätzte halbe Höhe der Mess-Pille für Kollisionsprüfungen am oberen Canvas-Rand.
  static const double defaultPillHalfHeight = 16.0;

  /// Berechnet die Label-Position für eine Strecke mit orthogonalem Versatz (32 px).
  /// Klappt automatisch nach unten um (Auto-Flip), wenn die Pille über den oberen Bildrand ragen würde.
  static Offset calculateLineLabelPosition(
    Offset p1Pix,
    Offset p2Pix,
    Size size, {
    double offsetDistance = defaultLineLabelOffset,
    double pillHalfHeight = defaultPillHalfHeight,
  }) {
    final midpoint = Offset(
      (p1Pix.dx + p2Pix.dx) / 2,
      (p1Pix.dy + p2Pix.dy) / 2,
    );
    final dx = p2Pix.dx - p1Pix.dx;
    final dy = p2Pix.dy - p1Pix.dy;
    final length = sqrt(dx * dx + dy * dy);

    if (length == 0) return midpoint;

    // Normalenvektor senkrecht zur Strecke: (-dy, dx) / length
    Offset normal = Offset(-dy / length, dx / length);
    // Standardmäßig nach "oben" ausrichten (in Screen-Koordinaten ist dy negativ = oben)
    if (normal.dy > 0 || (normal.dy == 0 && normal.dx < 0)) {
      normal = -normal;
    }

    final candidate = midpoint + normal * offsetDistance;
    // Auto-Flip: Wenn der obere Rand der Pille über den oberen Canvas-Rand ragen würde (dy < 0)
    if (candidate.dy - pillHalfHeight < 0) {
      return midpoint - normal * offsetDistance;
    }
    return candidate;
  }

  /// Returns the pixel coordinates where the main label should be drawn.
  static Offset? getMeasurementLabelPosition(DrawingEntity entity, Size size) {
    final basePos = entity.map(
      calibration: (calib) {
        if (calib.p1 == null || calib.p2 == null) return null;
        final p1Pix = calib.p1!.toPixel(size);
        final p2Pix = calib.p2!.toPixel(size);
        return calculateLineLabelPosition(p1Pix, p2Pix, size);
      },
      perspective: (_) => null,
      line: (line) {
        if (line.p1 == null || line.p2 == null) return null;
        final p1Pix = line.p1!.toPixel(size);
        final p2Pix = line.p2!.toPixel(size);
        return calculateLineLabelPosition(p1Pix, p2Pix, size);
      },
      rectangle: (rect) {
        if (rect.p1 == null || rect.p2 == null) return null;
        final p1Pix = rect.p1!.toPixel(size);
        final p2Pix = rect.p2!.toPixel(size);
        return calculateRectangleAreaLabelPosition(p1Pix, p2Pix, size);
      },
      polygon: (poly) {
        if (poly.points.length < 3 || !poly.isClosed) return null;
        final pointsPix = poly.points.map((p) => p.toPixel(size)).toList();
        return calculatePolygonLabelPosition(pointsPix, size);
      },
      angle: (angle) {
        if (angle.p1 == null || angle.p2 == null) return null;
        final p1Pix = angle.p1!.toPixel(size);
        final p2Pix = angle.p2!.toPixel(size);
        return calculateAngleLabelPosition(p1Pix, p2Pix, size);
      },
    );

    if (basePos == null) return null;
    final customOffset = entity.customLabelOffset;
    if (customOffset != null) {
      return basePos + customOffset.toPixel(size);
    }
    return basePos;
  }

  /// Returns the anchor point (center / midpoint / centroid / apex) for the measurement entity.
  /// Used as the origin for leader lines when the label is displaced.
  static Offset? getMeasurementAnchorPosition(DrawingEntity entity, Size size) {
    return entity.map(
      calibration: (c) {
        if (c.p1 == null || c.p2 == null) return null;
        final p1 = c.p1!.toPixel(size);
        final p2 = c.p2!.toPixel(size);
        return Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      },
      perspective: (_) => null,
      line: (l) {
        if (l.p1 == null || l.p2 == null) return null;
        final p1 = l.p1!.toPixel(size);
        final p2 = l.p2!.toPixel(size);
        return Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      },
      rectangle: (r) {
        if (r.p1 == null || r.p2 == null) return null;
        final p1 = r.p1!.toPixel(size);
        final p2 = r.p2!.toPixel(size);
        return Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      },
      polygon: (p) {
        if (p.points.length < 3 || !p.isClosed) return null;
        return GeometryUtils.calculatePolygonCentroid(p.points).toPixel(size);
      },
      angle: (a) {
        if (a.p1 == null) return null;
        return a.p1!.toPixel(size);
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

  /// Schätzt die Bounding-Box einer Mess-Pille anhand des Texts und des Selektionszustands.
  static Size estimatePillSize(
    String text, {
    bool isSelected = false,
    bool isMobile = false,
    bool hasDelete = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: (isMobile || isSelected)
              ? FontWeight.bold
              : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final hPadding = isMobile ? 20.0 : 16.0;
    const vPadding = 8.0;
    final borderWidth = isSelected ? 4.0 : (isMobile ? 3.0 : 2.4);
    final deleteWidth = (isSelected && hasDelete) ? 30.0 : 0.0;

    final width = textPainter.width + hPadding + borderWidth + deleteWidth;
    final height = max(
      textPainter.height + vPadding + borderWidth,
      (isSelected && hasDelete) ? 30.0 : 24.0,
    );
    return Size(max(width, 40.0), max(height, 24.0));
  }

  /// Ermittelt alle interaktiven Kontrollpunkte/Anfasser einer Entität in Pixelkoordinaten.
  static List<Offset> getEntityHandlePoints(DrawingEntity entity, Size size) {
    return entity.map(
      calibration: (c) => [
        if (c.p1 != null) c.p1!.toPixel(size),
        if (c.p2 != null) c.p2!.toPixel(size),
      ],
      perspective: (p) => p.points.map((pt) => pt.toPixel(size)).toList(),
      line: (l) => [
        if (l.p1 != null) l.p1!.toPixel(size),
        if (l.p2 != null) l.p2!.toPixel(size),
      ],
      rectangle: (r) {
        if (r.p1 == null || r.p2 == null) return <Offset>[];
        final p1Pix = r.p1!.toPixel(size);
        final p2Pix = r.p2!.toPixel(size);
        return [
          p1Pix,
          Offset(p2Pix.dx, p1Pix.dy),
          p2Pix,
          Offset(p1Pix.dx, p2Pix.dy),
        ];
      },
      polygon: (p) => p.points.map((pt) => pt.toPixel(size)).toList(),
      angle: (a) => [
        if (a.p1 != null) a.p1!.toPixel(size),
        if (a.p2 != null) a.p2!.toPixel(size),
      ],
    );
  }

  /// Prüft, ob eine Fremdpille mit der Schutzzone eines selektierten Elements kollidiert.
  /// Schutzzone = Griffe (Kreis mit Trefferradius) + Bounding-Boxes der selektierten Pillen.
  static bool checkPillCollision({
    required Rect foreignPillRect,
    required List<Offset> selectedHandles,
    required List<Rect> selectedPillRects,
    required double handleRadius,
  }) {
    for (final handle in selectedHandles) {
      if (GeometryUtils.rectIntersectsCircle(
        foreignPillRect,
        handle,
        handleRadius,
      )) {
        return true;
      }
    }
    for (final selPill in selectedPillRects) {
      if (foreignPillRect.overlaps(selPill)) {
        return true;
      }
    }
    return false;
  }
}

/// Datenstruktur für die berechnete Platzierung eines Kanten-Badges eines Rechtecks.
class RectangleBadgePlacement {
  /// Berechnete Basis-Position (Zentrum der Kante bzw. umgeklappt).
  final Offset position;

  /// Gibt an, ob das Badge aufgrund von Platzmangel am Bildrand auf die gegenüberliegende Seite umgeklappt wurde.
  final bool isFlipped;

  /// Relativer Translations-Offset für die widget-basierte Platzierung.
  final Offset widgetTranslation;

  const RectangleBadgePlacement({
    required this.position,
    required this.isFlipped,
    required this.widgetTranslation,
  });
}
