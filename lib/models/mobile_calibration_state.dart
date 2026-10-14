import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entities/drawing_entity.dart';
import 'loaded_image_info.dart';

/// Die 4 Workflow-Zustände der mobilen Maßstabs-Kalibrierung (Schritt 3).
enum MobileCalibrationStepState {
  /// Phase 1: 0 Punkte gesetzt. Startzustand.
  initial,

  /// Phase 2: Punkt 1 gesetzt (1 von 2 Punkten).
  onePoint,

  /// Phase 3: Beide Punkte gesetzt, Eingabe der realen Länge aktiv.
  twoPointsInput,

  /// Phase 4: Maßstab erfolgreich bestätigt und kalibriert.
  confirmed,
}

class MobileCalibrationState {
  final MobileCalibrationStepState stepState;

  const MobileCalibrationState({
    this.stepState = MobileCalibrationStepState.initial,
  });

  MobileCalibrationState copyWith({MobileCalibrationStepState? stepState}) {
    return MobileCalibrationState(stepState: stepState ?? this.stepState);
  }

  /// Ermittelt den effektiven Zustand unter Berücksichtigung von Punkten und Kalibrierungsstatus.
  MobileCalibrationStepState calculateEffectiveState({
    Offset? p1,
    Offset? p2,
    bool isConfirmed = false,
  }) {
    if (isConfirmed || stepState == MobileCalibrationStepState.confirmed) {
      return MobileCalibrationStepState.confirmed;
    } else if ((p1 != null && p2 != null) ||
        stepState == MobileCalibrationStepState.twoPointsInput) {
      return MobileCalibrationStepState.twoPointsInput;
    } else if (p1 != null || stepState == MobileCalibrationStepState.onePoint) {
      return MobileCalibrationStepState.onePoint;
    } else {
      return MobileCalibrationStepState.initial;
    }
  }

  /// Ermittelt den effektiven Zustand anhand einer [CalibrationEntity].
  MobileCalibrationStepState calculateEffectiveStateForEntity(
    CalibrationEntity? entity,
  ) {
    return calculateEffectiveState(
      p1: entity?.p1,
      p2: entity?.p2,
      isConfirmed: entity?.isConfirmed ?? false,
    );
  }

  /// Berechnet den dynamischen Pixel-Faktor für Phase 4: "1 [Einheit] = X px".
  static int calculatePixelFactor({
    required Offset p1,
    required Offset p2,
    required double enteredDistance,
    required Size imageSize,
  }) {
    if (enteredDistance <= 0 || imageSize.width <= 0 || imageSize.height <= 0) {
      return 0;
    }
    final p1Pix = Offset(p1.dx * imageSize.width, p1.dy * imageSize.height);
    final p2Pix = Offset(p2.dx * imageSize.width, p2.dy * imageSize.height);
    final pixelDistance = (p2Pix - p1Pix).distance;
    return (pixelDistance / enteredDistance).round();
  }

  /// Erzeugt den formatierten Bestätigungstext für Phase 4.
  static String formatConfirmedText({
    required CalibrationEntity? calib,
    required LoadedImageInfo? imageInfo,
  }) {
    final unit = calib?.selectedUnit ?? 'm';
    if (calib == null ||
        calib.p1 == null ||
        calib.p2 == null ||
        calib.enteredDistance == null ||
        imageInfo == null) {
      return '✓ Maßstab kalibriert: 1 $unit = 0 px';
    }

    final factor = calculatePixelFactor(
      p1: calib.p1!,
      p2: calib.p2!,
      enteredDistance: calib.enteredDistance!,
      imageSize: Size(imageInfo.width.toDouble(), imageInfo.height.toDouble()),
    );

    return '✓ Maßstab kalibriert: 1 $unit = $factor px';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MobileCalibrationState &&
          runtimeType == other.runtimeType &&
          stepState == other.stepState;

  @override
  int get hashCode => stepState.hashCode;
}

class MobileCalibrationNotifier extends Notifier<MobileCalibrationState> {
  @override
  MobileCalibrationState build() => const MobileCalibrationState();

  void setInitial() {
    state = const MobileCalibrationState(
      stepState: MobileCalibrationStepState.initial,
    );
  }

  void setOnePoint() {
    state = const MobileCalibrationState(
      stepState: MobileCalibrationStepState.onePoint,
    );
  }

  void setTwoPointsInput() {
    state = const MobileCalibrationState(
      stepState: MobileCalibrationStepState.twoPointsInput,
    );
  }

  void setConfirmed() {
    state = const MobileCalibrationState(
      stepState: MobileCalibrationStepState.confirmed,
    );
  }

  void reset() => setInitial();
}

final mobileCalibrationStateProvider =
    NotifierProvider<MobileCalibrationNotifier, MobileCalibrationState>(
      MobileCalibrationNotifier.new,
    );
