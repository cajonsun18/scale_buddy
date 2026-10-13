import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Die 4 Workflow-Zustände der mobilen Perspektiven-Korrektur (Schritt 2).
enum MobilePerspectiveStepState {
  /// Zustand 1: Start-Auswahl („Auto-Entzerrung“, „Manuelle-Entzerrung“, „Überspringen“)
  initial,

  /// Zustand 2: Manuelle Erfassung aktiv, Punkte werden gesetzt (< 4 Punkte)
  manualInProgress,

  /// Zustand 3: 4 Ecken vorhanden (Bereit zum Entzerren)
  ready4Points,

  /// Zustand 4: Bild wurde entzerrt („Punkte anpassen“, „Zurücksetzen“, „Weiter“)
  rectified,
}

class MobilePerspectiveState {
  final MobilePerspectiveStepState stepState;
  final bool isAutoDetected;

  const MobilePerspectiveState({
    this.stepState = MobilePerspectiveStepState.initial,
    this.isAutoDetected = false,
  });

  MobilePerspectiveState copyWith({
    MobilePerspectiveStepState? stepState,
    bool? isAutoDetected,
  }) {
    return MobilePerspectiveState(
      stepState: stepState ?? this.stepState,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
    );
  }

  /// Ermittelt den effektiven Zustand unter Berücksichtigung von Punkten und Entzerrungsstatus.
  MobilePerspectiveStepState calculateEffectiveState({
    required int pointsCount,
    required bool isWarped,
  }) {
    if (isWarped || stepState == MobilePerspectiveStepState.rectified) {
      return MobilePerspectiveStepState.rectified;
    } else if (pointsCount == 4 ||
        stepState == MobilePerspectiveStepState.ready4Points) {
      return MobilePerspectiveStepState.ready4Points;
    } else if (stepState == MobilePerspectiveStepState.manualInProgress ||
        pointsCount > 0) {
      return MobilePerspectiveStepState.manualInProgress;
    } else {
      return MobilePerspectiveStepState.initial;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MobilePerspectiveState &&
          runtimeType == other.runtimeType &&
          stepState == other.stepState &&
          isAutoDetected == other.isAutoDetected;

  @override
  int get hashCode => Object.hash(stepState, isAutoDetected);
}

class MobilePerspectiveNotifier extends Notifier<MobilePerspectiveState> {
  @override
  MobilePerspectiveState build() => const MobilePerspectiveState();

  void setInitial() {
    state = const MobilePerspectiveState(
      stepState: MobilePerspectiveStepState.initial,
      isAutoDetected: false,
    );
  }

  void startManual() {
    state = const MobilePerspectiveState(
      stepState: MobilePerspectiveStepState.manualInProgress,
      isAutoDetected: false,
    );
  }

  void setReady({bool isAuto = false}) {
    state = MobilePerspectiveState(
      stepState: MobilePerspectiveStepState.ready4Points,
      isAutoDetected: isAuto,
    );
  }

  void setManualInProgress() => startManual();

  void setRectified() {
    state = state.copyWith(stepState: MobilePerspectiveStepState.rectified);
  }
}

final mobilePerspectiveStateProvider =
    NotifierProvider<MobilePerspectiveNotifier, MobilePerspectiveState>(
      MobilePerspectiveNotifier.new,
    );
