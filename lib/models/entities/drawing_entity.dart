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

  const factory DrawingEntity.line({
    required String id,
    required Offset p1,
    required Offset p2,
    required Color color,
  }) = LineEntity;

  const factory DrawingEntity.polygon({
    required String id,
    required List<Offset> points,
    required Color color,
    @Default(false) bool isClosed,
  }) = PolygonEntity;

  const factory DrawingEntity.rectangle({
    required String id,
    required Offset p1,
    required Offset p2,
    required Color color,
  }) = RectangleEntity;

  const factory DrawingEntity.angle({
    required String id,
    required Offset p1,
    required Offset p2,
    required Color color,
  }) = AngleEntity;
}
