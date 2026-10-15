import 'dart:math';

import 'package:flutter/material.dart';

import 'calibration_input_utils.dart';

class GeometryUtils {
  /// Skaliert einen normalisierten Punkt (0.0 bis 1.0) auf die gegebene Canvas-/Bild-Größe.
  static Offset toPixel(Offset normalized, Size size) {
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }

  /// Skaliert einen optionalen normalisierten Punkt (0.0 bis 1.0) auf die gegebene Canvas-/Bild-Größe.
  static Offset? toPixelOrNull(Offset? normalized, Size size) {
    if (normalized == null) return null;
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }

  /// Skaliert eine Liste normalisierter Punkte auf die gegebene Canvas-/Bild-Größe.
  static List<Offset> toPixels(List<Offset> normalizedPoints, Size size) {
    return normalizedPoints
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
  }

  /// Normalisiert einen Pixelpunkt bezüglich der gegebenen Canvas-/Bild-Größe (0.0 bis 1.0).
  static Offset toNormalized(Offset pixel, Size size) {
    if (size.width == 0 || size.height == 0) return Offset.zero;
    return Offset(pixel.dx / size.width, pixel.dy / size.height);
  }

  /// Berechnet den Flächenschwerpunkt (Centroid) eines Polygons
  static Offset calculatePolygonCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;
    if (points.length == 2) {
      return Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );
    }

    double signedArea = 0.0;
    double cx = 0.0;
    double cy = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p0 = points[i];
      final p1 = points[(i + 1) % points.length];
      final a = p0.dx * p1.dy - p1.dx * p0.dy;
      signedArea += a;
      cx += (p0.dx + p1.dx) * a;
      cy += (p0.dy + p1.dy) * a;
    }

    signedArea *= 0.5;

    // Falls alle Punkte auf einer Linie liegen (Fläche = 0)
    if (signedArea == 0) {
      double minX = points.first.dx, maxX = points.first.dx;
      double minY = points.first.dy, maxY = points.first.dy;
      for (final p in points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      return Offset((minX + maxX) / 2, (minY + maxY) / 2);
    }

    cx /= (6.0 * signedArea);
    cy /= (6.0 * signedArea);

    return Offset(cx, cy);
  }

  /// Berechnet die Fläche eines Polygons in Pixel^2
  static double calculatePolygonAreaPixel(List<Offset> points, Size imageSize) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area +=
          (points[i].dx * imageSize.width) * (points[j].dy * imageSize.height);
      area -=
          (points[j].dx * imageSize.width) * (points[i].dy * imageSize.height);
    }
    return (area / 2.0).abs();
  }

  /// Berechnet den Winkel einer Linie zur Horizontalen (in Grad)
  static double calculateAngleToHorizontal(Offset p1, Offset p2) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy; // Bildschirmkoordinaten (y nach unten)

    // atan2(dy, dx) gibt Winkel im Bogenmaß.
    // Wir ignorieren die Richtung (Linie p1->p2 oder p2->p1) für die Neigung.
    double angleRad = atan2(dy, dx);
    double angleDeg = angleRad * 180 / pi;

    // Wir wollen den spitzen Winkel zur Bildhorizontalen
    if (angleDeg < 0) angleDeg += 180;
    if (angleDeg > 90) angleDeg = 180 - angleDeg;

    return angleDeg;
  }

  static double? getPixelsPerMeter(
    Size imageSize, {
    Offset? calibP1,
    Offset? calibP2,
    double? calibDistance,
    String unit = 'm',
  }) {
    if (calibP1 == null ||
        calibP2 == null ||
        calibDistance == null ||
        calibDistance <= 0) {
      return null;
    }

    final p1Pix = GeometryUtils.toPixel(calibP1, imageSize);
    final p2Pix = GeometryUtils.toPixel(calibP2, imageSize);

    final pixelDistance = (p2Pix - p1Pix).distance;
    if (pixelDistance == 0) return null;

    final distanceInMeters = CalibrationInputUtils.convertToMeters(
      calibDistance,
      unit,
    );
    if (distanceInMeters == null || distanceInMeters <= 0) return null;

    return pixelDistance / distanceInMeters;
  }

  static bool isPointNearLine(
    Offset p,
    Offset l1,
    Offset l2,
    double threshold,
  ) {
    final lineMag = (l2 - l1).distance;
    if (lineMag == 0) return (p - l1).distance <= threshold;

    final u =
        (((p.dx - l1.dx) * (l2.dx - l1.dx)) +
            ((p.dy - l1.dy) * (l2.dy - l1.dy))) /
        (lineMag * lineMag);

    if (u < 0.0 || u > 1.0) return false;

    final intersection = Offset(
      l1.dx + u * (l2.dx - l1.dx),
      l1.dy + u * (l2.dy - l1.dy),
    );
    final distance = (p - intersection).distance;

    return distance <= threshold;
  }

  static bool isPointInPolygon(Offset p, List<Offset> poly) {
    bool c = false;
    int j = poly.length - 1;
    for (int i = 0; i < poly.length; i++) {
      if (((poly[i].dy > p.dy) != (poly[j].dy > p.dy)) &&
          (p.dx <
              (poly[j].dx - poly[i].dx) *
                      (p.dy - poly[i].dy) /
                      (poly[j].dy - poly[i].dy) +
                  poly[i].dx)) {
        c = !c;
      }
      j = i;
    }
    return c;
  }

  static bool isPointInRect(Offset p, Offset r1, Offset r2) {
    final minX = min(r1.dx, r2.dx);
    final maxX = max(r1.dx, r2.dx);
    final minY = min(r1.dy, r2.dy);
    final maxY = max(r1.dy, r2.dy);
    return p.dx >= minX && p.dx <= maxX && p.dy >= minY && p.dy <= maxY;
  }
}

extension NormalizedOffsetExtension on Offset {
  Offset toPixel(Size size) => GeometryUtils.toPixel(this, size);
}

extension NullableNormalizedOffsetExtension on Offset? {
  Offset? toPixel(Size size) => GeometryUtils.toPixelOrNull(this, size);
}

extension NormalizedOffsetListExtension on List<Offset> {
  List<Offset> toPixels(Size size) => GeometryUtils.toPixels(this, size);
}
