import 'dart:math';

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
              panEnabled: false, // Deaktiviert, da wir manuell mit der mittleren Maustaste verschieben
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
                      _ImageWithPointsOverlay(isCalibrateStep: isCalibrateStep),
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
  final bool isCalibrateStep;

  const _ImageWithPointsOverlay({required this.isCalibrateStep});

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
                        isCalibrateStep: widget.isCalibrateStep,
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

            if (widget.isCalibrateStep && calib != null) ...[
              if (calib.p1 != null)
                _buildPointHandle(calib.p1!, size, controller),
              if (calib.p2 != null)
                _buildPointHandle(calib.p2!, size, controller),
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

            if (widget.isCalibrateStep &&
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
                              isDraggable: widget.isCalibrateStep,
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
            if (!widget.isCalibrateStep)
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
  final bool isCalibrateStep;
  final Color primaryColor;
  final Color successColor;
  final Color pointColor;
  final String? selectedEntityId;

  EntitiesPainter({
    required this.entities,
    required this.isCalibrateStep,
    required this.primaryColor,
    required this.successColor,
    required this.pointColor,
    this.selectedEntityId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entity in entities) {
      entity.map(
        calibration: (e) => _paintCalibration(canvas, size, e),
        line: (e) {
          if (!isCalibrateStep) _paintLine(canvas, size, e);
        },
        polygon: (e) {
          if (!isCalibrateStep) _paintPolygon(canvas, size, e);
        },
        rectangle: (e) {
          if (!isCalibrateStep) _paintRectangle(canvas, size, e);
        },
        angle: (e) {
          if (!isCalibrateStep) _paintAngle(canvas, size, e);
        },
      );
    }
  }

  void _paintAngle(Canvas canvas, Size size, AngleEntity angle) {
    final p1 = angle.p1;
    final p2 = angle.p2;

    if (p1 == null && p2 == null) return;

    final paintLine = Paint()
      ..color = angle.color
      ..strokeWidth = _getStrokeWidth(angle.id)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintHelper = Paint()
      ..color = angle.color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = angle.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;

    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);

      final distance = (p2Pixel - p1Pixel).distance;
      if (distance > 0) {
        final dx = p2Pixel.dx - p1Pixel.dx;
        final dy = p2Pixel.dy - p1Pixel.dy;

        final direction = dx >= 0 ? 1.0 : -1.0;
        final helperEnd = Offset(
          p1Pixel.dx + (distance * direction),
          p1Pixel.dy,
        );

        const dashWidth = 5.0;
        const dashSpace = 5.0;
        double currentX = p1Pixel.dx;
        if (direction > 0) {
          while (currentX < helperEnd.dx) {
            canvas.drawLine(
              Offset(currentX, p1Pixel.dy),
              Offset(min(currentX + dashWidth, helperEnd.dx), p1Pixel.dy),
              paintHelper,
            );
            currentX += dashWidth + dashSpace;
          }
        } else {
          while (currentX > helperEnd.dx) {
            canvas.drawLine(
              Offset(currentX, p1Pixel.dy),
              Offset(max(currentX - dashWidth, helperEnd.dx), p1Pixel.dy),
              paintHelper,
            );
            currentX -= dashWidth + dashSpace;
          }
        }

        final rect = Rect.fromCircle(center: p1Pixel, radius: distance * 0.3);
        final baseAngle = direction > 0 ? 0.0 : pi;

        final angleRad = atan2(dy, dx);
        final sweepAngle = angleRad - baseAngle;

        double normalizedSweep = sweepAngle;
        while (normalizedSweep > pi) {
          normalizedSweep -= 2 * pi;
        }
        while (normalizedSweep < -pi) {
          normalizedSweep += 2 * pi;
        }

        canvas.drawArc(rect, baseAngle, normalizedSweep, false, paintLine);

        // Arrowhead
        final arrowEndX = p1Pixel.dx + cos(angleRad) * (distance * 0.3);
        final arrowEndY = p1Pixel.dy + sin(angleRad) * (distance * 0.3);

        final tangentAngle =
            angleRad + (normalizedSweep > 0 ? pi / 2 : -pi / 2);

        const arrowLength = 10.0;
        const arrowAngle = pi / 6;

        final arrowP1 = Offset(
          arrowEndX + cos(tangentAngle + pi + arrowAngle) * arrowLength,
          arrowEndY + sin(tangentAngle + pi + arrowAngle) * arrowLength,
        );
        final arrowP2 = Offset(
          arrowEndX + cos(tangentAngle + pi - arrowAngle) * arrowLength,
          arrowEndY + sin(tangentAngle + pi - arrowAngle) * arrowLength,
        );

        canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP1, paintLine);
        canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP2, paintLine);
      }
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }

  void _paintRectangle(Canvas canvas, Size size, RectangleEntity rect) {
    final p1 = rect.p1;
    final p2 = rect.p2;

    if (p1 == null && p2 == null) return;

    final paintLine = Paint()
      ..color = rect.color
      ..strokeWidth = _getStrokeWidth(rect.id)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = rect.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = rect.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;

    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      final rectShape = Rect.fromPoints(p1Pixel, p2Pixel);
      canvas.drawRect(rectShape, paintFill);
      canvas.drawRect(rectShape, paintLine);
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }

  void _paintPolygon(Canvas canvas, Size size, PolygonEntity polygon) {
    if (polygon.points.isEmpty) return;

    final paintLine = Paint()
      ..color = polygon.color
      ..strokeWidth = _getStrokeWidth(polygon.id)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = polygon.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final firstPoint = Offset(
      polygon.points.first.dx * size.width,
      polygon.points.first.dy * size.height,
    );
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < polygon.points.length; i++) {
      final p = Offset(
        polygon.points[i].dx * size.width,
        polygon.points[i].dy * size.height,
      );
      path.lineTo(p.dx, p.dy);
    }

    if (polygon.isClosed) {
      path.close();
      canvas.drawPath(path, paintFill);
    }

    canvas.drawPath(path, paintLine);

    // Points
    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = polygon.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final normPoint in polygon.points) {
      final p = Offset(normPoint.dx * size.width, normPoint.dy * size.height);
      canvas.drawCircle(p, 5.0, paintPoint);
      canvas.drawCircle(p, 5.0, paintPointBorder);
    }
  }

  void _paintLine(Canvas canvas, Size size, LineEntity line) {
    final p1 = line.p1;
    final p2 = line.p2;

    if (p1 == null && p2 == null) return;

    final paintLine = Paint()
      ..color = line.color
      ..strokeWidth = _getStrokeWidth(line.id)
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final paintPointBorder = Paint()
      ..color = line.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;

    if (p1 != null) {
      p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    }
    if (p2 != null) {
      p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);
    }

    if (p1Pixel != null && p2Pixel != null) {
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 5.0, paintPoint);
      canvas.drawCircle(p1Pixel, 5.0, paintPointBorder);
    }
    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 5.0, paintPoint);
      canvas.drawCircle(p2Pixel, 5.0, paintPointBorder);
    }
  }

  void _paintCalibration(Canvas canvas, Size size, CalibrationEntity calib) {
    if (!isCalibrateStep) return;

    final p1 = calib.p1;
    final p2 = calib.p2;

    if (p1 == null && p2 == null) return;

    final color = calib.isConfirmed ? successColor : primaryColor;

    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintPoint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintPointBorder = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? p1Pixel, p2Pixel;

    if (p1 != null) p1Pixel = Offset(p1.dx * size.width, p1.dy * size.height);
    if (p2 != null) p2Pixel = Offset(p2.dx * size.width, p2.dy * size.height);

    if (p1Pixel != null && p2Pixel != null) {
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);
    }

    if (p1Pixel != null) {
      canvas.drawCircle(p1Pixel, 6.0, paintPoint);
      canvas.drawCircle(p1Pixel, 6.0, paintPointBorder);
    }

    if (p2Pixel != null) {
      canvas.drawCircle(p2Pixel, 6.0, paintPoint);
      canvas.drawCircle(p2Pixel, 6.0, paintPointBorder);
    }
  }

  @override
  bool shouldRepaint(covariant EntitiesPainter oldDelegate) {
    return true; // Im echten Einsatz könnten wir auf Listen-Änderungen optimieren
  }

  double _getStrokeWidth(String id) {
    return id == selectedEntityId ? 5.0 : 3.0;
  }
}
