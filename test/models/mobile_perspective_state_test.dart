import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/mobile_perspective_state.dart';

void main() {
  group('MobilePerspectiveState calculateEffectiveState', () {
    test(
      'returns rectified when isWarped is true or stepState is rectified',
      () {
        const state = MobilePerspectiveState();
        expect(
          state.calculateEffectiveState(pointsCount: 0, isWarped: true),
          MobilePerspectiveStepState.rectified,
        );

        const rectifiedState = MobilePerspectiveState(
          stepState: MobilePerspectiveStepState.rectified,
        );
        expect(
          rectifiedState.calculateEffectiveState(
            pointsCount: 4,
            isWarped: false,
          ),
          MobilePerspectiveStepState.rectified,
        );
      },
    );

    test(
      'returns ready4Points when pointsCount is 4 or stepState is ready4Points',
      () {
        const state = MobilePerspectiveState();
        expect(
          state.calculateEffectiveState(pointsCount: 4, isWarped: false),
          MobilePerspectiveStepState.ready4Points,
        );

        const readyState = MobilePerspectiveState(
          stepState: MobilePerspectiveStepState.ready4Points,
        );
        expect(
          readyState.calculateEffectiveState(pointsCount: 0, isWarped: false),
          MobilePerspectiveStepState.ready4Points,
        );
      },
    );

    test('returns manualInProgress when stepState is manualInProgress or pointsCount > 0', () {
      const state = MobilePerspectiveState();
      expect(
        state.calculateEffectiveState(pointsCount: 2, isWarped: false),
        MobilePerspectiveStepState.manualInProgress,
      );

      const manualState = MobilePerspectiveState(
        stepState: MobilePerspectiveStepState.manualInProgress,
      );
      expect(
        manualState.calculateEffectiveState(pointsCount: 0, isWarped: false),
        MobilePerspectiveStepState.manualInProgress,
      );
    });

    test('returns initial when pointsCount is 0, not warped, and stepState is initial', () {
      const state = MobilePerspectiveState(
        stepState: MobilePerspectiveStepState.initial,
      );
      expect(
        state.calculateEffectiveState(pointsCount: 0, isWarped: false),
        MobilePerspectiveStepState.initial,
      );
    });
  });

  group('MobilePerspectiveNotifier', () {
    test('startManual sets stepState to manualInProgress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobilePerspectiveStateProvider.notifier);
      notifier.startManual();

      final state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.manualInProgress);
      expect(state.isAutoDetected, isFalse);
    });

    test('setManualInProgress aliases startManual cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobilePerspectiveStateProvider.notifier);
      notifier.setManualInProgress();

      final state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.manualInProgress);
      expect(state.isAutoDetected, isFalse);
    });

    test('setReady sets ready4Points and isAuto flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobilePerspectiveStateProvider.notifier);
      notifier.setReady(isAuto: true);

      final state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.ready4Points);
      expect(state.isAutoDetected, isTrue);
    });

    test('setRectified sets rectified stepState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobilePerspectiveStateProvider.notifier);
      notifier.setRectified();

      final state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.rectified);
    });

    test('setInitial resets state back to initial', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobilePerspectiveStateProvider.notifier);
      notifier.setReady(isAuto: true);
      notifier.setInitial();

      final state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.initial);
      expect(state.isAutoDetected, isFalse);
    });
  });
}
