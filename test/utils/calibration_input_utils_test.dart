import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/utils/calibration_input_utils.dart';

void main() {
  group('CalibrationInputUtils - parseDistance & isValidDistance', () {
    test('parses decimal point and comma correctly', () {
      expect(CalibrationInputUtils.parseDistance('2.5'), 2.5);
      expect(CalibrationInputUtils.parseDistance('2,5'), 2.5);
      expect(CalibrationInputUtils.parseDistance('123.45'), 123.45);
      expect(CalibrationInputUtils.parseDistance('123,45'), 123.45);
    });

    test('trims surrounding whitespace and line breaks', () {
      expect(CalibrationInputUtils.parseDistance('  3.14  '), 3.14);
      expect(CalibrationInputUtils.parseDistance('\t10,5\n'), 10.5);
    });

    test('parses leading separator properly', () {
      expect(CalibrationInputUtils.parseDistance('.5'), 0.5);
      expect(CalibrationInputUtils.parseDistance(',5'), 0.5);
    });

    test('rejects zero, negative and non-numeric inputs', () {
      expect(CalibrationInputUtils.parseDistance('0'), isNull);
      expect(CalibrationInputUtils.parseDistance('0.0'), isNull);
      expect(CalibrationInputUtils.parseDistance('0,00'), isNull);
      expect(CalibrationInputUtils.parseDistance('-1'), isNull);
      expect(CalibrationInputUtils.parseDistance('-2.5'), isNull);
      expect(CalibrationInputUtils.parseDistance('abc'), isNull);
      expect(CalibrationInputUtils.parseDistance('12a'), isNull);
      expect(CalibrationInputUtils.parseDistance(''), isNull);
      expect(CalibrationInputUtils.parseDistance('   '), isNull);
      expect(CalibrationInputUtils.parseDistance(null), isNull);
      expect(CalibrationInputUtils.parseDistance('1.2.3'), isNull);
    });

    test('isValidDistance matches parseDistance != null', () {
      expect(CalibrationInputUtils.isValidDistance('2.5'), isTrue);
      expect(CalibrationInputUtils.isValidDistance('0'), isFalse);
      expect(CalibrationInputUtils.isValidDistance('abc'), isFalse);
    });
  });

  group('CalibrationInputUtils - Units & Conversion', () {
    test('isValidUnit checks supported units', () {
      expect(CalibrationInputUtils.isValidUnit('m'), isTrue);
      expect(CalibrationInputUtils.isValidUnit('cm'), isTrue);
      expect(CalibrationInputUtils.isValidUnit('mm'), isTrue);
      expect(CalibrationInputUtils.isValidUnit('km'), isFalse);
      expect(CalibrationInputUtils.isValidUnit('inch'), isFalse);
      expect(CalibrationInputUtils.isValidUnit(null), isFalse);
    });

    test('convertToMeters converts correctly', () {
      expect(CalibrationInputUtils.convertToMeters(2.5, 'm'), 2.5);
      expect(CalibrationInputUtils.convertToMeters(250.0, 'cm'), 2.5);
      expect(CalibrationInputUtils.convertToMeters(2500.0, 'mm'), 2.5);
      expect(CalibrationInputUtils.convertToMeters(0, 'm'), isNull);
      expect(CalibrationInputUtils.convertToMeters(-5, 'm'), isNull);
      expect(CalibrationInputUtils.convertToMeters(null, 'm'), isNull);
    });
  });

  group('CalibrationInputUtils - formatDistance', () {
    test('formats distance with trimmed trailing .0 by default', () {
      expect(CalibrationInputUtils.formatDistance(5.0), '5');
      expect(CalibrationInputUtils.formatDistance(5.25), '5.25');
      expect(CalibrationInputUtils.formatDistance(null), '');
    });

    test('formats distance with comma and fixed decimal places', () {
      expect(
        CalibrationInputUtils.formatDistance(
          2.5,
          useComma: true,
          decimalPlaces: 2,
        ),
        '2,50',
      );
      expect(
        CalibrationInputUtils.formatDistance(
          2.1,
          useComma: false,
          decimalPlaces: 2,
        ),
        '2.10',
      );
    });
  });

  group('CalibrationInputUtils - canInsertChar', () {
    test('allows single comma or dot', () {
      expect(CalibrationInputUtils.canInsertChar('12', ','), isTrue);
      expect(CalibrationInputUtils.canInsertChar('12', '.'), isTrue);
    });

    test('rejects second comma or dot', () {
      expect(CalibrationInputUtils.canInsertChar('12,5', ','), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12.5', ','), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12,5', '.'), isFalse);
    });

    test('rejects non-digit characters', () {
      expect(CalibrationInputUtils.canInsertChar('12', 'a'), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12', '-'), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12', ' '), isFalse);
    });

    test('enforces max decimals', () {
      expect(CalibrationInputUtils.canInsertChar('12,5', '0'), isTrue);
      expect(CalibrationInputUtils.canInsertChar('12,50', '5'), isFalse);
      // But allows inserting before separator
      expect(
        CalibrationInputUtils.canInsertChar(
          '12,50',
          '5',
          selection: const TextSelection.collapsed(offset: 1),
        ),
        isTrue,
      );
      // And allows replacing when text selected
      expect(
        CalibrationInputUtils.canInsertChar(
          '12,50',
          '5',
          selection: const TextSelection(baseOffset: 3, extentOffset: 5),
        ),
        isTrue,
      );
    });
  });
}
