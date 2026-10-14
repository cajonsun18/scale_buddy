import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/loaded_image_info.dart';
import '../models/workspace_state.dart';
import '../models/drag_detail.dart';
import '../models/entities/drawing_entity.dart';
import '../services/image_loader_service.dart';
import '../tools/workspace_tool.dart';
import '../tools/calibration_tool.dart';

class ActiveToolNotifier extends Notifier<WorkspaceTool> {
  @override
  WorkspaceTool build() => const EmptyTool();

  void setTool(WorkspaceTool tool) {
    state = tool;
  }
}

final activeToolProvider = NotifierProvider<ActiveToolNotifier, WorkspaceTool>(
  ActiveToolNotifier.new,
);

// Provider für den zentralen Controller
final workspaceControllerProvider =
    NotifierProvider<WorkspaceController, WorkspaceState>(
      WorkspaceController.new,
    );

final transformationControllerProvider = Provider<TransformationController>((
  ref,
) {
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
    state = state.copyWith(
      entities: newList,
      selectedEntityId: state.selectedEntityId == id
          ? null
          : state.selectedEntityId,
    );
  }

  void selectEntity(String id) {
    state = state.copyWith(selectedEntityId: id);
  }

  void clearSelection() {
    state = state.copyWith(selectedEntityId: null);
  }

  void clearCalibration() {
    final newList = state.entities
        .where((e) => e is! CalibrationEntity)
        .toList();
    state = state.copyWith(
      entities: newList,
      selectedEntityId:
          state.selectedEntityId == CalibrationTool.defaultCalibrationId
          ? null
          : state.selectedEntityId,
    );
  }

  void updateCalibrationDistance(double? distance) {
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    if (calib != null) {
      addOrUpdateEntity(calib.copyWith(enteredDistance: distance));
    }
  }

  void updateCalibrationUnit(String unit) {
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    if (calib != null) {
      addOrUpdateEntity(calib.copyWith(selectedUnit: unit));
    }
  }

  void confirmCalibration({double? distance, String? unit}) {
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    if (calib != null) {
      addOrUpdateEntity(
        calib.copyWith(
          enteredDistance: distance ?? calib.enteredDistance,
          selectedUnit: unit ?? calib.selectedUnit,
          isConfirmed: true,
        ),
      );
    }
  }

  void unconfirmCalibration() {
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    if (calib != null) {
      addOrUpdateEntity(calib.copyWith(isConfirmed: false));
    }
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
    state = state.copyWith(
      status: LoadingStatus.loading,
      statusMessage: WorkspaceError.none,
    );

    // Yield to let the UI render the loading overlay before opening native dialogs
    await Future.delayed(const Duration(milliseconds: 50));

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

  void loadFromPicker() => _performImageLoad(
    () => ref.read(imageLoaderServiceProvider).pickImageFromFile(),
  );

  void loadFromCamera() => _performImageLoad(
    () => ref.read(imageLoaderServiceProvider).pickImageFromCamera(),
  );

  void loadFromGalleryMobile() => _performImageLoad(
    () => ref.read(imageLoaderServiceProvider).pickImageFromGalleryMobile(),
  );

  void loadSample() => _performImageLoad(
    () => ref.read(imageLoaderServiceProvider).generateSampleFloorPlan(),
  );

  void pasteFromClipboard() => _performImageLoad(
    () => ref.read(imageLoaderServiceProvider).pasteFromClipboard(),
  );

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

    _performImageLoad(
      () => ref.read(imageLoaderServiceProvider).loadFromBytes(combined),
    );
  }

  void handleDroppedFilePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    _performImageLoad(
      () => ref.read(imageLoaderServiceProvider).loadFromPaths(paths),
    );
  }

  void resetPerspective() {
    if (state.originalImage == null) return;
    state = state.copyWith(
      loadedImage: state.originalImage,
      originalImage: null,
      entities: state.preWarpEntities ?? [],
      preWarpEntities: null,
      perspectiveScaleX: 1.0,
      perspectiveScaleY: 1.0,
      status: LoadingStatus.success,
    );
  }

  void clearPerspectiveEntities() {
    if (state.originalImage != null) {
      resetPerspective();
    }
    final remaining = state.entities
        .where((e) => e is! PerspectiveEntity)
        .toList();
    state = state.copyWith(entities: remaining, preWarpEntities: null);
  }

  void setPerspectiveScaleX(double value) {
    state = state.copyWith(perspectiveScaleX: value);
  }

  void setPerspectiveScaleY(double value) {
    state = state.copyWith(perspectiveScaleY: value);
  }

  void reapplyPerspectiveIfWarped() {
    if (state.originalImage == null) return; // Not warped yet
    applyPerspectiveCorrection();
  }

  Future<void> applyPerspectiveCorrection() async {
    final bool isAlreadyWarped = state.originalImage != null;
    final entitiesSource = isAlreadyWarped
        ? state.preWarpEntities
        : state.entities;
    final perspective = entitiesSource
        ?.whereType<PerspectiveEntity>()
        .firstOrNull;
    if (perspective == null || perspective.points.length != 4) return;

    final imgInfo = isAlreadyWarped ? state.originalImage : state.loadedImage;
    if (imgInfo == null) return;

    state = state.copyWith(status: LoadingStatus.loading);

    try {
      final newImgInfo = await compute(_warpImageIsolate, {
        'bytes': imgInfo.bytes,
        'points': perspective.points,
        'width': imgInfo.width,
        'height': imgInfo.height,
        'scaleX': state.perspectiveScaleX,
        'scaleY': state.perspectiveScaleY,
      });

      if (newImgInfo != null) {
        state = state.copyWith(
          originalImage: state.originalImage ?? state.loadedImage,
          preWarpEntities: isAlreadyWarped
              ? state.preWarpEntities
              : state.entities,
          loadedImage: LoadedImageInfo(
            fileName: imgInfo.fileName,
            fileSizeBytes: (newImgInfo['bytes'] as Uint8List).lengthInBytes,
            bytes: newImgInfo['bytes'] as Uint8List,
            width: newImgInfo['width'] as int,
            height: newImgInfo['height'] as int,
          ),
          entities: isAlreadyWarped ? state.entities : [],
          selectedEntityId: isAlreadyWarped ? state.selectedEntityId : null,
          activeDragDetail: isAlreadyWarped ? state.activeDragDetail : null,
          status: LoadingStatus.success,
        );
      } else {
        state = state.copyWith(
          status: LoadingStatus.error,
          statusMessage: WorkspaceError.unknown,
        );
      }
    } catch (e) {
      debugPrint('Error applying perspective: $e');
      state = state.copyWith(
        status: LoadingStatus.error,
        statusMessage: WorkspaceError.unknown,
      );
    }
  }

  Future<void> autoDetectPerspective() async {
    final imgInfo = state.loadedImage;
    if (imgInfo == null) return;

    state = state.copyWith(status: LoadingStatus.loading);

    try {
      final detectedPoints = await compute(_autoDetectIsolate, {
        'bytes': imgInfo.bytes,
        'width': imgInfo.width,
        'height': imgInfo.height,
      });

      if (detectedPoints != null) {
        // We found 4 points. Remove old perspective entity.
        final oldEntities = state.entities
            .where((e) => e is! PerspectiveEntity)
            .toList();
        final newEntity = DrawingEntity.perspective(
          id: 'perspective_${DateTime.now().millisecondsSinceEpoch}',
          points: detectedPoints,
          color: Colors.orange,
        ) as PerspectiveEntity;

        state = state.copyWith(
          entities: [...oldEntities, newEntity],
          status: LoadingStatus.success,
        );
      } else {
        state = state.copyWith(status: LoadingStatus.success);
      }
    } catch (e) {
      debugPrint('Error auto detecting perspective: $e');
      state = state.copyWith(
        status: LoadingStatus.error,
        statusMessage: WorkspaceError.unknown,
      );
    }
  }

  // --- WERKZEUG-ROUTING (NEU) ---

  void cancelCurrentTool() {
    final newEntities = state.entities
        .where((e) {
          return e.map(
            calibration: (c) => c.isConfirmed || c.enteredDistance != null,
            line: (l) => l.p1 != null && l.p2 != null,
            rectangle: (r) => r.p1 != null && r.p2 != null,
            polygon: (p) => p.isClosed,
            angle: (a) => a.p1 != null && a.p2 != null,
            perspective: (p) => p.points.length == 4,
          );
        })
        .map((e) {
          return e.map(
            calibration: (c) => (!c.isConfirmed && c.enteredDistance != null)
                ? c.copyWith(isConfirmed: true)
                : c,
            line: (l) => l,
            rectangle: (r) => r,
            polygon: (p) => p,
            angle: (a) => a,
            perspective: (p) => p,
          );
        })
        .toList();

    state = state.copyWith(entities: newEntities, selectedEntityId: null);
  }

  void handleTapUp(TapUpDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final tool = ref.read(activeToolProvider);
    state = tool.onTapUp(state, details, size);
  }

  void handlePanStart(DragStartDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    state = tool.onPanStart(state, details, size);
  }

  void handlePanUpdate(DragUpdateDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    if (state.activeDragDetail is DragDetailCalibrationPoint &&
        tool is! CalibrationTool) {
      state = const CalibrationTool().onPanUpdate(state, details, size);
      return;
    }
    state = tool.onPanUpdate(state, details, size);
  }

  void handlePanEnd(DragEndDetails details, Size size) {
    final tool = ref.read(activeToolProvider);
    if (state.activeDragDetail is DragDetailCalibrationPoint &&
        tool is! CalibrationTool) {
      state = const CalibrationTool().onPanEnd(state, details, size);
      return;
    }
    state = tool.onPanEnd(state, details, size);
  }

  /// Startet das Ziehen eines Kalibrierungs-Punktes (p1 oder p2).
  void startDraggingCalibrationPoint(bool isP1) {
    state = state.copyWith(
      activeDragDetail: DragDetail.calibrationPoint(isP1: isP1),
    );
  }

  /// Startet das Ziehen eines Entity-Punktes (z. B. Perspective- oder Kalibrierungs-Ecke).
  void startDraggingEntityPoint(String entityId, int pointIndex) {
    state = state.copyWith(
      activeDragDetail: DragDetail.entityPoint(
        entityId: entityId,
        pointIndex: pointIndex,
      ),
    );
  }
}

