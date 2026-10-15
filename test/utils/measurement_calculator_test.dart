import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/utils/measurement_calculator.dart';

void main() {
  const size = Size(1000, 1000);
  const pixelsPerMeter = 100.0; // 100 px = 1 m

  group('MeasurementCalculator Line Tests', () {
    const line = LineEntity(
      id: 'L1',
      p1: Offset(0.1, 0.2), // (100, 200) px
      p2: Offset(
        0.4,
        0.6,
      ), // (400, 600) px -> dx=300, dy=400 -> dist=500 px = 5.00 m
      color: Colors.blue,
    );

    test('calculateDistance and formatDistance', () {
      final dist = MeasurementCalculator.calculateDistance(
        line.p1!,
        line.p2!,
        size,
        pixelsPerMeter,
      );
      expect(dist, closeTo(5.0, 0.001));
      expect(MeasurementCalculator.formatDistance(dist!), '5.00 m');
    });

    test('getMeasurementText for LineEntity', () {
      final text = MeasurementCalculator.getMeasurementText(
        line,
        size,
        pixelsPerMeter,
      );
      expect(text, '5.00 m');
    });

    test('getMeasurementLabelPosition for LineEntity', () {
      final pos = MeasurementCalculator.getMeasurementLabelPosition(line, size);
      expect(pos, const Offset(250.0, 400.0));
    });

    test('returns null when pixelsPerMeter is null', () {
      final text = MeasurementCalculator.getMeasurementText(line, size, null);
      expect(text, isNull);
    });
  });

  group('MeasurementCalculator Rectangle Tests', () {
    const rect = RectangleEntity(
      id: 'R1',
      p1: Offset(0.2, 0.3), // (200, 300) px
      p2: Offset(
        0.5,
        0.7,
      ), // (500, 700) px -> width=300 px (3m), height=400 px (4m), area=12 m²
      color: Colors.red,
    );

    test('calculateRectangleArea and formatArea', () {
      final area = MeasurementCalculator.calculateRectangleArea(
        rect.p1!,
        rect.p2!,
        size,
        pixelsPerMeter,
      );
      expect(area, closeTo(12.0, 0.001));
      expect(MeasurementCalculator.formatArea(area!), '12.00 m²');
    });

    test('getMeasurementText for RectangleEntity', () {
      final text = MeasurementCalculator.getMeasurementText(
        rect,
        size,
        pixelsPerMeter,
      );
      expect(text, '12.00 m²');
    });

    test('getMeasurementLabelPosition for RectangleEntity', () {
      final pos = MeasurementCalculator.getMeasurementLabelPosition(rect, size);
      expect(pos, const Offset(350.0, 500.0));
    });

    test('rectangle side lengths and label positions', () {
      final widthText = MeasurementCalculator.getRectangleWidthText(
        rect,
        size,
        pixelsPerMeter,
      );
      expect(widthText, '3.00 m');

      final heightText = MeasurementCalculator.getRectangleHeightText(
        rect,
        size,
        pixelsPerMeter,
      );
      expect(heightText, '4.00 m');

      final widthPos = MeasurementCalculator.getRectangleWidthLabelPosition(
        rect,
        size,
      );
      expect(widthPos, const Offset(350.0, 300.0));

      final heightPos = MeasurementCalculator.getRectangleHeightLabelPosition(
        rect,
        size,
      );
      expect(heightPos, const Offset(200.0, 500.0));
    });
  });

  group('MeasurementCalculator Polygon Tests', () {
    // Triangle: (0,0), (300, 0), (0, 400) -> area = 1/2 * 3 * 4 = 6 m²
    const poly = PolygonEntity(
      id: 'P1',
      points: [Offset(0.0, 0.0), Offset(0.3, 0.0), Offset(0.0, 0.4)],
      color: Colors.green,
      isClosed: true,
    );

    test('calculatePolygonArea and getMeasurementText', () {
      final area = MeasurementCalculator.calculatePolygonArea(
        poly.points,
        size,
        pixelsPerMeter,
      );
      expect(area, closeTo(6.0, 0.001));

      final text = MeasurementCalculator.getMeasurementText(
        poly,
        size,
        pixelsPerMeter,
      );
      expect(text, '6.00 m²');
    });

    test('getMeasurementLabelPosition for PolygonEntity', () {
      final pos = MeasurementCalculator.getMeasurementLabelPosition(poly, size);
      expect(pos, isNotNull);
      // Centroid of (0,0), (300, 0), (0, 400) is (100, 133.33)
      expect(pos!.dx, closeTo(100.0, 0.1));
      expect(pos.dy, closeTo(133.33, 0.1));
    });

    test('unclosed polygon returns null', () {
      const openPoly = PolygonEntity(
        id: 'P2',
        points: [Offset(0.0, 0.0), Offset(0.3, 0.0), Offset(0.0, 0.4)],
        color: Colors.green,
        isClosed: false,
      );
      expect(
        MeasurementCalculator.getMeasurementText(
          openPoly,
          size,
          pixelsPerMeter,
        ),
        isNull,
      );
    });
  });

  group('MeasurementCalculator Angle Tests', () {
    const angle45 = AngleEntity(
      id: 'A1',
      p1: Offset(0.1, 0.1),
      p2: Offset(0.2, 0.2), // dy = dx -> 45 degrees
      color: Colors.orange,
    );

    test('calculateAngle and formatAngle', () {
      final deg = MeasurementCalculator.calculateAngle(
        angle45.p1!,
        angle45.p2!,
        size,
      );
      expect(deg, closeTo(45.0, 0.001));
      expect(MeasurementCalculator.formatAngle(deg), '45.0°');
    });

    test(
      'getMeasurementText for AngleEntity does not require pixelsPerMeter',
      () {
        final textWithCalib = MeasurementCalculator.getMeasurementText(
          angle45,
          size,
          pixelsPerMeter,
        );
        expect(textWithCalib, '45.0°');

        final textWithoutCalib = MeasurementCalculator.getMeasurementText(
          angle45,
          size,
          null,
        );
        expect(textWithoutCalib, '45.0°');
      },
    );

    test('getMeasurementLabelPosition for AngleEntity', () {
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        angle45,
        size,
      );
      expect(pos, isNotNull);
    });
  });

  group('MeasurementCalculator Type Labels', () {
    test('returns correct type labels', () {
      expect(
        MeasurementCalculator.getMeasurementTypeLabel(
          const LineEntity(id: '1', color: Colors.blue),
        ),
        'Linie (Länge)',
      );
      expect(
        MeasurementCalculator.getMeasurementTypeLabel(
          const RectangleEntity(id: '2', color: Colors.red),
        ),
        'Rechteck (Fläche)',
      );
      expect(
        MeasurementCalculator.getMeasurementTypeLabel(
          const PolygonEntity(id: '3', points: [], color: Colors.green),
        ),
        'Polygon (Fläche)',
      );
      expect(
        MeasurementCalculator.getMeasurementTypeLabel(
          const AngleEntity(id: '4', color: Colors.orange),
        ),
        'Winkel',
      );
      expect(
        MeasurementCalculator.getMeasurementTypeLabel(
          const CalibrationEntity(id: '5'),
        ),
        isNull,
      );
      expect(
        MeasurementCalculator.getMeasurementTypeLabel(
          const PerspectiveEntity(id: '6', points: [], color: Colors.blue),
        ),
        isNull,
      );
    });
  });
}
