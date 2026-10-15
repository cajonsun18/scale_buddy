import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../theme/measure_tool_colors.dart';
import '../theme/responsive.dart';
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
    final isMobile = context.isMobile;

    void handleTap(String id) {
      Focus.of(context).requestFocus();
      controller.selectEntity(id);
      if (isMobile) {
        ref.read(activeToolProvider.notifier).setTool(const SelectTool());
      }
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
    final lineEntities = state.entities.whereType<LineEntity>().toList();
    final rectEntities = state.entities.whereType<RectangleEntity>().toList();
    final polyEntities = state.entities.whereType<PolygonEntity>().toList();
    final angleEntities = state.entities.whereType<AngleEntity>().toList();

    for (final entity in state.entities) {
      if (entity is CalibrationEntity || entity is PerspectiveEntity) continue;

      final isSelected = entity.id == state.selectedEntityId;

      // Mobile Zustand 2: Punkt 1 gesetzt -> Tooltips für Startpunkt und Tippe Punkt 2
      if (isMobile) {
        Offset? openP1;
        if (entity is LineEntity && entity.p1 != null && entity.p2 == null) {
          openP1 = entity.p1;
        } else if (entity is RectangleEntity &&
            entity.p1 != null &&
            entity.p2 == null) {
          openP1 = entity.p1;
        } else if (entity is AngleEntity &&
            entity.p1 != null &&
            entity.p2 == null) {
          openP1 = entity.p1;
        } else if (entity is PolygonEntity &&
            !entity.isClosed &&
            entity.points.length == 1) {
          openP1 = entity.points.first;
        }

        if (openP1 != null) {
          final p1Pix = openP1.toPixel(size);
          final ghostPix = Offset(
            (p1Pix.dx + 65.0 > size.width - 35)
                ? p1Pix.dx - 65.0
                : p1Pix.dx + 65.0,
            p1Pix.dy,
          );

          widgets.add(
            Positioned(
              left: p1Pix.dx,
              top: p1Pix.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.8),
                child: Semantics(
                  label: 'Startpunkt',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF38BDF8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      '▪ Startpunkt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          widgets.add(
            Positioned(
              left: ghostPix.dx,
              top: ghostPix.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.8),
                child: Semantics(
                  label: 'Tippe Punkt 2',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF38BDF8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Tippe Punkt 2',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          continue;
        }
      }

      String? text;
      Color? borderColor;
      Color? textColor;
      int? entityIdx;

      if (entity is LineEntity) {
        entityIdx = lineEntities.indexOf(entity) + 1;
        borderColor = MeasureToolColors.distance;
        textColor = isMobile
            ? MeasureToolColors.distance
            : const Color(0xFF0284C7);
      } else if (entity is RectangleEntity) {
        entityIdx = rectEntities.indexOf(entity) + 1;
        borderColor = MeasureToolColors.rectangle;
        textColor = isMobile ? Colors.white : const Color(0xFF047857);
      } else if (entity is PolygonEntity) {
        entityIdx = polyEntities.indexOf(entity) + 1;
        borderColor = MeasureToolColors.polygon;
        textColor = isMobile ? Colors.white : const Color(0xFF7E22CE);
      } else if (entity is AngleEntity) {
        entityIdx = angleEntities.indexOf(entity) + 1;
        borderColor = MeasureToolColors.angle;
        textColor = isMobile ? Colors.white : const Color(0xFFB45309);
      }

      text = MeasurementCalculator.getMeasurementText(
        entity,
        size,
        pixelsPerMeter,
        index: entityIdx,
        useComma: isMobile,
      );

      final position = MeasurementCalculator.getMeasurementLabelPosition(
        entity,
        size,
      );

      final isDimmed =
          isMobile && state.selectedEntityId != null && !isSelected;

      if (text != null && position != null) {
        Widget labelWidget = MeasurementLabelWidget(
          text: text,
          isSelected: isSelected,
          isMobile: isMobile,
          borderColor: borderColor,
          textColor: textColor,
          onTap: () => handleTap(entity.id),
          onPanStart: (details) => handlePanStart(details, entity.id),
          onPanUpdate: handlePanUpdate,
          onPanEnd: handlePanEnd,
          onDelete: () => controller.removeEntity(entity.id),
        );
        if (isDimmed) {
          labelWidget = Opacity(opacity: 0.35, child: labelWidget);
        }
        widgets.add(
          Positioned(
            left: position.dx,
            top: position.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: labelWidget,
            ),
          ),
        );
      }

      // Rectangle side lengths (width & height)
      if (entity is RectangleEntity) {
        final widthText = isMobile
            ? MeasurementCalculator.getMobileRectangleWidthBadgeText(
                entity,
                size,
                pixelsPerMeter,
                useComma: true,
              )
            : MeasurementCalculator.getRectangleWidthText(
                entity,
                size,
                pixelsPerMeter,
              );
        final widthPos = MeasurementCalculator.getRectangleWidthLabelPosition(
          entity,
          size,
        );
        if (widthText != null && widthPos != null) {
          Widget widthWidget = MeasurementLabelWidget(
            text: widthText,
            isSelected: isSelected,
            isMobile: isMobile,
            borderColor: MeasureToolColors.rectangle,
            textColor: isMobile
                ? MeasureToolColors.rectangle
                : const Color(0xFF047857),
            onTap: () => handleTap(entity.id),
            onPanStart: (details) => handlePanStart(details, entity.id),
            onPanUpdate: handlePanUpdate,
            onPanEnd: handlePanEnd,
          );
          if (isDimmed) {
            widthWidget = Opacity(opacity: 0.35, child: widthWidget);
          }
          widgets.add(
            Positioned(
              left: widthPos.dx,
              top: widthPos.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.2),
                child: widthWidget,
              ),
            ),
          );
        }

        if (!isMobile) {
          final heightText = MeasurementCalculator.getRectangleHeightText(
            entity,
            size,
            pixelsPerMeter,
          );
          final heightPos =
              MeasurementCalculator.getRectangleHeightLabelPosition(
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
                    borderColor: MeasureToolColors.rectangle,
                    textColor: const Color(0xFF047857),
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
    }

    return Stack(clipBehavior: Clip.none, children: widgets);
  }
}
