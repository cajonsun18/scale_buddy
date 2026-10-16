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

  group('MobileCalibrationState', () {
    test('calculateEffectiveState resolves correct state from points, confirmation, entity, and overrides', () {
      const state = MobileCalibrationState();

      // No points
      expect(
        state.calculateEffectiveState(),
        MobileCalibrationStepState.initial,
      );

      // Only p1
      expect(
        state.calculateEffectiveState(p1: const Offset(0.2, 0.2)),
        MobileCalibrationStepState.onePoint,
      );

      // p1 and p2 unconfirmed
      expect(
        state.calculateEffectiveState(
          p1: const Offset(0.2, 0.2),
          p2: const Offset(0.8, 0.8),
          isConfirmed: false,
        ),
        MobileCalibrationStepState.twoPointsInput,
      );

      // Confirmed
      expect(
        state.calculateEffectiveState(
          p1: const Offset(0.2, 0.2),
          p2: const Offset(0.8, 0.8),
          isConfirmed: true,
        ),
        MobileCalibrationStepState.confirmed,
      );

      // Overrides
      expect(
        const MobileCalibrationState(
          stepState: MobileCalibrationStepState.confirmed,
        ).calculateEffectiveState(),
        MobileCalibrationStepState.confirmed,
      );
      expect(
        const MobileCalibrationState(
          stepState: MobileCalibrationStepState.twoPointsInput,
        ).calculateEffectiveState(),
        MobileCalibrationStepState.twoPointsInput,
      );
      expect(
        const MobileCalibrationState(
          stepState: MobileCalibrationStepState.onePoint,
        ).calculateEffectiveState(),
        MobileCalibrationStepState.onePoint,
      );

      // Entity resolution
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
    });

    test('calculatePixelFactor and formatConfirmedText compute pixel factors and labels across units', () {
      // 1000x1000 image, p1 at (0.2, 0.5), p2 at (0.4079, 0.5)
      // distance in pixel = 207.9 px; enteredDistance = 2.10 m -> (207.9 / 2.10) = 99 px
      final factor = MobileCalibrationState.calculatePixelFactor(
        p1: const Offset(0.2, 0.5),
        p2: const Offset(0.4079, 0.5),
        enteredDistance: 2.10,
        imageSize: const Size(1000, 1000),
      );
      expect(factor, 99);

      // Formatted text for meters
      final image = createMockImage(width: 1000, height: 1000);
      const calibM = DrawingEntity.calibration(
        id: 'calib_1',
        p1: Offset(0.2, 0.5),
        p2: Offset(0.4079, 0.5),
        enteredDistance: 2.10,
        selectedUnit: 'm',
        isConfirmed: true,
      );
      expect(
        MobileCalibrationState.formatConfirmedText(
          calib: calibM as CalibrationEntity,
          imageInfo: image,
        ),
        '✓ Maßstab kalibriert: 1 m = 99 px',
      );

      // Formatted text for centimeters (500 px / 50 = 10 px)
      const calibCm = DrawingEntity.calibration(
        id: 'calib_2',
        p1: Offset(0.1, 0.5),
        p2: Offset(0.6, 0.5),
        enteredDistance: 50.0,
        selectedUnit: 'cm',
        isConfirmed: true,
      );
      expect(
        MobileCalibrationState.formatConfirmedText(
          calib: calibCm as CalibrationEntity,
          imageInfo: image,
        ),
        '✓ Maßstab kalibriert: 1 cm = 10 px',
      );
    });

    test(
      'MobileCalibrationNotifier transitions state through helper methods',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          mobileCalibrationStateProvider.notifier,
        );
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
      },
    );
  });
}
