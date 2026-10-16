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
      Focus.maybeOf(context)?.requestFocus();
      controller.selectEntity(id);
      if (isMobile) {
        ref.read(activeToolProvider.notifier).setTool(const SelectTool());
      }
    }

    void handlePillPanStart(DragStartDetails details, String id) {
      Focus.maybeOf(context)?.requestFocus();
      controller.selectEntity(id);
      if (isMobile) {
        ref.read(activeToolProvider.notifier).setTool(const SelectTool());
      }
    }

    void handlePillPanUpdate(DragUpdateDetails details, String id) {
      controller.moveEntityLabel(id, details.delta, size);
    }

    void handlePillDoubleTap(String id) {
      controller.resetEntityLabelOffset(id);
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
    final leaderLines = <MeasurementLeaderLine>[];
    final lineEntities = state.entities.whereType<LineEntity>().toList();
    final rectEntities = state.entities.whereType<RectangleEntity>().toList();
    final polyEntities = state.entities.whereType<PolygonEntity>().toList();
    final angleEntities = state.entities.whereType<AngleEntity>().toList();

    final selectedEntity = state.selectedEntityId != null
        ? state.entities
              .where((e) => e.id == state.selectedEntityId)
              .firstOrNull
        : null;

    final handleRadius = isMobile
        ? MeasurementCalculator.mobileHandleProtectionRadius
        : MeasurementCalculator.desktopHandleProtectionRadius;
    final selectedHandles = selectedEntity != null
        ? MeasurementCalculator.getEntityHandlePoints(selectedEntity, size)
        : <Offset>[];
    final selectedPillRects = <Rect>[];

    if (selectedEntity != null && selectedEntity is! PerspectiveEntity) {
      final selPos = MeasurementCalculator.getMeasurementLabelPosition(
        selectedEntity,
        size,
      );
      if (selPos != null) {
        String? selText;
        if (selectedEntity is CalibrationEntity) {
          selText = MeasurementCalculator.getMeasurementText(
            selectedEntity,
            size,
            pixelsPerMeter,
            useComma: isMobile,
          );
        } else {
          int? selIdx;
          if (selectedEntity is LineEntity) {
            selIdx = lineEntities.indexOf(selectedEntity) + 1;
          } else if (selectedEntity is RectangleEntity) {
            selIdx = rectEntities.indexOf(selectedEntity) + 1;
          } else if (selectedEntity is PolygonEntity) {
            selIdx = polyEntities.indexOf(selectedEntity) + 1;
          } else if (selectedEntity is AngleEntity) {
            selIdx = angleEntities.indexOf(selectedEntity) + 1;
          }

          selText = MeasurementCalculator.getMeasurementText(
            selectedEntity,
            size,
            pixelsPerMeter,
            index: selIdx,
            useComma: isMobile,
          );
        }

        if (selText != null) {
          final selPillSize = MeasurementCalculator.estimatePillSize(
            selText,
            isSelected: true,
            isMobile: isMobile,
            hasDelete: selectedEntity is! CalibrationEntity,
          );
          selectedPillRects.add(
            Rect.fromCenter(
              center: selPos,
              width: selPillSize.width,
              height: selPillSize.height,
            ),
          );
        }
      }

      if (selectedEntity is RectangleEntity) {
        final selWidthText = isMobile
            ? MeasurementCalculator.getMobileRectangleWidthBadgeText(
                selectedEntity,
                size,
                pixelsPerMeter,
                useComma: true,
              )
            : MeasurementCalculator.getRectangleWidthText(
                selectedEntity,
                size,
                pixelsPerMeter,
              );
        final widthPlacement =
            MeasurementCalculator.getRectangleWidthBadgePlacement(
              selectedEntity,
              size,
            );
        if (selWidthText != null && widthPlacement != null) {
          final widthSize = MeasurementCalculator.estimatePillSize(
            selWidthText,
            isSelected: true,
            isMobile: isMobile,
            hasDelete: false,
          );
          selectedPillRects.add(
            Rect.fromLTWH(
              widthPlacement.position.dx +
                  widthPlacement.widgetTranslation.dx * widthSize.width,
              widthPlacement.position.dy +
                  widthPlacement.widgetTranslation.dy * widthSize.height,
              widthSize.width,
              widthSize.height,
            ),
          );
        }

        if (!isMobile) {
          final selHeightText = MeasurementCalculator.getRectangleHeightText(
            selectedEntity,
            size,
            pixelsPerMeter,
          );
          final heightPlacement =
              MeasurementCalculator.getRectangleHeightBadgePlacement(
                selectedEntity,
                size,
              );
          if (selHeightText != null && heightPlacement != null) {
            final heightSize = MeasurementCalculator.estimatePillSize(
              selHeightText,
              isSelected: true,
              isMobile: isMobile,
              hasDelete: false,
            );
            selectedPillRects.add(
              Rect.fromLTWH(
                heightPlacement.position.dx +
                    heightPlacement.widgetTranslation.dx * heightSize.width,
                heightPlacement.position.dy +
                    heightPlacement.widgetTranslation.dy * heightSize.height,
                heightSize.width,
                heightSize.height,
              ),
            );
          }
        }
      }
    }

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

      final pillSize = MeasurementCalculator.estimatePillSize(
        text ?? '',
        isSelected: isSelected,
        isMobile: isMobile,
        hasDelete: isSelected,
      );
      final pillRect = position != null
          ? Rect.fromCenter(
              center: position,
              width: pillSize.width,
              height: pillSize.height,
            )
          : null;

      final isGhosted =
          !isSelected &&
          selectedEntity != null &&
          pillRect != null &&
          MeasurementCalculator.checkPillCollision(
            foreignPillRect: pillRect,
            selectedHandles: selectedHandles,
            selectedPillRects: selectedPillRects,
            handleRadius: handleRadius,
          );

      if (text != null && position != null) {
        if (entity is LineEntity && entity.p1 != null && entity.p2 != null) {
          final p1Pix = entity.p1!.toPixel(size);
          final p2Pix = entity.p2!.toPixel(size);
          final midpoint = Offset(
            (p1Pix.dx + p2Pix.dx) / 2,
            (p1Pix.dy + p2Pix.dy) / 2,
          );
          if ((position - midpoint).distance > 1.0) {
            leaderLines.add(
              MeasurementLeaderLine(
                start: midpoint,
                end: position,
                color: borderColor ?? MeasureToolColors.distance,
                opacity: isGhosted
                    ? MeasurementCalculator.ghostedPillOpacity
                    : 1.0,
              ),
            );
          }
        } else if (entity is RectangleEntity &&
            entity.p1 != null &&
            entity.p2 != null) {
          final p1Pix = entity.p1!.toPixel(size);
          final p2Pix = entity.p2!.toPixel(size);
          final center = Offset(
            (p1Pix.dx + p2Pix.dx) / 2,
            (p1Pix.dy + p2Pix.dy) / 2,
          );
          if ((position - center).distance > 1.0) {
            leaderLines.add(
              MeasurementLeaderLine(
                start: center,
                end: position,
                color: borderColor ?? MeasureToolColors.rectangle,
                opacity: isGhosted
                    ? MeasurementCalculator.ghostedPillOpacity
                    : 1.0,
              ),
            );
          }
        } else if (entity is PolygonEntity &&
            entity.points.length >= 3 &&
            entity.isClosed) {
          final centroid = GeometryUtils.calculatePolygonCentroid(entity.points)
              .toPixel(size);
          if ((position - centroid).distance > 1.0) {
            leaderLines.add(
              MeasurementLeaderLine(
                start: centroid,
                end: position,
                color: borderColor ?? MeasureToolColors.polygon,
                opacity: isGhosted
                    ? MeasurementCalculator.ghostedPillOpacity
                    : 1.0,
              ),
            );
          }
        } else if (entity is AngleEntity && entity.p1 != null) {
          final apexPix = entity.p1!.toPixel(size);
          if (entity.customLabelOffset != null &&
              (position - apexPix).distance > 1.0) {
            leaderLines.add(
              MeasurementLeaderLine(
                start: apexPix,
                end: position,
                color: borderColor ?? MeasureToolColors.angle,
                opacity: isGhosted
                    ? MeasurementCalculator.ghostedPillOpacity
                    : 1.0,
              ),
            );
          }
        }

        Widget labelWidget = MeasurementLabelWidget(
          text: text,
          isSelected: isSelected,
          isMobile: isMobile,
          borderColor: borderColor,
          textColor: textColor,
          onTap: () => handleTap(entity.id),
          onDoubleTap: () => handlePillDoubleTap(entity.id),
          onPanStart: (details) => handlePillPanStart(details, entity.id),
          onPanUpdate: (details) => handlePillPanUpdate(details, entity.id),
          onDelete: () => controller.removeEntity(entity.id),
        );
        labelWidget = AnimatedOpacity(
          opacity: isGhosted ? MeasurementCalculator.ghostedPillOpacity : 1.0,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(ignoring: isGhosted, child: labelWidget),
        );
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
        final widthPlacement =
            MeasurementCalculator.getRectangleWidthBadgePlacement(entity, size);
        if (widthText != null && widthPlacement != null) {
          final widthSize = MeasurementCalculator.estimatePillSize(
            widthText,
            isSelected: isSelected,
            isMobile: isMobile,
            hasDelete: false,
          );
          final widthRect = Rect.fromLTWH(
            widthPlacement.position.dx +
                widthPlacement.widgetTranslation.dx * widthSize.width,
            widthPlacement.position.dy +
                widthPlacement.widgetTranslation.dy * widthSize.height,
            widthSize.width,
            widthSize.height,
          );
          final isWidthGhosted =
              !isSelected &&
              selectedEntity != null &&
              MeasurementCalculator.checkPillCollision(
                foreignPillRect: widthRect,
                selectedHandles: selectedHandles,
                selectedPillRects: selectedPillRects,
                handleRadius: handleRadius,
              );

          Widget widthWidget = MeasurementLabelWidget(
            text: widthText,
            isSelected: isSelected,
            isMobile: isMobile,
            borderColor: MeasureToolColors.rectangle,
            textColor: isMobile
                ? MeasureToolColors.rectangle
                : const Color(0xFF047857),
            onTap: () => handleTap(entity.id),
          );
          widthWidget = AnimatedOpacity(
            opacity: isWidthGhosted
                ? MeasurementCalculator.ghostedPillOpacity
                : 1.0,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(ignoring: isWidthGhosted, child: widthWidget),
          );
          widgets.add(
            Positioned(
              left: widthPlacement.position.dx,
              top: widthPlacement.position.dy,
              child: FractionalTranslation(
                translation: widthPlacement.widgetTranslation,
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
          final heightPlacement =
              MeasurementCalculator.getRectangleHeightBadgePlacement(
                entity,
                size,
              );
          if (heightText != null && heightPlacement != null) {
            final heightSize = MeasurementCalculator.estimatePillSize(
              heightText,
              isSelected: isSelected,
              isMobile: isMobile,
              hasDelete: false,
            );
            final heightRect = Rect.fromLTWH(
              heightPlacement.position.dx +
                  heightPlacement.widgetTranslation.dx * heightSize.width,
              heightPlacement.position.dy +
                  heightPlacement.widgetTranslation.dy * heightSize.height,
              heightSize.width,
              heightSize.height,
            );
            final isHeightGhosted =
                !isSelected &&
                selectedEntity != null &&
                MeasurementCalculator.checkPillCollision(
                  foreignPillRect: heightRect,
                  selectedHandles: selectedHandles,
                  selectedPillRects: selectedPillRects,
                  handleRadius: handleRadius,
                );

            Widget heightWidget = MeasurementLabelWidget(
              text: heightText,
              isSelected: isSelected,
              borderColor: MeasureToolColors.rectangle,
              textColor: const Color(0xFF047857),
              onTap: () => handleTap(entity.id),
            );
            heightWidget = AnimatedOpacity(
              opacity: isHeightGhosted
                  ? MeasurementCalculator.ghostedPillOpacity
                  : 1.0,
              duration: const Duration(milliseconds: 150),
              child: IgnorePointer(
                ignoring: isHeightGhosted,
                child: heightWidget,
              ),
            );
            widgets.add(
              Positioned(
                left: heightPlacement.position.dx,
                top: heightPlacement.position.dy,
                child: FractionalTranslation(
                  translation: heightPlacement.widgetTranslation,
                  child: heightWidget,
                ),
              ),
            );
          }
        }
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (leaderLines.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                size: size,
                painter: MeasurementLeaderLinesPainter(lines: leaderLines),
              ),
            ),
          ),
        ...widgets,
      ],
    );
  }
}

class MeasurementLeaderLine {
  final Offset start;
  final Offset end;
  final Color color;
  final double opacity;

  const MeasurementLeaderLine({
    required this.start,
    required this.end,
    required this.color,
    this.opacity = 1.0,
  });
}

class MeasurementLeaderLinesPainter extends CustomPainter {
  final List<MeasurementLeaderLine> lines;

  MeasurementLeaderLinesPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      GeometryUtils.drawDashedLeaderLine(
        canvas,
        line.start,
        line.end,
        line.color,
        opacity: line.opacity * 0.75,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MeasurementLeaderLinesPainter oldDelegate) {
    if (oldDelegate.lines.length != lines.length) return true;
    for (int i = 0; i < lines.length; i++) {
      if (oldDelegate.lines[i].start != lines[i].start ||
          oldDelegate.lines[i].end != lines[i].end ||
          oldDelegate.lines[i].color != lines[i].color ||
          oldDelegate.lines[i].opacity != lines[i].opacity) {
        return true;
      }
    }
    return false;
  }
}
