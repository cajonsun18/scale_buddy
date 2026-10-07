import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/utils/geometry_utils.dart';

void main() {
  group('GeometryUtils', () {
    test('calculatePolygonCentroid calculates correct centroid', () {
      final points = [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(10, 10),
        const Offset(0, 10),
      ];
      final centroid = GeometryUtils.calculatePolygonCentroid(points);
      expect(centroid.dx, closeTo(5.0, 0.001));
      expect(centroid.dy, closeTo(5.0, 0.001));
    });

    test('calculatePolygonAreaPixel calculates correct area', () {
      final points = [
        const Offset(0, 0),
        const Offset(1, 0),
        const Offset(1, 1),
        const Offset(0, 1),
      ];
      // Size: 100x100
      final area = GeometryUtils.calculatePolygonAreaPixel(
        points,
        const Size(100, 100),
      );
      // Each side is 1*100 = 100 pixels. Area = 100 * 100 = 10000
      expect(area, closeTo(10000.0, 0.001));
    });

    test('calculateAngleToHorizontal calculates correct angle', () {
      // Horizontal
      expect(
        GeometryUtils.calculateAngleToHorizontal(
          const Offset(0, 0),
          const Offset(10, 0),
        ),
        closeTo(0.0, 0.001),
      );
      // Vertical (90 deg)
      expect(
        GeometryUtils.calculateAngleToHorizontal(
          const Offset(0, 0),
          const Offset(0, 10),
        ),
        closeTo(90.0, 0.001),
      );
      // 45 deg
      expect(
        GeometryUtils.calculateAngleToHorizontal(
          const Offset(0, 0),
          const Offset(10, 10),
        ),
        closeTo(45.0, 0.001),
      );
    });

    test('getPixelsPerMeter handles different units', () {
      // 100px width, 100px height
      // Calib from (0,0) to (1,0) = 100px
      // Distance 1 m -> 100 px/m
      final pxPerM = GeometryUtils.getPixelsPerMeter(
        const Size(100, 100),
        calibP1: const Offset(0, 0),
        calibP2: const Offset(1, 0),
        calibDistance: 1,
        unit: 'm',
      );
      expect(pxPerM, 100.0);

      // Distance 100 cm = 1m -> 100 px/m
      final pxPerMCm = GeometryUtils.getPixelsPerMeter(
        const Size(100, 100),
        calibP1: const Offset(0, 0),
        calibP2: const Offset(1, 0),
        calibDistance: 100,
        unit: 'cm',
      );
      expect(pxPerMCm, 100.0);
    });

    test('isPointNearLine works correctly', () {
      final p1 = const Offset(0, 0);
      final p2 = const Offset(10, 0);
      expect(
        GeometryUtils.isPointNearLine(const Offset(5, 0.5), p1, p2, 1.0),
        isTrue,
      );
      expect(
        GeometryUtils.isPointNearLine(const Offset(5, 2.0), p1, p2, 1.0),
        isFalse,
      );
    });

    test('isPointInPolygon works correctly', () {
      final poly = [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(10, 10),
        const Offset(0, 10),
      ];
      expect(GeometryUtils.isPointInPolygon(const Offset(5, 5), poly), isTrue);
      expect(
        GeometryUtils.isPointInPolygon(const Offset(15, 5), poly),
        isFalse,
      );
    });

    test('isPointInRect works correctly', () {
      expect(
        GeometryUtils.isPointInRect(
          const Offset(5, 5),
          const Offset(0, 0),
          const Offset(10, 10),
        ),
        isTrue,
      );
      expect(
        GeometryUtils.isPointInRect(
          const Offset(15, 5),
          const Offset(0, 0),
          const Offset(10, 10),
        ),
        isFalse,
      );
    });
  });
}
