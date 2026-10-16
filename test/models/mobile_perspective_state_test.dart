import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/mobile_perspective_state.dart';

void main() {
  group('MobilePerspectiveState', () {
    test('calculateEffectiveState determines step state across points count, warping, and overrides', () {
      const state = MobilePerspectiveState();

      // Rectified when isWarped is true or stepState is rectified
      expect(
        state.calculateEffectiveState(pointsCount: 0, isWarped: true),
        MobilePerspectiveStepState.rectified,
      );
      expect(
        const MobilePerspectiveState(
          stepState: MobilePerspectiveStepState.rectified,
        ).calculateEffectiveState(pointsCount: 4, isWarped: false),
        MobilePerspectiveStepState.rectified,
      );

      // Ready4Points when pointsCount is 4 or stepState is ready4Points
      expect(
        state.calculateEffectiveState(pointsCount: 4, isWarped: false),
        MobilePerspectiveStepState.ready4Points,
      );
      expect(
        const MobilePerspectiveState(
          stepState: MobilePerspectiveStepState.ready4Points,
        ).calculateEffectiveState(pointsCount: 0, isWarped: false),
        MobilePerspectiveStepState.ready4Points,
      );

      // ManualInProgress when stepState is manualInProgress or pointsCount > 0
      expect(
        state.calculateEffectiveState(pointsCount: 2, isWarped: false),
        MobilePerspectiveStepState.manualInProgress,
      );
      expect(
        const MobilePerspectiveState(
          stepState: MobilePerspectiveStepState.manualInProgress,
        ).calculateEffectiveState(pointsCount: 0, isWarped: false),
        MobilePerspectiveStepState.manualInProgress,
      );

      // Initial when pointsCount is 0, not warped, and stepState is initial
      expect(
        const MobilePerspectiveState(
          stepState: MobilePerspectiveStepState.initial,
        ).calculateEffectiveState(pointsCount: 0, isWarped: false),
        MobilePerspectiveStepState.initial,
      );
    });

    test('MobilePerspectiveNotifier updates and resets perspective workflow state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mobilePerspectiveStateProvider.notifier);

      // startManual
      notifier.startManual();
      var state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.manualInProgress);
      expect(state.isAutoDetected, isFalse);

      // setManualInProgress
      notifier.setManualInProgress();
      state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.manualInProgress);
      expect(state.isAutoDetected, isFalse);

      // setReady with isAuto
      notifier.setReady(isAuto: true);
      state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.ready4Points);
      expect(state.isAutoDetected, isTrue);

      // setRectified
      notifier.setRectified();
      state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.rectified);

      // setInitial
      notifier.setInitial();
      state = container.read(mobilePerspectiveStateProvider);
      expect(state.stepState, MobilePerspectiveStepState.initial);
      expect(state.isAutoDetected, isFalse);
    });
  });
}
