// Scratch file to generate MeasurementLabels
import 'package:flutter/material.dart';
import '../models/workspace_state.dart';
import '../models/entities/drawing_entity.dart';
import '../controllers/workspace_controller.dart';
import '../utils/geometry_utils.dart';
import 'measurement_label_widget.dart';

List<Widget> buildMeasurementLabels(
  BuildContext context,
  WorkspaceState state,
  Size size,
  WorkspaceController controller,
) {
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
    if (entity is CalibrationEntity) continue; // Already handled by CalibrationInputWidget
    if (pixelsPerMeter == null) continue; // Cannot measure without calibration

    final isSelected = entity.id == state.selectedEntityId;

    entity.map(
      calibration: (_) {},
      line: (line) {
        if (line.p1 != null && line.p2 != null) {
          final p1Pix = Offset(line.p1!.dx * size.width, line.p1!.dy * size.height);
          final p2Pix = Offset(line.p2!.dx * size.width, line.p2!.dy * size.height);
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
                  onTap: () => controller.selectEntity(entity.id),
                  onDelete: () => controller.removeEntity(entity.id),
                ),
              ),
            ),
          );
        }
      },
      rectangle: (rect) {
        if (rect.p1 != null && rect.p2 != null) {
          final p1Pix = Offset(rect.p1!.dx * size.width, rect.p1!.dy * size.height);
          final p2Pix = Offset(rect.p2!.dx * size.width, rect.p2!.dy * size.height);
          
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
                  onTap: () => controller.selectEntity(entity.id),
                  onDelete: () => controller.removeEntity(entity.id),
                ),
              ),
            ),
          );
          
          // Optionally add side length labels here, but spec says "Fläche in der Mitte, Seitenlängen an den entsprechenden Kanten."
          // Top edge
          widgets.add(
            Positioned(
              left: centerPix.dx,
              top: p1Pix.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.2),
                child: MeasurementLabelWidget(
                  text: '${widthMeters.toStringAsFixed(2)} m',
                  isSelected: false, // Don't highlight side labels
                  onTap: () => controller.selectEntity(entity.id),
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
                  isSelected: false,
                  onTap: () => controller.selectEntity(entity.id),
                ),
              ),
            ),
          );
        }
      },
      polygon: (polygon) {
        if (polygon.points.length >= 3 && polygon.isClosed) {
          final centroidNorm = GeometryUtils.calculatePolygonCentroid(polygon.points);
          final centroidPix = Offset(
            centroidNorm.dx * size.width,
            centroidNorm.dy * size.height,
          );
          
          final areaPix = GeometryUtils.calculatePolygonAreaPixel(polygon.points, size);
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
                  onTap: () => controller.selectEntity(entity.id),
                  onDelete: () => controller.removeEntity(entity.id),
                ),
              ),
            ),
          );
        }
      },
      angle: (angle) {
        if (angle.p1 != null && angle.p2 != null) {
          final p1Pix = Offset(angle.p1!.dx * size.width, angle.p1!.dy * size.height);
          final p2Pix = Offset(angle.p2!.dx * size.width, angle.p2!.dy * size.height);
          
          final angleDeg = GeometryUtils.calculateAngleToHorizontal(p1Pix, p2Pix);
          
          final distance = (p2Pix - p1Pix).distance;
          final dx = p2Pix.dx - p1Pix.dx;
          final dy = p2Pix.dy - p1Pix.dy;
          
          // Place label roughly in the middle of the arc
          final angleRad = atan2(dy, dx);
          final midAngleRad = angleRad / 2;
          final labelRadius = distance * 0.4; // slightly outside the arc (0.3)
          
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
                  onTap: () => controller.selectEntity(entity.id),
                  onDelete: () => controller.removeEntity(entity.id),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  return widgets;
}
