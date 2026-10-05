import '../painters/drawing_entity_painter.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../tools/select_tool.dart';
import '../models/entities/drawing_entity.dart';
import '../models/workflow_step.dart';
import 'calibration_input_widget.dart';
import 'measurement_labels_overlay.dart';

class WorkspaceImageView extends ConsumerStatefulWidget {
  final WorkflowStepType activeStep;

  const WorkspaceImageView({super.key, required this.activeStep});

  @override
  ConsumerState<WorkspaceImageView> createState() => _WorkspaceImageViewState();
}

class _WorkspaceImageViewState extends ConsumerState<WorkspaceImageView> {
  @override
  Widget build(BuildContext context) {
    final transformationController = ref.watch(
      transformationControllerProvider,
    );
    final state = ref.watch(workspaceControllerProvider);
    final info = state.loadedImage;
    if (info == null) return const SizedBox.shrink();

    final isCalibrateStep = widget.activeStep == WorkflowStepType.calibrate;

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerMove: (event) {
              if (event.buttons == kMiddleMouseButton) {
                final matrix = transformationController.value.clone();
                final currentDx = matrix.entry(0, 3);
                final currentDy = matrix.entry(1, 3);
                matrix.setEntry(0, 3, currentDx + event.delta.dx);
                matrix.setEntry(1, 3, currentDy + event.delta.dy);
                transformationController.value = matrix;
              }
            },
            child: InteractiveViewer(
              transformationController: transformationController,
              panEnabled: false,
              scaleEnabled: true,
              minScale: 0.1,
              maxScale: 20.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: AspectRatio(
                  aspectRatio: info.height == 0
                      ? 1.0
                      : info.width / info.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        info.bytes,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      _ImageWithPointsOverlay(activeStep: widget.activeStep),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isCalibrateStep)
          const Positioned(
            bottom: 40,
            right: 40,
            child: IgnorePointer(
              child: SizedBox(
                width: 150,
                height: 150,
                child: ClipOval(child: ColoredBox(color: Colors.transparent)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageWithPointsOverlay extends ConsumerStatefulWidget {
  final WorkflowStepType activeStep;

  const _ImageWithPointsOverlay({required this.activeStep});

  @override
  ConsumerState<_ImageWithPointsOverlay> createState() =>
      _ImageWithPointsOverlayState();
}

class _ImageWithPointsOverlayState
    extends ConsumerState<_ImageWithPointsOverlay> {
  double? _localLabelPosition;
  bool _showMagnifier = false;
  Offset? _magnifierPosition;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final controller = ref.read(workspaceControllerProvider.notifier);
    final activeTool = ref.watch(activeToolProvider);
    final isSelectTool = activeTool is SelectTool;
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;

    const magnifierSize = Size(80.0, 80.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Listener(
                onPointerHover: (event) {},
                child: GestureDetector(
                  onTapUp: (details) {
                    Focus.of(context).requestFocus();
                    final renderBox = context.findRenderObject() as RenderBox;
                    controller.handleTapUp(details, renderBox.size);
                  },
                  onPanStart: isSelectTool
                      ? (details) {
                          Focus.of(context).requestFocus();
                          final renderBox =
                              context.findRenderObject() as RenderBox;
                          final localPos = renderBox.globalToLocal(
                            details.globalPosition,
                          );
                          final newDetails = DragStartDetails(
                            sourceTimeStamp: details.sourceTimeStamp,
                            globalPosition: details.globalPosition,
                            localPosition: localPos,
                          );
                          controller.handlePanStart(newDetails, renderBox.size);

                          final currentState = ref.read(
                            workspaceControllerProvider,
                          );
                          if (currentState.activeDragDetail != null) {
                            setState(() {
                              _showMagnifier = true;
                              _magnifierPosition = localPos;
                            });
                          }
                        }
                      : null,
                  onPanUpdate: isSelectTool
                      ? (details) {
                          final renderBox =
                              context.findRenderObject() as RenderBox;
                          final localPos = renderBox.globalToLocal(
                            details.globalPosition,
                          );
                          final newDetails = DragUpdateDetails(
                            sourceTimeStamp: details.sourceTimeStamp,
                            delta: details.delta,
                            primaryDelta: details.primaryDelta,
                            globalPosition: details.globalPosition,
                          );
                          controller.handlePanUpdate(
                            newDetails,
                            renderBox.size,
                          );

                          final currentState = ref.read(
                            workspaceControllerProvider,
                          );
                          if (currentState.activeDragDetail != null) {
                            setState(() {
                              _magnifierPosition = localPos;
                            });
                          }
                        }
                      : null,
                  onPanEnd: isSelectTool
                      ? (details) {
                          setState(() {
                            _showMagnifier = false;
                            _magnifierPosition = null;
                          });
                          final renderBox =
                              context.findRenderObject() as RenderBox;
                          controller.handlePanEnd(details, renderBox.size);
                        }
                      : null,
                  child: Container(
                    color: Colors.transparent,
                    child: CustomPaint(
                      painter: EntitiesPainter(
                        entities: state.entities,
                        activeStep: widget.activeStep,
                        primaryColor: Theme.of(context).colorScheme.primary,
                        successColor: AppColors.of(context).success,
                        pointColor: Colors.white,
                        selectedEntityId: state.selectedEntityId,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if ((widget.activeStep == WorkflowStepType.calibrate) &&
                calib != null) ...[
              if (calib.p1 != null)
                _buildPointHandle(calib.p1!, size, controller),
              if (calib.p2 != null)
                _buildPointHandle(calib.p2!, size, controller),
            ],

            if ((widget.activeStep == WorkflowStepType.perspective)) ...[
              for (final entity
                  in state.entities.whereType<PerspectiveEntity>())
                for (final point in entity.points)
                  _buildPointHandle(point, size, controller),
            ],

            if (_showMagnifier && _magnifierPosition != null)
              Positioned(
                left: _magnifierPosition!.dx - (magnifierSize.width / 2),
                top: _magnifierPosition!.dy - (magnifierSize.height / 2),
                child: IgnorePointer(
                  child: RawMagnifier(
                    decoration: const MagnifierDecoration(
                      shape: CircleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    size: magnifierSize,
                    magnificationScale: 2.0,
                  ),
                ),
              ),

            if ((widget.activeStep == WorkflowStepType.calibrate) &&
                calib != null &&
                calib.p1 != null &&
                calib.p2 != null)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final currentLabelPos =
                        _localLabelPosition ?? calib.labelPosition;
                    final pos = _calculateLabelOffset(
                      calib.p1!,
                      calib.p2!,
                      currentLabelPos,
                      size,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: pos.dx,
                          top: pos.dy,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: CalibrationInputWidget(
                              key: const ValueKey('calib_input_card'),
                              isDraggable:
                                  (widget.activeStep ==
                                  WorkflowStepType.calibrate),
                              onDragStart: () {
                                setState(() {
                                  _localLabelPosition = calib.labelPosition;
                                });
                              },
                              onDragUpdate: (details) {
                                _handleLabelDragLocal(details, calib, size);
                              },
                              onDragEnd: () {
                                if (_localLabelPosition != null) {
                                  final state = ref.read(
                                    workspaceControllerProvider,
                                  );
                                  final currentCalib = state.entities
                                      .whereType<CalibrationEntity>()
                                      .firstOrNull;
                                  if (currentCalib != null) {
                                    controller.addOrUpdateEntity(
                                      currentCalib.copyWith(
                                        labelPosition: _localLabelPosition!
                                            .clamp(0.15, 0.85),
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _localLabelPosition = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (widget.activeStep == WorkflowStepType.measure)
              Positioned.fill(child: MeasurementLabelsOverlay(size: size)),
          ],
        );
      },
    );
  }

  Widget _buildPointHandle(
    Offset normPoint,
    Size size,
    WorkspaceController controller,
  ) {
    const handleSize = 48.0;
    final center = Offset(
      normPoint.dx * size.width,
      normPoint.dy * size.height,
    );

    return Positioned(
      left: center.dx - (handleSize / 2),
      top: center.dy - (handleSize / 2),
      width: handleSize,
      height: handleSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPos = renderBox.globalToLocal(details.globalPosition);
          setState(() {
            _showMagnifier = true;
            _magnifierPosition = localPos;
          });
          final newDetails = DragStartDetails(
            sourceTimeStamp: details.sourceTimeStamp,
            globalPosition: details.globalPosition,
            localPosition: localPos,
          );
          controller.handlePanStart(newDetails, size);
        },
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPos = renderBox.globalToLocal(details.globalPosition);
          setState(() {
            _magnifierPosition = localPos;
          });
          final newDetails = DragUpdateDetails(
            sourceTimeStamp: details.sourceTimeStamp,
            delta: details.delta,
            primaryDelta: details.primaryDelta,
            globalPosition: details.globalPosition,
            localPosition: localPos,
          );
          controller.handlePanUpdate(newDetails, size);
        },
        onPanEnd: (details) {
          setState(() {
            _showMagnifier = false;
            _magnifierPosition = null;
          });
          controller.handlePanEnd(details, size);
        },
        child: const SizedBox(width: handleSize, height: handleSize),
      ),
    );
  }

  Offset _calculateLabelOffset(Offset p1, Offset p2, double t, Size size) {
    final p1Pix = Offset(p1.dx * size.width, p1.dy * size.height);
    final p2Pix = Offset(p2.dx * size.width, p2.dy * size.height);
    final lineVec = p2Pix - p1Pix;
    final length = lineVec.distance;

    double offsetX = 0;
    double offsetY = 0;

    if (length > 0) {
      double nx = -lineVec.dy / length;
      double ny = lineVec.dx / length;

      final centerPix = Offset(size.width / 2, size.height / 2);
      final midPix = Offset(
        (p1Pix.dx + p2Pix.dx) / 2,
        (p1Pix.dy + p2Pix.dy) / 2,
      );
      final toCenterPix = centerPix - midPix;

      if ((nx * toCenterPix.dx + ny * toCenterPix.dy) < 0) {
        nx = -nx;
        ny = -ny;
      }

      const offsetDistance = 55.0;
      offsetX = nx * offsetDistance;
      offsetY = ny * offsetDistance;
    }

    return Offset(
      p1Pix.dx + lineVec.dx * t + offsetX,
      p1Pix.dy + lineVec.dy * t + offsetY,
    );
  }

  void _handleLabelDragLocal(
    DragUpdateDetails details,
    CalibrationEntity calib,
    Size size,
  ) {
    final p1 = calib.p1!;
    final p2 = calib.p2!;
    final p1Pix = Offset(p1.dx * size.width, p1.dy * size.height);
    final p2Pix = Offset(p2.dx * size.width, p2.dy * size.height);
    final lineVec = p2Pix - p1Pix;
    final length = lineVec.distance;

    if (length == 0) return;

    final dt =
        (details.delta.dx * lineVec.dx + details.delta.dy * lineVec.dy) /
        (length * length);

    setState(() {
      _localLabelPosition = (_localLabelPosition ?? calib.labelPosition) + dt;
    });
  }
}

class EntitiesPainter extends CustomPainter {
  final List<DrawingEntity> entities;
  final WorkflowStepType activeStep;
  final Color primaryColor;
  final Color successColor;
  final Color pointColor;
  final String? selectedEntityId;

  EntitiesPainter({
    required this.entities,
    required this.activeStep,
    required this.primaryColor,
    required this.successColor,
    required this.pointColor,
    this.selectedEntityId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final context = PaintContext(
      activeStep: activeStep,
      primaryColor: primaryColor,
      successColor: successColor,
      pointColor: pointColor,
      selectedEntityId: selectedEntityId,
    );

    for (final entity in entities) {
      EntityPainterDispatcher.paintEntity(canvas, size, entity, context);
    }
  }

  @override
  bool shouldRepaint(covariant EntitiesPainter oldDelegate) {
    return true; // Im echten Einsatz koennten wir auf Listen-Aenderungen optimieren
  }
}