Future<Map<String, dynamic>?> _warpImageIsolate(
  Map<String, dynamic> args,
) async {
  final bytes = args['bytes'] as Uint8List;
  final points = args['points'] as List<Offset>;
  final width = args['width'] as int;
  final height = args['height'] as int;

  var pixelPoints = points
      .map((p) => cv.Point2f(p.dx * width, p.dy * height))
      .toList();

  // Sort points clockwise (Top-Left, Top-Right, Bottom-Right, Bottom-Left)
  double cx = 0;
  double cy = 0;
  for (final p in pixelPoints) {
    cx += p.x;
    cy += p.y;
  }
  cx /= pixelPoints.length;
  cy /= pixelPoints.length;

  pixelPoints.sort((a, b) {
    final angleA = math.atan2(a.y - cy, a.x - cx);
    final angleB = math.atan2(b.y - cy, b.x - cx);
    return angleA.compareTo(angleB);
  });

  final sourcePoints = cv.VecPoint2f.fromList(pixelPoints);

  double calculateSquaredDistance(cv.Point2f p1, cv.Point2f p2) {
    return (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y);
  }

  final topWidthSquared = calculateSquaredDistance(
    pixelPoints[0],
    pixelPoints[1],
  );
  final bottomWidthSquared = calculateSquaredDistance(
    pixelPoints[2],
    pixelPoints[3],
  );
  final maxWidthSquared = (topWidthSquared > bottomWidthSquared
      ? topWidthSquared
      : bottomWidthSquared);

  final leftHeightSquared = calculateSquaredDistance(
    pixelPoints[0],
    pixelPoints[3],
  );
  final rightHeightSquared = calculateSquaredDistance(
    pixelPoints[1],
    pixelPoints[2],
  );
  final maxHeightSquared = (leftHeightSquared > rightHeightSquared
      ? leftHeightSquared
      : rightHeightSquared);

  final double refWidth = math.sqrt(maxWidthSquared);
  final double refHeight = math.sqrt(maxHeightSquared);

  final destinationPoints = cv.VecPoint2f.fromList([
    cv.Point2f(0.0, 0.0),
    cv.Point2f(refWidth, 0.0),
    cv.Point2f(refWidth, refHeight),
    cv.Point2f(0.0, refHeight),
  ]);

  final srcMat = cv.imdecode(bytes, cv.IMREAD_COLOR);
  if (srcMat.isEmpty) return null;

  final perspectiveMatrix = cv.getPerspectiveTransform2f(
    sourcePoints,
    destinationPoints,
  );

  double mat00 = perspectiveMatrix.at<double>(0, 0);
  double mat01 = perspectiveMatrix.at<double>(0, 1);
  double mat02 = perspectiveMatrix.at<double>(0, 2);
  double mat10 = perspectiveMatrix.at<double>(1, 0);
  double mat11 = perspectiveMatrix.at<double>(1, 1);
  double mat12 = perspectiveMatrix.at<double>(1, 2);
  double mat20 = perspectiveMatrix.at<double>(2, 0);
  double mat21 = perspectiveMatrix.at<double>(2, 1);
  double mat22 = perspectiveMatrix.at<double>(2, 2);

  cv.Point2f transformPoint(double x, double y) {
    double z = mat20 * x + mat21 * y + mat22;
    if (z.abs() < 1e-6) z = 1e-6;
    return cv.Point2f(
      (mat00 * x + mat01 * y + mat02) / z,
      (mat10 * x + mat11 * y + mat12) / z,
    );
  }

  final cornerTopLeft = transformPoint(0, 0);
  final cornerTopRight = transformPoint(width.toDouble(), 0);
  final cornerBottomRight = transformPoint(width.toDouble(), height.toDouble());
  final cornerBottomLeft = transformPoint(0, height.toDouble());

  double minX = math.min(
    cornerTopLeft.x,
    math.min(
      cornerTopRight.x,
      math.min(cornerBottomRight.x, cornerBottomLeft.x),
    ),
  );
  double minY = math.min(
    cornerTopLeft.y,
    math.min(
      cornerTopRight.y,
      math.min(cornerBottomRight.y, cornerBottomLeft.y),
    ),
  );
  double maxX = math.max(
    cornerTopLeft.x,
    math.max(
      cornerTopRight.x,
      math.max(cornerBottomRight.x, cornerBottomLeft.x),
    ),
  );
  double maxY = math.max(
    cornerTopLeft.y,
    math.max(
      cornerTopRight.y,
      math.max(cornerBottomRight.y, cornerBottomLeft.y),
    ),
  );

  double dstWidth = maxX - minX;
  double dstHeight = maxY - minY;

  double scale = 1.0;
  const double maxSize = 8000.0;
  if (dstWidth > maxSize || dstHeight > maxSize) {
    scale = math.min(maxSize / dstWidth, maxSize / dstHeight);
    dstWidth *= scale;
    dstHeight *= scale;
  }

  final combinedMatrix = cv.Mat.zeros(3, 3, cv.MatType.CV_64FC1);
  combinedMatrix.set<double>(0, 0, (mat00 - minX * mat20) * scale);
  combinedMatrix.set<double>(0, 1, (mat01 - minX * mat21) * scale);
  combinedMatrix.set<double>(0, 2, (mat02 - minX * mat22) * scale);
  combinedMatrix.set<double>(1, 0, (mat10 - minY * mat20) * scale);
  combinedMatrix.set<double>(1, 1, (mat11 - minY * mat21) * scale);
  combinedMatrix.set<double>(1, 2, (mat12 - minY * mat22) * scale);
  combinedMatrix.set<double>(2, 0, mat20);
  combinedMatrix.set<double>(2, 1, mat21);
  combinedMatrix.set<double>(2, 2, mat22);

  final scaleX = args['scaleX'] as double? ?? 1.0;
  final scaleY = args['scaleY'] as double? ?? 1.0;

  var dstMat = cv.warpPerspective(srcMat, combinedMatrix, (
    dstWidth.round(),
    dstHeight.round(),
  ));

  if (scaleX != 1.0 || scaleY != 1.0) {
    int newW = (dstWidth * scaleX).round();
    int newH = (dstHeight * scaleY).round();
    if (newW > 0 && newH > 0) {
      final resizedMat = cv.resize(dstMat, (newW, newH));
      dstMat.dispose();
      dstMat = resizedMat;
      dstWidth = newW.toDouble();
      dstHeight = newH.toDouble();
    }
  }

  final encoded = cv.imencode('.png', dstMat);

  srcMat.dispose();
  dstMat.dispose();
  perspectiveMatrix.dispose();
  combinedMatrix.dispose();
  sourcePoints.dispose();
  destinationPoints.dispose();

  return {
    'bytes': encoded.$2,
    'width': dstWidth.round(),
    'height': dstHeight.round(),
  };
}

