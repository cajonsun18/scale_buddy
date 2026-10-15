import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/theme/measure_tool_colors.dart';

void main() {
  group('MeasureToolColors', () {
    test('defines unified colors for desktop and mobile measurement tools', () {
      expect(MeasureToolColors.distance, const Color(0xFF38BDF8));
      expect(MeasureToolColors.rectangle, const Color(0xFF10B981));
      expect(MeasureToolColors.polygon, const Color(0xFFA855F7));
      expect(MeasureToolColors.angle, const Color(0xFFF59E0B));
      expect(MeasureToolColors.select, const Color(0xFF3B82F6));
    });
  });
}
