import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/utils/calibration_input_utils.dart';

void main() {
  group('CalibrationInputUtils', () {
    test('parseDistance & isValidDistance correctly parse valid inputs and reject invalid/negative inputs', () {
      // Valid decimal points and commas
      expect(CalibrationInputUtils.parseDistance('2.5'), 2.5);
      expect(CalibrationInputUtils.parseDistance('2,5'), 2.5);
      expect(CalibrationInputUtils.parseDistance('123.45'), 123.45);
      expect(CalibrationInputUtils.parseDistance('123,45'), 123.45);

      // Trimming surrounding whitespace
      expect(CalibrationInputUtils.parseDistance('  3.14  '), 3.14);
      expect(CalibrationInputUtils.parseDistance('\t10,5\n'), 10.5);

      // Leading separators
      expect(CalibrationInputUtils.parseDistance('.5'), 0.5);
      expect(CalibrationInputUtils.parseDistance(',5'), 0.5);

      // Rejection of zero, negative, empty and non-numeric inputs
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

      // isValidDistance consistency
      expect(CalibrationInputUtils.isValidDistance('2.5'), isTrue);
      expect(CalibrationInputUtils.isValidDistance('0'), isFalse);
      expect(CalibrationInputUtils.isValidDistance('abc'), isFalse);
    });

    test('isValidUnit and convertToMeters handle supported units and conversion logic', () {
      // Unit validation
      expect(CalibrationInputUtils.isValidUnit('m'), isTrue);
      expect(CalibrationInputUtils.isValidUnit('cm'), isTrue);
      expect(CalibrationInputUtils.isValidUnit('mm'), isTrue);
      expect(CalibrationInputUtils.isValidUnit('km'), isFalse);
      expect(CalibrationInputUtils.isValidUnit('inch'), isFalse);
      expect(CalibrationInputUtils.isValidUnit(null), isFalse);

      // Conversion
      expect(CalibrationInputUtils.convertToMeters(2.5, 'm'), 2.5);
      expect(CalibrationInputUtils.convertToMeters(250.0, 'cm'), 2.5);
      expect(CalibrationInputUtils.convertToMeters(2500.0, 'mm'), 2.5);
      expect(CalibrationInputUtils.convertToMeters(0, 'm'), isNull);
      expect(CalibrationInputUtils.convertToMeters(-5, 'm'), isNull);
      expect(CalibrationInputUtils.convertToMeters(null, 'm'), isNull);
    });

    test('formatDistance formats distances with decimal trimming and locale formatting', () {
      // Default formatting with trimming
      expect(CalibrationInputUtils.formatDistance(5.0), '5');
      expect(CalibrationInputUtils.formatDistance(5.25), '5.25');
      expect(CalibrationInputUtils.formatDistance(null), '');

      // Comma and fixed decimal places
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

    test('canInsertChar validates character insertions, decimals limit, and selections', () {
      // Allowed comma/dot
      expect(CalibrationInputUtils.canInsertChar('12', ','), isTrue);
      expect(CalibrationInputUtils.canInsertChar('12', '.'), isTrue);

      // Duplicate comma/dot rejected
      expect(CalibrationInputUtils.canInsertChar('12,5', ','), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12.5', ','), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12,5', '.'), isFalse);

      // Non-digits rejected
      expect(CalibrationInputUtils.canInsertChar('12', 'a'), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12', '-'), isFalse);
      expect(CalibrationInputUtils.canInsertChar('12', ' '), isFalse);

      // Max decimal places enforcement and selection handling
      expect(CalibrationInputUtils.canInsertChar('12,5', '0'), isTrue);
      expect(CalibrationInputUtils.canInsertChar('12,50', '5'), isFalse);
      expect(
        CalibrationInputUtils.canInsertChar(
          '12,50',
          '5',
          selection: const TextSelection.collapsed(offset: 1),
        ),
        isTrue,
      );
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
