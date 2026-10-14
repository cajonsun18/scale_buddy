import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_calibration_state.dart';

void main() {
  LoadedImageInfo createMockImage({int width = 1000, int height = 1000}) {
    return LoadedImageInfo(
      fileName: 'mock.png',
      fileSizeBytes: 100,
      bytes: Uint8List(0),
      width: width,
      height: height,
    );
  }

  group('MobileCalibrationState calculateEffectiveState', () {
    test('returns initial when no points set', () {
      const state = MobileCalibrationState();
      expect(
        state.calculateEffectiveState(),
        MobileCalibrationStepState.initial,
      );
    });

    test('returns onePoint when only p1 is set', () {
      const state = MobileCalibrationState();
      expect(
        state.calculateEffectiveState(p1: const Offset(0.2, 0.2)),
        MobileCalibrationStepState.onePoint,
      );
    });

    test(
      'returns twoPointsInput when both p1 and p2 are set but not confirmed',
      () {
        const state = MobileCalibrationState();
        expect(
          state.calculateEffectiveState(
            p1: const Offset(0.2, 0.2),
            p2: const Offset(0.8, 0.8),
            isConfirmed: false,
          ),
          MobileCalibrationStepState.twoPointsInput,
        );
      },
    );

    test('returns confirmed when isConfirmed is true', () {
      const state = MobileCalibrationState();
      expect(
        state.calculateEffectiveState(
          p1: const Offset(0.2, 0.2),
          p2: const Offset(0.8, 0.8),
          isConfirmed: true,
        ),
        MobileCalibrationStepState.confirmed,
      );
    });

    test('respects stepState overrides', () {
      const confirmedState = MobileCalibrationState(
        stepState: MobileCalibrationStepState.confirmed,
      );
      expect(
        confirmedState.calculateEffectiveState(),
        MobileCalibrationStepState.confirmed,
      );

      const twoPointsState = MobileCalibrationState(
        stepState: MobileCalibrationStepState.twoPointsInput,
      );
      expect(
        twoPointsState.calculateEffectiveState(),
        MobileCalibrationStepState.twoPointsInput,
      );

      const onePointState = MobileCalibrationState(
        stepState: MobileCalibrationStepState.onePoint,
      );
      expect(
        onePointState.calculateEffectiveState(),
        MobileCalibrationStepState.onePoint,
      );
    });

    test(
      'calculateEffectiveStateForEntity works cleanly with CalibrationEntity',
      () {
        const state = MobileCalibrationState();
        const entity = DrawingEntity.calibration(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.5, 0.5),
          isConfirmed: true,
        );
        expect(
          state.calculateEffectiveStateForEntity(entity as CalibrationEntity),
          MobileCalibrationStepState.confirmed,
        );
      },
    );
  });

  group('MobileCalibrationState pixel factor & confirmed text', () {
    test('calculatePixelFactor computes correct factor', () {
      // 1000x1000 image, p1 at (0.2, 0.5), p2 at (0.4079, 0.5)
      // distance in pixel = 207.9 px
      // enteredDistance = 2.10 m -> (207.9 / 2.10) = 99 px
      final factor = MobileCalibrationState.calculatePixelFactor(
        p1: const Offset(0.2, 0.5),
        p2: const Offset(0.4079, 0.5),
        enteredDistance: 2.10,
        imageSize: const Size(1000, 1000),
      );
      expect(factor, 99);
    });

    test('formatConfirmedText returns expected formatted string for m', () {
      final image = createMockImage(width: 1000, height: 1000);
      const calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.2, 0.5),
        p2: Offset(0.4079, 0.5),
        enteredDistance: 2.10,
        selectedUnit: 'm',
        isConfirmed: true,
      );

      final text = MobileCalibrationState.formatConfirmedText(
        calib: calib as CalibrationEntity,
        imageInfo: image,
      );
      expect(text, '✓ Maßstab kalibriert: 1 m = 99 px');
    });

    test('formatConfirmedText handles custom unit such as cm', () {
      final image = createMockImage(width: 1000, height: 1000);
      const calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.1, 0.5),
        p2: Offset(0.6, 0.5),
        enteredDistance: 50.0,
        selectedUnit: 'cm',
        isConfirmed: true,
      );

      // pixel dist = 500 px. 500 / 50 = 10 px
      final text = MobileCalibrationState.formatConfirmedText(
        calib: calib as CalibrationEntity,
        imageInfo: image,
      );
      expect(text, '✓ Maßstab kalibriert: 1 cm = 10 px');
    });
  });

  group('MobileCalibrationNotifier', () {
    test('transitions state through helper methods', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobileCalibrationStateProvider.notifier);
      expect(
        container.read(mobileCalibrationStateProvider).stepState,
        MobileCalibrationStepState.initial,
      );

      notifier.setOnePoint();
      expect(
        container.read(mobileCalibrationStateProvider).stepState,
        MobileCalibrationStepState.onePoint,
      );

      notifier.setTwoPointsInput();
      expect(
        container.read(mobileCalibrationStateProvider).stepState,
        MobileCalibrationStepState.twoPointsInput,
      );

      notifier.setConfirmed();
      expect(
        container.read(mobileCalibrationStateProvider).stepState,
        MobileCalibrationStepState.confirmed,
      );

      notifier.reset();
      expect(
        container.read(mobileCalibrationStateProvider).stepState,
        MobileCalibrationStepState.initial,
      );
    });
  });
}
