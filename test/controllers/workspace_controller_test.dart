import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/services/image_loader_service.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';

class MockImageLoaderService extends Mock implements ImageLoaderService {}

void main() {
  group('WorkspaceController', () {
    late ProviderContainer container;
    late MockImageLoaderService mockImageLoaderService;

    setUp(() {
      mockImageLoaderService = MockImageLoaderService();
      container = ProviderContainer(
        overrides: [
          imageLoaderServiceProvider.overrideWithValue(mockImageLoaderService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('addOrUpdateEntity and removeEntity', () {
      final controller = container.read(workspaceControllerProvider.notifier);

      const entity = DrawingEntity.calibration(id: 'calib_1');
      controller.addOrUpdateEntity(entity);

      var state = container.read(workspaceControllerProvider);
      expect(state.entities.length, 1);
      expect(state.entities.first.id, 'calib_1');

      controller.removeEntity('calib_1');
      state = container.read(workspaceControllerProvider);
      expect(state.entities.isEmpty, isTrue);
    });

    test(
      'loadFromPicker success sets loading state and then success state',
      () async {
        final mockImage = LoadedImageInfo(
          fileName: 'test.png',
          bytes: Uint8List(0),
          width: 800,
          height: 600,
          fileSizeBytes: 0,
        );

        when(() => mockImageLoaderService.pickImageFromFile())
            .thenAnswer((_) async => mockImage);

        final controller = container.read(workspaceControllerProvider.notifier);

        final states = <WorkspaceState>[];
        container.listen(workspaceControllerProvider, (previous, next) {
          states.add(next);
        }, fireImmediately: false);

        controller.loadFromPicker();

        // Allow async operation to complete
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0].status, LoadingStatus.loading);
        expect(states[1].status, LoadingStatus.success);
        expect(states[1].loadedImage, mockImage);
      },
    );

    test('loadFromPicker failure sets error state', () async {
      when(() => mockImageLoaderService.pickImageFromFile())
          .thenThrow(Exception('Simulated error'));

      final controller = container.read(workspaceControllerProvider.notifier);

      final states = <WorkspaceState>[];
      container.listen(workspaceControllerProvider, (previous, next) {
        states.add(next);
      }, fireImmediately: false);

      controller.loadFromPicker();

      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, LoadingStatus.loading);
      expect(states[1].status, LoadingStatus.error);
      expect(states[1].statusMessage, WorkspaceError.loadFailed);
    });

    test('clearCalibration removes the default calibration entity', () {
      final controller = container.read(workspaceControllerProvider.notifier);
      const entity = DrawingEntity.calibration(
        id: CalibrationTool.defaultCalibrationId,
      );

      controller.addOrUpdateEntity(entity);
      expect(container.read(workspaceControllerProvider).entities.length, 1);

      controller.clearCalibration();
      expect(
        container.read(workspaceControllerProvider).entities.isEmpty,
        isTrue,
      );
    });

    test(
      'canLeaveCalibrationStep prevents leaving with unconfirmed points',
      () {
        final controller = container.read(workspaceControllerProvider.notifier);

        // Initially, it's true (no calibration entity)
        expect(controller.canLeaveCalibrationStep(), isTrue);

        // Add a calibration entity with p1 but NOT confirmed
        const unconfirmedEntity = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.5, 0.5),
          isConfirmed: false,
        );
        controller.addOrUpdateEntity(unconfirmedEntity);
        expect(controller.canLeaveCalibrationStep(), isFalse);

        // Add a confirmed entity
        const confirmedEntity = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.5, 0.5),
          p2: Offset(0.6, 0.6),
          isConfirmed: true,
        );
        controller.addOrUpdateEntity(confirmedEntity);
        expect(controller.canLeaveCalibrationStep(), isTrue);
      },
    );
  });
}
