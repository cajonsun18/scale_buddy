import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'drawing_entity.freezed.dart';

/// Basis-Klasse für alle gezeichneten Objekte auf dem Bildschirm.
/// Dank "freezed" können wir später einfach neue Werkzeuge wie .line() oder .polygon() anbauen.
@freezed
sealed class DrawingEntity with _$DrawingEntity {
  const factory DrawingEntity.calibration({
    required String id,
    Offset? p1,
    Offset? p2,
    double? enteredDistance,
    @Default('m') String selectedUnit,
    @Default(false) bool isConfirmed,
    @Default(0.5) double labelPosition,
  }) = CalibrationEntity;

  // Später kommen hier ganz einfach hinzu:
  // const factory DrawingEntity.line({ ... }) = LineEntity;
  // const factory DrawingEntity.polygon({ ... }) = PolygonEntity;
}
