import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../tools/select_tool.dart';
import '../utils/geometry_utils.dart';
import '../utils/measurement_calculator.dart';
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
      if (entity is CalibrationEntity || entity is PerspectiveEntity) continue;

      final isSelected = entity.id == state.selectedEntityId;

      final text = MeasurementCalculator.getMeasurementText(
        entity,
        size,
        pixelsPerMeter,
      );
      final position = MeasurementCalculator.getMeasurementLabelPosition(
        entity,
        size,
      );

      if (text != null && position != null) {
        widgets.add(
          Positioned(
            left: position.dx,
            top: position.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: MeasurementLabelWidget(
                text: text,
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

      // Rectangle side lengths (width & height)
      if (entity is RectangleEntity) {
        final widthText = MeasurementCalculator.getRectangleWidthText(
          entity,
          size,
          pixelsPerMeter,
        );
        final widthPos = MeasurementCalculator.getRectangleWidthLabelPosition(
          entity,
          size,
        );
        if (widthText != null && widthPos != null) {
          widgets.add(
            Positioned(
              left: widthPos.dx,
              top: widthPos.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.2),
                child: MeasurementLabelWidget(
                  text: widthText,
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

        final heightText = MeasurementCalculator.getRectangleHeightText(
          entity,
          size,
          pixelsPerMeter,
        );
        final heightPos = MeasurementCalculator.getRectangleHeightLabelPosition(
          entity,
          size,
        );
        if (heightText != null && heightPos != null) {
          widgets.add(
            Positioned(
              left: heightPos.dx,
              top: heightPos.dy,
              child: FractionalTranslation(
                translation: const Offset(-1.2, -0.5),
                child: MeasurementLabelWidget(
                  text: heightText,
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
      }
    }

    return Stack(clipBehavior: Clip.none, children: widgets);
  }
}
