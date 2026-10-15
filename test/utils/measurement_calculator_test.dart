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

  group('MeasurementCalculator Mobile Formatting Tests', () {
    test('formatDistance, formatArea and formatAngle with comma', () {
      expect(
        MeasurementCalculator.formatDistance(1.04, useComma: true),
        '1,04 m',
      );
      expect(MeasurementCalculator.formatArea(4.00, useComma: true), '4,00 m²');
      expect(MeasurementCalculator.formatAngle(4.2, useComma: true), '4,2°');
    });

    test('getMobileMeasurementBadgeText for LineEntity', () {
      const line = LineEntity(
        id: 'L1',
        p1: Offset(0.1, 0.2),
        p2: Offset(0.4, 0.6), // 5.00 m
        color: Colors.blue,
      );
      final badge = MeasurementCalculator.getMobileMeasurementBadgeText(
        line,
        size,
        pixelsPerMeter,
        index: 1,
        useComma: true,
      );
      expect(badge, 'S1: 5,00 m');

      final badge2 = MeasurementCalculator.getMobileMeasurementBadgeText(
        line,
        size,
        pixelsPerMeter,
        index: 2,
        useComma: true,
      );
      expect(badge2, 'S2: 5,00 m');
    });

    test('getMobileMeasurementBadgeText and getMobileRectangleWidthBadgeText for RectangleEntity', () {
      const rect = RectangleEntity(
        id: 'R1',
        p1: Offset(0.2, 0.3),
        p2: Offset(0.5, 0.7), // width=3m, height=4m, area=12m²
        color: Colors.red,
      );
      final centerBadge = MeasurementCalculator.getMobileMeasurementBadgeText(
        rect,
        size,
        pixelsPerMeter,
        index: 1,
        useComma: true,
      );
      expect(centerBadge, 'F1: 12,00 m²');

      final widthBadge = MeasurementCalculator.getMobileRectangleWidthBadgeText(
        rect,
        size,
        pixelsPerMeter,
        useComma: true,
      );
      expect(widthBadge, '3,00 m');
    });

    test('getMobileMeasurementBadgeText for PolygonEntity uses P prefix', () {
      const poly = PolygonEntity(
        id: 'P1',
        points: [
          Offset(0.0, 0.0),
          Offset(0.3, 0.0),
          Offset(0.0, 0.4),
        ], // 6.00 m²
        color: Colors.purple,
        isClosed: true,
      );
      final badge = MeasurementCalculator.getMobileMeasurementBadgeText(
        poly,
        size,
        pixelsPerMeter,
        index: 1,
        useComma: true,
      );
      expect(badge, 'P1: 6,00 m²');
    });

    test('getMobileMeasurementBadgeText for AngleEntity uses W prefix', () {
      const angle = AngleEntity(
        id: 'A1',
        p1: Offset(0.1, 0.1),
        p2: Offset(0.2, 0.2), // 45.0°
        color: Colors.amber,
      );
      final badge = MeasurementCalculator.getMobileMeasurementBadgeText(
        angle,
        size,
        pixelsPerMeter,
        index: 1,
        useComma: true,
      );
      expect(badge, 'W1: 45,0°');
    });

    test(
      'Mobile Inspector formatting and calculations for RectangleEntity',
      () {
        // 1000x1000 canvas, 100 px = 1 m
        // 1.74 m width = 174 px = 0.174
        // 2.30 m height = 230 px = 0.230
        const rect = RectangleEntity(
          id: 'R1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.274, 0.33),
          color: Colors.green,
        );

        final allEntities = [rect];
        expect(
          MeasurementCalculator.getMobileEntityIdentifier(rect, allEntities),
          'F1',
        );
        expect(MeasurementCalculator.getMobileEntityTypeName(rect), 'Rechteck');
        expect(
          MeasurementCalculator.getMobileEntityTitle(rect, allEntities),
          'F1 · Rechteckfläche',
        );

        final details = MeasurementCalculator.getMobileEntityDetails(
          rect,
          size,
          pixelsPerMeter,
          useComma: true,
        );
        // Area = 1.74 * 2.30 = 4.002 m² -> 4,00 m²
        // Perimeter = 2 * (1.74 + 2.30) = 8.08 m -> 8,08 m
        // 1,74 × 2,30 m
        expect(details, 'Fläche: 4,00 m² · Umfang: 8,08 m · 1,74 × 2,30 m');
      },
    );

    test(
      'Mobile Inspector formatting and calculations for Line, Polygon, Angle',
      () {
        const line = LineEntity(
          id: 'L1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.1, 0.204), // 104 px = 1.04 m
          color: Colors.blue,
        );
        const poly = PolygonEntity(
          id: 'P1',
          points: [
            Offset(0.0, 0.0),
            Offset(0.3, 0.0),
            Offset(0.3, 0.4),
            Offset(0.0, 0.4),
          ], // 3m x 4m = 12m², perimeter = 2*(3+4)=14m
          color: Colors.purple,
          isClosed: true,
        );
        const angle = AngleEntity(
          id: 'A1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.2, 0.1), // 0°
          color: Colors.amber,
        );

        final entities = [line, poly, angle];
        expect(
          MeasurementCalculator.getMobileEntityIdentifier(line, entities),
          'S1',
        );
        expect(
          MeasurementCalculator.getMobileEntityTitle(line, entities),
          'S1 · Streckenlänge',
        );
        expect(
          MeasurementCalculator.getMobileEntityDetails(
            line,
            size,
            pixelsPerMeter,
            useComma: true,
          ),
          'Länge: 1,04 m',
        );

        expect(
          MeasurementCalculator.getMobileEntityIdentifier(poly, entities),
          'P1',
        );
        expect(
          MeasurementCalculator.getMobileEntityTitle(poly, entities),
          'P1 · Polygonfläche',
        );
        expect(
          MeasurementCalculator.getMobileEntityDetails(
            poly,
            size,
            pixelsPerMeter,
            useComma: true,
          ),
          'Fläche: 12,00 m² · Umfang: 14,00 m',
        );

        expect(
          MeasurementCalculator.getMobileEntityIdentifier(angle, entities),
          'W1',
        );
        expect(
          MeasurementCalculator.getMobileEntityTitle(angle, entities),
          'W1 · Dachwinkel',
        );
        expect(
          MeasurementCalculator.getMobileEntityDetails(
            angle,
            size,
            pixelsPerMeter,
            useComma: true,
          ),
          'Winkel: 0,0°',
        );
      },
    );
  });
}
