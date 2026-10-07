import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';

void main() {
  group('DrawingEntity', () {
    test('supports calibration entity', () {
      final entity = DrawingEntity.calibration(
        id: '1',
        p1: const Offset(0, 0),
        p2: const Offset(10, 10),
      );

      expect(entity.id, '1');
      expect((entity as CalibrationEntity).p1, const Offset(0, 0));
    });

    test('supports line entity', () {
      final entity = DrawingEntity.line(
        id: '2',
        color: const Color(0xFF000000),
      );
      expect(entity.id, '2');
      expect((entity as LineEntity).color, const Color(0xFF000000));
    });
  });
}
