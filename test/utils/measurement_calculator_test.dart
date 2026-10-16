import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/utils/geometry_utils.dart';
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

    test(
      'getMeasurementLabelPosition for LineEntity has 32px orthogonal offset',
      () {
        final pos = MeasurementCalculator.getMeasurementLabelPosition(
          line,
          size,
        );
        expect(pos, const Offset(275.6, 380.8));
        final midpoint = const Offset(250.0, 400.0);
        final dist = (pos! - midpoint).distance;
        expect(dist, closeTo(32.0, 0.001));
      },
    );

    test('getMeasurementLabelPosition with customLabelOffset adds relative offset to base position', () {
      final displacedLine = line.copyWith(
        customLabelOffset: const Offset(0.05, 0.1),
      );
      final basePos = MeasurementCalculator.getMeasurementLabelPosition(
        line,
        size,
      )!;
      final displacedPos = MeasurementCalculator.getMeasurementLabelPosition(
        displacedLine,
        size,
      )!;
      expect(displacedPos.dx, closeTo(basePos.dx + 50.0, 0.001));
      expect(displacedPos.dy, closeTo(basePos.dy + 100.0, 0.001));
    });

    test(
      'calculateLineLabelPosition for horizontal line places pill 32px upwards',
      () {
        const p1 = Offset(100, 200);
        const p2 = Offset(300, 200);
        final pos = MeasurementCalculator.calculateLineLabelPosition(
          p1,
          p2,
          size,
        );
        // Midpoint: (200, 200), upward offset of 32px -> (200, 168)
        expect(pos, const Offset(200.0, 168.0));
        expect((pos - const Offset(200, 200)).distance, 32.0);

        // Inverted direction (right-to-left) should still point upward
        final posInverted = MeasurementCalculator.calculateLineLabelPosition(
          p2,
          p1,
          size,
        );
        expect(posInverted, const Offset(200.0, 168.0));
      },
    );

    test('calculateLineLabelPosition for vertical line places pill 32px to the right', () {
      const p1 = Offset(200, 100);
      const p2 = Offset(200, 300);
      final pos = MeasurementCalculator.calculateLineLabelPosition(
        p1,
        p2,
        size,
      );
      // Midpoint: (200, 200), rightward offset of 32px -> (232, 200)
      expect(pos, const Offset(232.0, 200.0));
      expect((pos - const Offset(200, 200)).distance, 32.0);

      // Bottom-to-top should still produce identical position
      final posInverted = MeasurementCalculator.calculateLineLabelPosition(
        p2,
        p1,
        size,
      );
      expect(posInverted, const Offset(232.0, 200.0));
    });

    test(
      'calculateLineLabelPosition auto-flips downward at top canvas edge',
      () {
        const p1 = Offset(100, 20);
        const p2 = Offset(300, 20);
        // Midpoint: (200, 20). Upward candidate: (200, 20 - 32) = (200, -12).
        // Since candidate.dy - 16 < 0, it flips downward: (200, 20 + 32) = (200, 52).
        final pos = MeasurementCalculator.calculateLineLabelPosition(
          p1,
          p2,
          size,
        );
        expect(pos, const Offset(200.0, 52.0));
        expect(pos.dy, greaterThan(20.0));
        expect(
          pos.dy - MeasurementCalculator.defaultPillHalfHeight,
          greaterThanOrEqualTo(0.0),
        );
      },
    );

    test(
      'Short lines (< 100px) do not overlap P1 or P2 with badge bounding box',
      () {
        // Horizontal short line: 60px
        const p1H = Offset(200, 200);
        const p2H = Offset(260, 200);
        final posH = MeasurementCalculator.calculateLineLabelPosition(
          p1H,
          p2H,
          size,
        );
        // Typical badge size: ~80px wide, ~26px high
        final badgeRectH = Rect.fromCenter(center: posH, width: 80, height: 26);
        expect(badgeRectH.contains(p1H), isFalse);
        expect(badgeRectH.contains(p2H), isFalse);
        expect(
          badgeRectH.overlaps(Rect.fromCircle(center: p1H, radius: 10)),
          isFalse,
        );
        expect(
          badgeRectH.overlaps(Rect.fromCircle(center: p2H, radius: 10)),
          isFalse,
        );

        // Vertical short line: 60px
        const p1V = Offset(300, 200);
        const p2V = Offset(300, 260);
        final posV = MeasurementCalculator.calculateLineLabelPosition(
          p1V,
          p2V,
          size,
        );
        final badgeRectV = Rect.fromCenter(center: posV, width: 80, height: 26);
        expect(badgeRectV.contains(p1V), isFalse);
        expect(badgeRectV.contains(p2V), isFalse);
        expect(
          badgeRectV.overlaps(Rect.fromCircle(center: p1V, radius: 10)),
          isFalse,
        );
        expect(
          badgeRectV.overlaps(Rect.fromCircle(center: p2V, radius: 10)),
          isFalse,
        );
      },
    );

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

    test('getRectangleWidthLabelPosition and getRectangleHeightLabelPosition handle inverted points', () {
      const invertedRect = RectangleEntity(
        id: 'R_inv',
        p1: Offset(0.5, 0.7), // Bottom-right: (500, 700) px
        p2: Offset(0.2, 0.3), // Top-left: (200, 300) px
        color: Colors.red,
      );
      final widthPos = MeasurementCalculator.getRectangleWidthLabelPosition(
        invertedRect,
        size,
      );
      expect(widthPos, const Offset(350.0, 300.0)); // Always top edge

      final heightPos = MeasurementCalculator.getRectangleHeightLabelPosition(
        invertedRect,
        size,
      );
      expect(heightPos, const Offset(200.0, 500.0)); // Always left edge
    });

    test('getRectangleWidthBadgePlacement and getRectangleHeightBadgePlacement calculate positions and flips correctly', () {
      // Normal rectangle away from image borders
      const normalRect = RectangleEntity(
        id: 'R_normal',
        p1: Offset(0.2, 0.2), // (200, 200) px
        p2: Offset(0.5, 0.6), // (500, 600) px
        color: Colors.green,
      );
      final normalWidth = MeasurementCalculator.getRectangleWidthBadgePlacement(
        normalRect,
        size,
      );
      expect(normalWidth, isNotNull);
      expect(normalWidth!.isFlipped, isFalse);
      expect(normalWidth.position, const Offset(350.0, 200.0));
      expect(normalWidth.widgetTranslation, const Offset(-0.5, -1.6));

      final normalHeight =
          MeasurementCalculator.getRectangleHeightBadgePlacement(
            normalRect,
            size,
          );
      expect(normalHeight, isNotNull);
      expect(normalHeight!.isFlipped, isFalse);
      expect(normalHeight.position, const Offset(200.0, 400.0));
      expect(normalHeight.widgetTranslation, const Offset(-1.4, -0.5));

      // Rectangle near top and left borders to trigger flipping
      const borderRect = RectangleEntity(
        id: 'R_border',
        p1: Offset(0.02, 0.02), // (20, 20) px: minY = 20 < 35, minX = 20 < 60
        p2: Offset(0.3, 0.4), // (300, 400) px: maxY = 400, maxX = 300
        color: Colors.green,
      );
      final borderWidth = MeasurementCalculator.getRectangleWidthBadgePlacement(
        borderRect,
        size,
      );
      expect(borderWidth, isNotNull);
      expect(borderWidth!.isFlipped, isTrue);
      expect(borderWidth.position, const Offset(160.0, 400.0));
      expect(borderWidth.widgetTranslation, const Offset(-0.5, 0.6));

      final borderHeight =
          MeasurementCalculator.getRectangleHeightBadgePlacement(
            borderRect,
            size,
          );
      expect(borderHeight, isNotNull);
      expect(borderHeight!.isFlipped, isTrue);
      expect(borderHeight.position, const Offset(300.0, 210.0));
      expect(borderHeight.widgetTranslation, const Offset(0.4, -0.5));
    });

    test('Compact rectangle area label shifts outside to avoid overlapping corner handles', () {
      const compactRect = RectangleEntity(
        id: 'R_compact',
        p1: Offset(0.2, 0.2), // (200, 200) px
        p2: Offset(0.24, 0.24), // (240, 240) px -> 40x40 px rectangle
        color: Colors.red,
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        compactRect,
        size,
      );
      expect(pos, isNotNull);

      // Centroid would be (220, 220), which would collide with all 4 corners
      expect(pos, isNot(const Offset(220.0, 220.0)));

      // Verify label bounding box does not overlap any of the 4 corners
      final corners = [
        const Offset(200, 200),
        const Offset(240, 200),
        const Offset(200, 240),
        const Offset(240, 240),
      ];
      final badgeRect = Rect.fromCenter(center: pos!, width: 84, height: 28);
      for (final corner in corners) {
        expect(badgeRect.contains(corner), isFalse);
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: corner, radius: 10)),
          isFalse,
        );
      }
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

    test('Compact polygon shifts label position away from vertices', () {
      // Small triangle: (200, 200), (260, 200), (230, 225) px
      const compactPoly = PolygonEntity(
        id: 'P_compact',
        points: [Offset(0.2, 0.2), Offset(0.26, 0.2), Offset(0.23, 0.225)],
        color: Colors.green,
        isClosed: true,
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        compactPoly,
        size,
      );
      expect(pos, isNotNull);

      final centroid = GeometryUtils.calculatePolygonCentroid(
        compactPoly.points,
      ).toPixel(size);
      expect((pos! - centroid).distance, greaterThan(1.0));

      final vertices = [
        const Offset(200, 200),
        const Offset(260, 200),
        const Offset(230, 225),
      ];
      final badgeRect = Rect.fromCenter(center: pos, width: 84, height: 28);
      for (final v in vertices) {
        expect(badgeRect.contains(v), isFalse);
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: v, radius: 10)),
          isFalse,
        );
      }
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

    test(
      'getMeasurementLabelPosition for AngleEntity does not overlap p1 or p2',
      () {
        final pos = MeasurementCalculator.getMeasurementLabelPosition(
          angle45,
          size,
        );
        expect(pos, isNotNull);

        final p1 = const Offset(100, 100);
        final p2 = const Offset(200, 200);
        final badgeRect = Rect.fromCenter(center: pos!, width: 84, height: 28);
        expect(badgeRect.contains(p1), isFalse);
        expect(badgeRect.contains(p2), isFalse);
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: p1, radius: 10)),
          isFalse,
        );
        expect(
          badgeRect.overlaps(Rect.fromCircle(center: p2, radius: 10)),
          isFalse,
        );
      },
    );

    test('Short angle (40px arm) positions badge with sufficient radius away from apex and arm end', () {
      const shortAngle = AngleEntity(
        id: 'A_short',
        p1: Offset(0.2, 0.2), // (200, 200) px
        p2: Offset(0.24, 0.2), // (240, 200) px -> 40px horizontal arm
        color: Colors.orange,
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        shortAngle,
        size,
      );
      expect(pos, isNotNull);

      const p1 = Offset(200, 200);
      const p2 = Offset(240, 200);
      final badgeRect = Rect.fromCenter(center: pos!, width: 84, height: 28);
      expect(badgeRect.contains(p1), isFalse);
      expect(badgeRect.contains(p2), isFalse);
      expect(
        badgeRect.overlaps(Rect.fromCircle(center: p1, radius: 10)),
        isFalse,
      );
      expect(
        badgeRect.overlaps(Rect.fromCircle(center: p2, radius: 10)),
        isFalse,
      );
    });

    test('Acute angle (small sweep) positions badge without colliding with handles', () {
      const acuteAngle = AngleEntity(
        id: 'A_acute',
        p1: Offset(0.3, 0.3), // (300, 300) px
        p2: Offset(0.38, 0.32), // (380, 320) px -> ~14°
        color: Colors.orange,
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        acuteAngle,
        size,
      );
      expect(pos, isNotNull);

      const p1 = Offset(300, 300);
      const p2 = Offset(380, 320);
      final badgeRect = Rect.fromCenter(center: pos!, width: 84, height: 28);
      expect(badgeRect.contains(p1), isFalse);
      expect(badgeRect.contains(p2), isFalse);
      expect(
        badgeRect.overlaps(Rect.fromCircle(center: p1, radius: 10)),
        isFalse,
      );
      expect(
        badgeRect.overlaps(Rect.fromCircle(center: p2, radius: 10)),
        isFalse,
      );
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

  group('Selective Ghosting and Protection Zone Tests', () {
    test(
      'estimatePillSize calculates reasonable dimensions for badge text',
      () {
        final unselectedSize = MeasurementCalculator.estimatePillSize(
          'S1: 5.00 m',
        );
        expect(unselectedSize.width, greaterThan(40.0));
        expect(unselectedSize.height, greaterThanOrEqualTo(24.0));

        final selectedSize = MeasurementCalculator.estimatePillSize(
          'S1: 5.00 m',
          isSelected: true,
          hasDelete: true,
        );
        expect(selectedSize.width, greaterThan(unselectedSize.width));
      },
    );

    test('getEntityHandlePoints extracts correct handle points for all entity types', () {
      const line = LineEntity(
        id: 'L1',
        p1: Offset(0.2, 0.4),
        p2: Offset(0.6, 0.4),
        color: Colors.blue,
      );
      final lineHandles = MeasurementCalculator.getEntityHandlePoints(
        line,
        size,
      );
      expect(lineHandles.length, 2);
      expect(lineHandles[0], const Offset(200, 400));
      expect(lineHandles[1], const Offset(600, 400));

      const rect = RectangleEntity(
        id: 'R1',
        p1: Offset(0.1, 0.1),
        p2: Offset(0.3, 0.4),
        color: Colors.green,
      );
      final rectHandles = MeasurementCalculator.getEntityHandlePoints(
        rect,
        size,
      );
      expect(rectHandles.length, 4);
      expect(rectHandles, contains(const Offset(100, 100)));
      expect(rectHandles, contains(const Offset(300, 100)));
      expect(rectHandles, contains(const Offset(300, 400)));
      expect(rectHandles, contains(const Offset(100, 400)));

      const poly = PolygonEntity(
        id: 'P1',
        points: [Offset(0.1, 0.1), Offset(0.2, 0.1), Offset(0.15, 0.2)],
        color: Colors.purple,
      );
      final polyHandles = MeasurementCalculator.getEntityHandlePoints(
        poly,
        size,
      );
      expect(polyHandles.length, 3);

      const angle = AngleEntity(
        id: 'A1',
        p1: Offset(0.5, 0.5),
        p2: Offset(0.6, 0.5),
        color: Colors.amber,
      );
      final angleHandles = MeasurementCalculator.getEntityHandlePoints(
        angle,
        size,
      );
      expect(angleHandles.length, 2);
    });

    test('checkPillCollision detects collision with handle circle or selected pill', () {
      final selectedHandles = [const Offset(200, 400), const Offset(600, 400)];
      final selectedPillRects = [
        Rect.fromCenter(center: const Offset(400, 368), width: 80, height: 28),
      ];

      // Pill directly covering handle P1 at (200, 400)
      final collidingHandlePill = Rect.fromCenter(
        center: const Offset(200, 400),
        width: 70,
        height: 26,
      );
      expect(
        MeasurementCalculator.checkPillCollision(
          foreignPillRect: collidingHandlePill,
          selectedHandles: selectedHandles,
          selectedPillRects: selectedPillRects,
          handleRadius: 18.0,
        ),
        isTrue,
      );

      // Pill overlapping selected pill at (400, 368)
      final collidingPillRect = Rect.fromCenter(
        center: const Offset(420, 370),
        width: 70,
        height: 26,
      );
      expect(
        MeasurementCalculator.checkPillCollision(
          foreignPillRect: collidingPillRect,
          selectedHandles: selectedHandles,
          selectedPillRects: selectedPillRects,
          handleRadius: 18.0,
        ),
        isTrue,
      );

      // Distant pill far away at (800, 800)
      final distantPill = Rect.fromCenter(
        center: const Offset(800, 800),
        width: 70,
        height: 26,
      );
      expect(
        MeasurementCalculator.checkPillCollision(
          foreignPillRect: distantPill,
          selectedHandles: selectedHandles,
          selectedPillRects: selectedPillRects,
          handleRadius: 18.0,
        ),
        isFalse,
      );

      // Handle at (100, 100), radius = 10.0.
      // Bounding box of the handle circle is [90, 90] to [110, 110].
      // A pill at [108, 108, 120, 120] overlaps the handle bounding box,
      // but distance from center (100, 100) to closest point (108, 108) is sqrt(64+64) ~ 11.31 > 10.0.
      // Strict circle collision must NOT report collision!
      final cornerBoundingBoxPill = const Rect.fromLTRB(108, 108, 120, 120);
      expect(
        MeasurementCalculator.checkPillCollision(
          foreignPillRect: cornerBoundingBoxPill,
          selectedHandles: [const Offset(100, 100)],
          selectedPillRects: [],
          handleRadius: 10.0,
        ),
        isFalse,
      );
    });
  });

  group('MeasurementCalculator Calibration Tests', () {
    test('getMeasurementText for CalibrationEntity', () {
      const calibUnconfirmed = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.1, 0.2),
        p2: Offset(0.4, 0.6),
        enteredDistance: 2.50,
        selectedUnit: 'm',
        isConfirmed: false,
      );
      expect(
        MeasurementCalculator.getMeasurementText(
          calibUnconfirmed,
          size,
          pixelsPerMeter,
        ),
        '2.50 m',
      );
      expect(
        MeasurementCalculator.getMeasurementText(
          calibUnconfirmed,
          size,
          pixelsPerMeter,
          useComma: true,
        ),
        '2,50 m',
      );

      final calibConfirmed = calibUnconfirmed.copyWith(isConfirmed: true);
      expect(
        MeasurementCalculator.getMeasurementText(
          calibConfirmed,
          size,
          pixelsPerMeter,
        ),
        '✓ 2.50 m',
      );

      const calibNoDistance = CalibrationEntity(
        id: 'C2',
        p1: Offset(0.1, 0.2),
        p2: Offset(0.4, 0.6),
        selectedUnit: 'cm',
        isConfirmed: false,
      );
      expect(
        MeasurementCalculator.getMeasurementText(
          calibNoDistance,
          size,
          pixelsPerMeter,
        ),
        '-- cm',
      );
    });

    test('getMeasurementLabelPosition for CalibrationEntity has 32px orthogonal offset', () {
      const calib = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.1, 0.2), // (100, 200) px
        p2: Offset(0.4, 0.6), // (400, 600) px -> midpoint (250, 400)
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        calib,
        size,
      );
      expect(pos, const Offset(275.6, 380.8));
      final midpoint = const Offset(250.0, 400.0);
      final dist = (pos! - midpoint).distance;
      expect(dist, closeTo(32.0, 0.001));
    });

    test('getMeasurementLabelPosition with customLabelOffset for CalibrationEntity adds relative offset', () {
      const calib = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.1, 0.2),
        p2: Offset(0.4, 0.6),
      );
      final displacedCalib = calib.copyWith(
        customLabelOffset: const Offset(0.05, 0.1),
      );
      final basePos = MeasurementCalculator.getMeasurementLabelPosition(
        calib,
        size,
      )!;
      final displacedPos = MeasurementCalculator.getMeasurementLabelPosition(
        displacedCalib,
        size,
      )!;
      expect(displacedPos.dx, closeTo(basePos.dx + 50.0, 0.001));
      expect(displacedPos.dy, closeTo(basePos.dy + 100.0, 0.001));
    });

    test('calculateLineLabelPosition for CalibrationEntity auto-flips downward at top canvas edge', () {
      const calibNearTop = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.2, 0.01), // (200, 10)
        p2: Offset(0.4, 0.01), // (400, 10)
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        calibNearTop,
        size,
      )!;
      // Midpoint: (300, 10). Upward offset would be 10 - 32 = -22 px (off-screen).
      // Flipped downward: 10 + 32 = 42 px.
      expect(pos.dx, closeTo(300.0, 0.001));
      expect(pos.dy, closeTo(42.0, 0.001));
    });

    test('Short calibration lines (< 100px) do not overlap P1 or P2 with badge bounding box', () {
      const shortCalib = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.48, 0.5), // (480, 500)
        p2: Offset(0.52, 0.5), // (520, 500) -> 40px long horizontal line
      );
      final pos = MeasurementCalculator.getMeasurementLabelPosition(
        shortCalib,
        size,
      )!;
      // Midpoint: (500, 500), positioned at (500, 468) (32px offset upwards)
      expect(pos, const Offset(500.0, 468.0));

      const pillWidth = 70.0;
      const pillHeight = 26.0;
      final pillRect = Rect.fromCenter(
        center: pos,
        width: pillWidth,
        height: pillHeight,
      );

      final p1Pix = const Offset(480, 500);
      final p2Pix = const Offset(520, 500);
      const handleRadius = 14.0;
      final handle1Rect = Rect.fromCircle(center: p1Pix, radius: handleRadius);
      final handle2Rect = Rect.fromCircle(center: p2Pix, radius: handleRadius);

      expect(pillRect.overlaps(handle1Rect), isFalse);
      expect(pillRect.overlaps(handle2Rect), isFalse);
    });

    test('getEntityHandlePoints extracts correct handle points for CalibrationEntity', () {
      const calib = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.2, 0.4),
        p2: Offset(0.6, 0.4),
      );
      final handles = MeasurementCalculator.getEntityHandlePoints(calib, size);
      expect(handles.length, 2);
      expect(handles[0], const Offset(200, 400));
      expect(handles[1], const Offset(600, 400));
    });

    test('getMeasurementAnchorPosition returns correct anchor for all entity types', () {
      const calib = CalibrationEntity(
        id: 'C1',
        p1: Offset(0.2, 0.4),
        p2: Offset(0.6, 0.4),
      );
      expect(
        MeasurementCalculator.getMeasurementAnchorPosition(calib, size),
        const Offset(400, 400),
      );

      const line = LineEntity(
        id: 'L1',
        p1: Offset(0.1, 0.2),
        p2: Offset(0.3, 0.6),
        color: Colors.blue,
      );
      expect(
        MeasurementCalculator.getMeasurementAnchorPosition(line, size),
        const Offset(200, 400),
      );

      const rect = RectangleEntity(
        id: 'R1',
        p1: Offset(0.1, 0.1),
        p2: Offset(0.3, 0.5),
        color: Colors.green,
      );
      expect(
        MeasurementCalculator.getMeasurementAnchorPosition(rect, size),
        const Offset(200, 300),
      );

      const poly = PolygonEntity(
        id: 'P1',
        points: [
          Offset(0, 0),
          Offset(0.3, 0),
          Offset(0.3, 0.3),
          Offset(0, 0.3),
        ],
        color: Colors.purple,
        isClosed: true,
      );
      expect(
        MeasurementCalculator.getMeasurementAnchorPosition(poly, size),
        const Offset(150, 150),
      );

      const angle = AngleEntity(
        id: 'A1',
        p1: Offset(0.5, 0.5),
        p2: Offset(0.8, 0.5),
        color: Colors.amber,
      );
      expect(
        MeasurementCalculator.getMeasurementAnchorPosition(angle, size),
        const Offset(500, 500),
      );
    });
  });
}
