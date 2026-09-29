import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/loaded_image_info.dart';
import '../models/workspace_state.dart';
import '../models/entities/drawing_entity.dart';
import '../services/image_loader_service.dart';
import '../tools/workspace_tool.dart';
import '../tools/calibration_tool.dart';

class ActiveToolNotifier extends Notifier<WorkspaceTool> {
  @override
  WorkspaceTool build() => const CalibrationTool();
}

final activeToolProvider = NotifierProvider<ActiveToolNotifier, WorkspaceTool>(ActiveToolNotifier.new);

// Provider für den zentralen Controller
final workspaceControllerProvider = NotifierProvider<WorkspaceController, WorkspaceState>(WorkspaceController.new);

final transformationControllerProvider = Provider<TransformationController>((ref) {
  final controller = TransformationController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class WorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return const WorkspaceState();
  }

  void clearImage() {
    state = const WorkspaceState();
  }

    // --- Generische Entity-Methoden ---

  void addOrUpdateEntity(DrawingEntity entity) {
    final newList = List<DrawingEntity>.from(state.entities);
    final index = newList.indexWhere((e) => e.id == entity.id);
    if (index >= 0) {
      newList[index] = entity;
    } else {
      newList.add(entity);
    }
    state = state.copyWith(entities: newList);
  }

  void removeEntity(String id) {
    final newList = state.entities.where((e) => e.id != id).toList();
    state = state.copyWith(entities: newList);
  }

  void clearCalibration() {
    removeEntity(CalibrationTool.defaultCalibrationId);
  }

  bool canLeaveCalibrationStep() {
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    if (calib != null && calib.p1 != null && !calib.isConfirmed) {
      return false;
    }
    return true;
  }

  // --- Lade-Logiken ---

  Future<void> _performImageLoad(
    Future<LoadedImageInfo?> Function() loaderAction,
  ) async {
    state = state.copyWith(status: LoadingStatus.loading, statusMessage: WorkspaceError.none);

    try {
      final info = await loaderAction();
      if (info != null) {
        state = state.copyWith(
          loadedImage: info,
          status: LoadingStatus.success,
        );
      } else {
        state = state.copyWith(
          status: LoadingStatus.error,
          statusMessage: WorkspaceError.selectionCancelled,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: LoadingStatus.error,
        statusMessage: WorkspaceError.loadFailed,
      );
    }
  }

  void loadFromPicker() => _performImageLoad(() => ref.read(imageLoaderServiceProvider).pickImageFromFile());

  void loadSample() => _performImageLoad(() => ref.read(imageLoaderServiceProvider).generateSampleFloorPlan());

  void pasteFromClipboard() => _performImageLoad(() => ref.read(imageLoaderServiceProvider).pasteFromClipboard());

  void handleDroppedBytes(List<Uint8List> chunks) {
    if (chunks.isEmpty) return;
    final combined = chunks.length == 1
        ? chunks.first
        : (() {
            final builder = BytesBuilder(copy: false);
            for (final c in chunks) {
              builder.add(c);
            }
            return builder.toBytes();
          })();
    
    _performImageLoad(() => ref.read(imageLoaderServiceProvider).loadFromBytes(combined));
  }

  void handleDroppedFilePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    _performImageLoad(() => ref.read(imageLoaderServiceProvider).loadFromPaths(paths));
  }

  // --- WERKZEUG-ROUTING (NEU) ---
  
  void handleTapUp(TapUpDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    state = tool.onTapUp(state, details, size);
  }

  void handlePanStart(DragStartDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    state = tool.onPanStart(state, details, size);
  }

  void handlePanUpdate(DragUpdateDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    state = tool.onPanUpdate(state, details, size);
  }

  void handlePanEnd(DragEndDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    state = tool.onPanEnd(state, details, size);
  }
}

