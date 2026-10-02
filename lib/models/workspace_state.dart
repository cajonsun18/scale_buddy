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

  const WorkspaceState._();

  WorkspaceState removeEntity(String id) {
    final newList = List<DrawingEntity>.from(entities)
      ..removeWhere((e) => e.id == id);
    return copyWith(entities: newList);
  }

  WorkspaceState addOrUpdateEntity(DrawingEntity entity) {
    final newList = List<DrawingEntity>.from(entities);
    final index = newList.indexWhere((e) => e.id == entity.id);
    if (index >= 0) {
      newList[index] = entity;
    } else {
      newList.add(entity);
    }
    return copyWith(entities: newList);
  }

  WorkspaceState updateEntity(
    String id,
    DrawingEntity Function(DrawingEntity) update,
  ) {
    final index = entities.indexWhere((e) => e.id == id);
    if (index == -1) return this;
    final newList = List<DrawingEntity>.from(entities);
    newList[index] = update(newList[index]);
    return copyWith(entities: newList);
  }
}
