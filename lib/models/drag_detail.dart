import 'package:freezed_annotation/freezed_annotation.dart';

part 'drag_detail.freezed.dart';

@freezed
sealed class DragDetail with _$DragDetail {
  const factory DragDetail.calibrationPoint({required bool isP1}) =
      DragDetailCalibrationPoint;
  const factory DragDetail.label() = DragDetailLabel;
  const factory DragDetail.entityPoint({
    required String entityId,
    required int pointIndex,
  }) = DragDetailEntityPoint;
}
