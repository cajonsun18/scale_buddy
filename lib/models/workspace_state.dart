import 'package:freezed_annotation/freezed_annotation.dart';

import 'loaded_image_info.dart';
import 'entities/drawing_entity.dart';
import 'drag_detail.dart';

part 'workspace_state.freezed.dart';

enum LoadingStatus { initial, loading, success, error }

enum WorkspaceError { none, loadFailed, selectionCancelled, unknown }

@freezed
sealed class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    LoadedImageInfo? loadedImage,
    @Default(LoadingStatus.initial) LoadingStatus status,
    @Default(WorkspaceError.none) WorkspaceError statusMessage,

    @Default([]) List<DrawingEntity> entities,
    String? selectedEntityId,
    DragDetail? activeDragDetail,
  }) = _WorkspaceState;
}