Future<List<Offset>?> _autoDetectIsolate(Map<String, dynamic> args) async {
  final bytes = args['bytes'] as Uint8List;
  final width = args['width'] as int;
  final height = args['height'] as int;

  final srcMat = cv.imdecode(bytes, cv.IMREAD_COLOR);
  if (srcMat.isEmpty) return null;

  // Für zuverlässigere Kanten immer auf eine fixe Maximalgröße skalieren
  const double maxDim = 1000.0;
  double scale = 1.0;
  if (width > maxDim || height > maxDim) {
    scale = maxDim / math.max(width, height);
  }

  cv.Mat processMat = srcMat;
  if (scale < 1.0) {
    processMat = cv.resize(srcMat, (
      (width * scale).round(),
      (height * scale).round(),
    ));
  }

  final gray = cv.cvtColor(processMat, cv.COLOR_BGR2GRAY);
  final blurred = cv.gaussianBlur(gray, (5, 5), 0, sigmaY: 0);
  final edges = cv.canny(blurred, 50, 150);

  // Lücken in den Kanten schließen
  final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final closedEdges = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);

  final contoursResult = cv.findContours(
    closedEdges,
    cv.RETR_LIST, // Ändern auf RETR_LIST
    cv.CHAIN_APPROX_SIMPLE,
  );
  final contours = contoursResult.$1;

  double maxArea = 0;
  List<cv.Point>? bestPoints;

  for (var i = 0; i < contours.length; i++) {
    final c = contours[i];
    final area = cv.contourArea(c);

    // Wir suchen nach der größten geschlossenen 4-Punkt Form
    if (area > maxArea && area > (processMat.cols * processMat.rows * 0.01)) {
      final perimeter = cv.arcLength(c, true);

      // Probier verschiedene Epsilon-Werte
      for (double epsFactor in [0.02, 0.04, 0.06, 0.01]) {
        final epsilon = epsFactor * perimeter;
        final approx = cv.approxPolyDP(c, epsilon, true);

        if (approx.length == 4 && cv.isContourConvex(approx)) {
          maxArea = area;
          bestPoints = [approx[0], approx[1], approx[2], approx[3]];
          approx.dispose();
          break; // Konvexes Viereck gefunden für diese Kontur
        }
        approx.dispose();
      }
    }
  }

  List<Offset>? result;
  if (bestPoints != null && bestPoints.length == 4) {
    // Punkte als prozentuale Koordinaten (0.0 bis 1.0) zurückgeben
    result = bestPoints
        .map((p) => Offset(p.x / processMat.cols, p.y / processMat.rows))
        .toList();
  }

  if (scale < 1.0) {
    processMat.dispose();
  }
  srcMat.dispose();
  gray.dispose();
  blurred.dispose();
  edges.dispose();
  closedEdges.dispose();
  kernel.dispose();
  contours.dispose();
  contoursResult.$2.dispose();

  return result;
}
