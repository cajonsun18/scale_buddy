import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entities/drawing_entity.dart';
import '../controllers/workspace_controller.dart';
import '../tools/select_tool.dart';
import '../utils/geometry_utils.dart';
import 'measurement_label_widget.dart';

class MeasurementLabelsOverlay extends ConsumerWidget {
  final Size size;

  const MeasurementLabelsOverlay({super.key, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final controller = ref.read(workspaceControllerProvider.notifier);

    void handleTap(String id) {
      Focus.of(context).requestFocus();
      controller.selectEntity(id);
    }

    void handlePanStart(DragStartDetails details, String id) {
      Focus.of(context).requestFocus();
      controller.selectEntity(id);
    }

    void handlePanUpdate(DragUpdateDetails details) {
      final activeTool = ref.read(activeToolProvider);
      if (activeTool is SelectTool) {
        final renderBox = context.findRenderObject() as RenderBox;
        final newDetails = DragUpdateDetails(
          sourceTimeStamp: details.sourceTimeStamp,
          delta: details.delta,
          primaryDelta: details.primaryDelta,
          globalPosition: details.globalPosition,
        );
        controller.handlePanUpdate(newDetails, renderBox.size);
      }
    }

    void handlePanEnd(DragEndDetails details) {
      final activeTool = ref.read(activeToolProvider);
      if (activeTool is SelectTool) {
        final renderBox = context.findRenderObject() as RenderBox;
        controller.handlePanEnd(details, renderBox.size);
      }
    }

    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    final pixelsPerMeter = GeometryUtils.getPixelsPerMeter(
      size,
      calibP1: calib?.p1,
      calibP2: calib?.p2,
      calibDistance: calib?.enteredDistance,
      unit: calib?.selectedUnit ?? 'm',
    );

    final widgets = <Widget>[];

    for (final entity in state.entities) {
      if (entity is CalibrationEntity) continue; // Already handled

      final isSelected = entity.id == state.selectedEntityId;

      entity.map(
        calibration: (_) {},
        line: (line) {
          if (pixelsPerMeter == null) return;
          if (line.p1 != null && line.p2 != null) {
            final p1Pix = Offset(
              line.p1!.dx * size.width,
              line.p1!.dy * size.height,
            );
            final p2Pix = Offset(
              line.p2!.dx * size.width,
              line.p2!.dy * size.height,
            );
            final distPix = (p2Pix - p1Pix).distance;
            final distMeters = distPix / pixelsPerMeter;

            final centerPix = Offset(
              (p1Pix.dx + p2Pix.dx) / 2,
              (p1Pix.dy + p2Pix.dy) / 2,
            );

            widgets.add(
              Positioned(
                left: centerPix.dx,
                top: centerPix.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: MeasurementLabelWidget(
                    text: '${distMeters.toStringAsFixed(2)} m',
                    isSelected: isSelected,
                    onTap: () => handleTap(entity.id),
                    onPanStart: (details) => handlePanStart(details, entity.id),
                    onPanUpdate: handlePanUpdate,
                    onPanEnd: handlePanEnd,
                    onDelete: () => controller.removeEntity(entity.id),
                  ),
                ),
              ),
            );
          }
        },
        rectangle: (rect) {
          if (pixelsPerMeter == null) return;
          if (rect.p1 != null && rect.p2 != null) {
            final p1Pix = Offset(
              rect.p1!.dx * size.width,
              rect.p1!.dy * size.height,
            );
            final p2Pix = Offset(
              rect.p2!.dx * size.width,
              rect.p2!.dy * size.height,
            );

            final widthPix = (p2Pix.dx - p1Pix.dx).abs();
            final heightPix = (p2Pix.dy - p1Pix.dy).abs();

            final widthMeters = widthPix / pixelsPerMeter;
            final heightMeters = heightPix / pixelsPerMeter;
            final area = widthMeters * heightMeters;

            final centerPix = Offset(
              (p1Pix.dx + p2Pix.dx) / 2,
              (p1Pix.dy + p2Pix.dy) / 2,
            );

            widgets.add(
              Positioned(
                left: centerPix.dx,
                top: centerPix.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: MeasurementLabelWidget(
                    text: '${area.toStringAsFixed(2)} m²',
                    isSelected: isSelected,
                    onTap: () => handleTap(entity.id),
                    onPanStart: (details) => handlePanStart(details, entity.id),
                    onPanUpdate: handlePanUpdate,
                    onPanEnd: handlePanEnd,
                    onDelete: () => controller.removeEntity(entity.id),
                  ),
                ),
              ),
            );

            // Top edge
            widgets.add(
              Positioned(
                left: centerPix.dx,
                top: p1Pix.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.2),
                  child: MeasurementLabelWidget(
                    text: '${widthMeters.toStringAsFixed(2)} m',
                    isSelected: isSelected,
                    onTap: () => handleTap(entity.id),
                    onPanStart: (details) => handlePanStart(details, entity.id),
                    onPanUpdate: handlePanUpdate,
                    onPanEnd: handlePanEnd,
                  ),
                ),
              ),
            );
            // Left edge
            widgets.add(
              Positioned(
                left: p1Pix.dx,
                top: centerPix.dy,
                child: FractionalTranslation(
                  translation: const Offset(-1.2, -0.5),
                  child: MeasurementLabelWidget(
                    text: '${heightMeters.toStringAsFixed(2)} m',
                    isSelected: isSelected,
                    onTap: () => handleTap(entity.id),
                    onPanStart: (details) => handlePanStart(details, entity.id),
                    onPanUpdate: handlePanUpdate,
                    onPanEnd: handlePanEnd,
                  ),
                ),
              ),
            );
          }
        },
        polygon: (polygon) {
          if (pixelsPerMeter == null) return;
          if (polygon.points.length >= 3 && polygon.isClosed) {
            final centroidNorm = GeometryUtils.calculatePolygonCentroid(
              polygon.points,
            );
            final centroidPix = Offset(
              centroidNorm.dx * size.width,
              centroidNorm.dy * size.height,
            );

            final areaPix = GeometryUtils.calculatePolygonAreaPixel(
              polygon.points,
              size,
            );
            final areaMeters = areaPix / (pixelsPerMeter * pixelsPerMeter);

            widgets.add(
              Positioned(
                left: centroidPix.dx,
                top: centroidPix.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: MeasurementLabelWidget(
                    text: '${areaMeters.toStringAsFixed(2)} m²',
                    isSelected: isSelected,
                    onTap: () => handleTap(entity.id),
                    onPanStart: (details) => handlePanStart(details, entity.id),
                    onPanUpdate: handlePanUpdate,
                    onPanEnd: handlePanEnd,
                    onDelete: () => controller.removeEntity(entity.id),
                  ),
                ),
              ),
            );
          }
        },
        angle: (angle) {
          if (angle.p1 != null && angle.p2 != null) {
            final p1Pix = Offset(
              angle.p1!.dx * size.width,
              angle.p1!.dy * size.height,
            );
            final p2Pix = Offset(
              angle.p2!.dx * size.width,
              angle.p2!.dy * size.height,
            );

            final angleDeg = GeometryUtils.calculateAngleToHorizontal(
              p1Pix,
              p2Pix,
            );

            final distance = (p2Pix - p1Pix).distance;
            final dx = p2Pix.dx - p1Pix.dx;
            final dy = p2Pix.dy - p1Pix.dy;

            final direction = dx >= 0 ? 1.0 : -1.0;
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

            final midAngleRad = baseAngle + (normalizedSweep / 2);
            final labelRadius = distance * 0.4;

            final labelX = p1Pix.dx + cos(midAngleRad) * labelRadius;
            final labelY = p1Pix.dy + sin(midAngleRad) * labelRadius;

            widgets.add(
              Positioned(
                left: labelX,
                top: labelY,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: MeasurementLabelWidget(
                    text: '${angleDeg.toStringAsFixed(1)}°',
                    isSelected: isSelected,
                    onTap: () => handleTap(entity.id),
                    onPanStart: (details) => handlePanStart(details, entity.id),
                    onPanUpdate: handlePanUpdate,
                    onPanEnd: handlePanEnd,
                    onDelete: () => controller.removeEntity(entity.id),
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    return Stack(clipBehavior: Clip.none, children: widgets);
  }
}
