import '../painters/drawing_entity_painter.dart';
import '../utils/geometry_utils.dart';
import '../utils/measurement_calculator.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../tools/select_tool.dart';
import '../models/entities/drawing_entity.dart';
import '../models/mobile_calibration_state.dart';
import '../models/mobile_perspective_state.dart';
import '../models/workflow_step.dart';
import '../models/workspace_state.dart';
import '../tools/calibration_tool.dart';
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
                    Focus.maybeOf(context)?.requestFocus();
                    final renderBox = context.findRenderObject() as RenderBox;
                    if (widget.activeStep == WorkflowStepType.calibrate &&
                        ref.read(activeToolProvider) is! CalibrationTool) {
                      ref
                          .read(activeToolProvider.notifier)
                          .setTool(const CalibrationTool());
                    }
                    controller.handleTapUp(details, renderBox.size);

                    if (context.isMobile &&
                        widget.activeStep == WorkflowStepType.calibrate) {
                      final updatedState = ref.read(
                        workspaceControllerProvider,
                      );
                      final calibEntity = updatedState.entities
                          .whereType<CalibrationEntity>()
                          .firstOrNull;
                      if (calibEntity?.p1 != null && calibEntity?.p2 != null) {
                        ref
                            .read(mobileCalibrationStateProvider.notifier)
                            .setTwoPointsInput();
                      } else if (calibEntity?.p1 != null) {
                        ref
                            .read(mobileCalibrationStateProvider.notifier)
                            .setOnePoint();
                      }
                    }

                    if (context.isMobile &&
                        widget.activeStep == WorkflowStepType.perspective) {
                      final perspFlow = ref.read(
                        mobilePerspectiveStateProvider,
                      );
                      // In mobile Step 2, points should only be placed if manual mode was started
                      if (perspFlow.stepState ==
                              MobilePerspectiveStepState.manualInProgress ||
                          perspFlow.stepState ==
                              MobilePerspectiveStepState.ready4Points) {
                        final updatedState = ref.read(
                          workspaceControllerProvider,
                        );
                        final pEntity = updatedState.entities
                            .whereType<PerspectiveEntity>()
                            .firstOrNull;
                        final count = pEntity?.points.length ?? 0;
                        if (count == 4) {
                          ref
                              .read(mobilePerspectiveStateProvider.notifier)
                              .setReady(isAuto: false);
                        } else if (count > 0) {
                          ref
                              .read(mobilePerspectiveStateProvider.notifier)
                              .setManualInProgress();
                        }
                      }
                    }
                  },
                  onPanStart: isSelectTool
                      ? (details) {
                          Focus.maybeOf(context)?.requestFocus();
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
                            localPosition: localPos,
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
                        isMobile: context.isMobile,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (!context.isMobile &&
                (widget.activeStep == WorkflowStepType.calibrate) &&
                calib != null &&
                calib.p1 != null &&
                calib.p2 != null)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final p1Pix = calib.p1!.toPixel(size);
                    final p2Pix = calib.p2!.toPixel(size);
                    final mid = Offset(
                      (p1Pix.dx + p2Pix.dx) / 2,
                      (p1Pix.dy + p2Pix.dy) / 2,
                    );
                    final pos =
                        MeasurementCalculator.getMeasurementLabelPosition(
                          calib,
                          size,
                        ) ??
                        mid;

                    final isOffset = (pos - mid).distance > 1.0;

                    final isGhosted = _isCalibrationCardGhosted(
                      state: state,
                      calib: calib,
                      cardCenter: pos,
                      size: size,
                    );

                    Widget cardWidget = CalibrationInputWidget(
                      key: const ValueKey('calib_input_card'),
                      isDraggable:
                          widget.activeStep == WorkflowStepType.calibrate,
                      onDragUpdate: (details) {
                        controller.moveEntityLabel(
                          calib.id,
                          details.delta,
                          size,
                        );
                      },
                      onDoubleTap: () {
                        controller.resetEntityLabelOffset(calib.id);
                      },
                    );

                    if (isGhosted) {
                      cardWidget = AnimatedOpacity(
                        opacity: MeasurementCalculator.ghostedPillOpacity,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(ignoring: true, child: cardWidget),
                      );
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (isOffset)
                          CustomPaint(
                            painter: MeasurementLeaderLinesPainter(
                              lines: [
                                MeasurementLeaderLine(
                                  start: mid,
                                  end: pos,
                                  color: calib.isConfirmed
                                      ? AppColors.of(context).success
                                      : Theme.of(context).colorScheme.primary,
                                  opacity: isGhosted
                                      ? MeasurementCalculator.ghostedPillOpacity
                                      : 1.0,
                                ),
                              ],
                            ),
                          ),
                        Positioned(
                          left: pos.dx,
                          top: pos.dy,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: cardWidget,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            if (widget.activeStep == WorkflowStepType.measure ||
                widget.activeStep == WorkflowStepType.export)
              Positioned.fill(child: MeasurementLabelsOverlay(size: size)),

            if ((widget.activeStep == WorkflowStepType.calibrate) &&
                calib != null) ...[
              if (calib.p1 != null)
                _buildPointHandle(
                  calib.p1!,
                  size,
                  controller,
                  pointIndex: 0,
                  entityId: calib.id,
                  isCalibration: true,
                ),
              if (calib.p2 != null)
                _buildPointHandle(
                  calib.p2!,
                  size,
                  controller,
                  pointIndex: 1,
                  entityId: calib.id,
                  isCalibration: true,
                ),
            ],

            if ((widget.activeStep == WorkflowStepType.perspective)) ...[
              for (final entity
                  in state.entities.whereType<PerspectiveEntity>())
                for (int i = 0; i < entity.points.length; i++)
                  _buildPointHandle(
                    entity.points[i],
                    size,
                    controller,
                    pointIndex: i,
                    entityId: entity.id,
                  ),
            ],

            if (widget.activeStep == WorkflowStepType.measure &&
                state.selectedEntityId != null) ...[
              for (final sel in [
                state.entities
                    .where((e) => e.id == state.selectedEntityId)
                    .firstOrNull,
              ])
                if (sel != null &&
                    _isEntityCompleted(sel) &&
                    (!context.isMobile || isSelectTool))
                  ..._buildMeasureEntityHandles(sel, size, controller),
            ],

            if (_showMagnifier && _magnifierPosition != null)
              Builder(
                builder: (context) {
                  final verticalOffset = context.isMobile ? 70.0 : 0.0;
                  final magCenter = Offset(
                    _magnifierPosition!.dx,
                    _magnifierPosition!.dy - verticalOffset,
                  );

                  return Positioned(
                    left: magCenter.dx - (magnifierSize.width / 2),
                    top: magCenter.dy - (magnifierSize.height / 2),
                    child: IgnorePointer(
                      child: SizedBox(
                        width: magnifierSize.width,
                        height: magnifierSize.height,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RawMagnifier(
                              focalPointOffset: Offset(0, verticalOffset),
                              decoration: MagnifierDecoration(
                                opacity: 1.0,
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                shape: const CircleBorder(
                                  side: BorderSide(
                                    color: Color(0xFF38BDF8),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              size: magnifierSize,
                              magnificationScale: AppTheme.magnifierScale,
                            ),
                            // Fadenkreuz im Zentrum der Lupe
                            CustomPaint(
                              size: magnifierSize,
                              painter: _CrosshairPainter(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPointHandle(
    Offset normPoint,
    Size size,
    WorkspaceController controller, {
    int? pointIndex,
    String? entityId,
    bool isCalibration = false,
  }) {
    final handleSize = context.isMobile ? 48.0 : 20.0;
    final center = Offset(
      normPoint.dx * size.width,
      normPoint.dy * size.height,
    );

    return Positioned(
      left: center.dx - (handleSize / 2),
      top: center.dy - (handleSize / 2),
      width: handleSize,
      height: handleSize,
      child: Semantics(
        label: isCalibration
            ? 'Referenzpunkt ${(pointIndex ?? 0) + 1}'
            : 'Ecke ${(pointIndex ?? 0) + 1}',
        button: true,
        child: GestureDetector(
          key: ValueKey('point_handle_${entityId}_$pointIndex'),
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
            if (isCalibration) {
              controller.startDraggingCalibrationPoint(pointIndex == 0);
            } else if (pointIndex != null && entityId != null) {
              controller.startDraggingEntityPoint(entityId, pointIndex);
            } else {
              controller.handlePanStart(newDetails, size);
            }
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

            if (isCalibration && context.isMobile) {
              final updatedState = ref.read(workspaceControllerProvider);
              final currentCalib = updatedState.entities
                  .whereType<CalibrationEntity>()
                  .firstOrNull;
              if (currentCalib != null && !currentCalib.isConfirmed) {
                if (currentCalib.p1 != null && currentCalib.p2 != null) {
                  ref
                      .read(mobileCalibrationStateProvider.notifier)
                      .setTwoPointsInput();
                } else if (currentCalib.p1 != null) {
                  ref
                      .read(mobileCalibrationStateProvider.notifier)
                      .setOnePoint();
                }
              }
            }
          },
          child: SizedBox(width: handleSize, height: handleSize),
        ),
      ),
    );
  }

  bool _isEntityCompleted(DrawingEntity entity) {
    return entity.isCompleted;
  }

  List<Widget> _buildMeasureEntityHandles(
    DrawingEntity entity,
    Size size,
    WorkspaceController controller,
  ) {
    final handles = <Widget>[];
    entity.map(
      calibration: (_) {},
      perspective: (_) {},
      line: (l) {
        if (l.p1 != null) {
          handles.add(
            _buildPointHandle(
              l.p1!,
              size,
              controller,
              pointIndex: 0,
              entityId: l.id,
            ),
          );
        }
        if (l.p2 != null) {
          handles.add(
            _buildPointHandle(
              l.p2!,
              size,
              controller,
              pointIndex: 1,
              entityId: l.id,
            ),
          );
        }
      },
      rectangle: (r) {
        if (r.p1 != null && r.p2 != null) {
          final corners = [
            r.p1!,
            Offset(r.p2!.dx, r.p1!.dy),
            r.p2!,
            Offset(r.p1!.dx, r.p2!.dy),
          ];
          for (int i = 0; i < corners.length; i++) {
            handles.add(
              _buildPointHandle(
                corners[i],
                size,
                controller,
                pointIndex: i,
                entityId: r.id,
              ),
            );
          }
        }
      },
      polygon: (p) {
        for (int i = 0; i < p.points.length; i++) {
          handles.add(
            _buildPointHandle(
              p.points[i],
              size,
              controller,
              pointIndex: i,
              entityId: p.id,
            ),
          );
        }
      },
      angle: (a) {
        if (a.p1 != null) {
          handles.add(
            _buildPointHandle(
              a.p1!,
              size,
              controller,
              pointIndex: 0,
              entityId: a.id,
            ),
          );
        }
        if (a.p2 != null) {
          handles.add(
            _buildPointHandle(
              a.p2!,
              size,
              controller,
              pointIndex: 1,
              entityId: a.id,
            ),
          );
        }
      },
    );
    return handles;
  }

  bool _isCalibrationCardGhosted({
    required WorkspaceState state,
    required CalibrationEntity calib,
    required Offset cardCenter,
    required Size size,
  }) {
    final selectedId = state.selectedEntityId;
    if (selectedId == null || selectedId == calib.id) {
      return false;
    }
    final selectedEntity = state.entities
        .where((e) => e.id == selectedId)
        .firstOrNull;
    if (selectedEntity == null) return false;

    final selectedHandles = MeasurementCalculator.getEntityHandlePoints(
      selectedEntity,
      size,
    );
    if (selectedHandles.isEmpty) return false;

    final cardRect = Rect.fromCenter(
      center: cardCenter,
      width: CalibrationInputWidget.cardWidth,
      height: CalibrationInputWidget.cardHeight,
    );
    return MeasurementCalculator.checkPillCollision(
      foreignPillRect: cardRect,
      selectedHandles: selectedHandles,
      selectedPillRects: const [],
      handleRadius: context.isMobile
          ? MeasurementCalculator.mobileHandleProtectionRadius
          : MeasurementCalculator.desktopHandleProtectionRadius,
    );
  }
}

class EntitiesPainter extends CustomPainter {
  final List<DrawingEntity> entities;
  final WorkflowStepType activeStep;
  final Color primaryColor;
  final Color successColor;
  final Color pointColor;
  final String? selectedEntityId;
  final bool isMobile;

  EntitiesPainter({
    required this.entities,
    required this.activeStep,
    required this.primaryColor,
    required this.successColor,
    required this.pointColor,
    this.selectedEntityId,
    this.isMobile = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final context = PaintContext(
      activeStep: activeStep,
      primaryColor: primaryColor,
      successColor: successColor,
      pointColor: pointColor,
      selectedEntityId: selectedEntityId,
      isMobile: isMobile,
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

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintCrosshair = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final paintShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    const crosshairLength = 12.0;
    const gap = 3.0;

    // Horizontale Linie (links & rechts mit kleiner Lücke im Zentrum)
    // Schatten zuerst
    canvas.drawLine(
      Offset(center.dx - crosshairLength, center.dy),
      Offset(center.dx - gap, center.dy),
      paintShadow,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + crosshairLength, center.dy),
      paintShadow,
    );

    // Vertikale Linie (oben & unten)
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairLength),
      Offset(center.dx, center.dy - gap),
      paintShadow,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + crosshairLength),
      paintShadow,
    );

    // Cyan Linien
    canvas.drawLine(
      Offset(center.dx - crosshairLength, center.dy),
      Offset(center.dx - gap, center.dy),
      paintCrosshair,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + crosshairLength, center.dy),
      paintCrosshair,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairLength),
      Offset(center.dx, center.dy - gap),
      paintCrosshair,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + crosshairLength),
      paintCrosshair,
    );

    // Kleiner Mittelpunkt
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1.2, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
