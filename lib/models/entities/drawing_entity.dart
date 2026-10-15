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
    Offset? p1,
    Offset? p2,
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
    Offset? p1,
    Offset? p2,
    required Color color,
  }) = RectangleEntity;

  const factory DrawingEntity.angle({
    required String id,
    Offset? p1,
    Offset? p2,
    required Color color,
  }) = AngleEntity;

  const factory DrawingEntity.perspective({
    required String id,
    required List<Offset> points,
    required Color color,
  }) = PerspectiveEntity;
}

/// Status- und Hilfsfunktionen für DrawingEntity.
extension DrawingEntityStatus on DrawingEntity {
  /// Prüft, ob ein Zeichenelement vollständig abgeschlossen ist.
  bool get isCompleted => map(
    calibration: (c) => c.p1 != null && c.p2 != null,
    perspective: (p) => p.points.length == 4,
    line: (l) => l.p1 != null && l.p2 != null,
    rectangle: (r) => r.p1 != null && r.p2 != null,
    polygon: (p) => p.isClosed && p.points.length >= 3,
    angle: (a) => a.p1 != null && a.p2 != null,
  );

  /// Prüft, ob ein Zeichenelement noch in Bearbeitung / unvollständig ist.
  bool get isOpen => !isCompleted;

  /// Prüft, ob das Element ein Messwerkzeug ist (Strecke, Rechteck, Polygon, Winkel).
  bool get isMeasurement =>
      this is LineEntity ||
      this is RectangleEntity ||
      this is PolygonEntity ||
      this is AngleEntity;
}
