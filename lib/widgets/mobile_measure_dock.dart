import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/entities/drawing_entity.dart';
import '../theme/measure_tool_colors.dart';
import '../theme/responsive.dart';
import '../tools/angle_tool.dart';
import '../tools/distance_tool.dart';
import '../tools/polygon_tool.dart';
import '../tools/rectangle_tool.dart';
import '../tools/select_tool.dart';
import '../utils/geometry_utils.dart';
import '../utils/measurement_calculator.dart';
import 'mobile_dock_components.dart';

/// Schwebende Steuerungsleiste (Floating Dock) am unteren Rand des mobilen Bildschirms in Schritt 4 („Messwerkzeuge“).
///
/// Zweistufiger Aufbau:
/// - Obere Reihe: 5 Werkzeuge (`Strecke`, `Rechteck`, `Polygon`, `Winkel`, `Edit`) in Kapselform.
/// - Untere Reihe: [ ↺ Rückgängig ] und [ Weiter zu Schritt 5 (Export) → ].
class MobileMeasureDock extends ConsumerStatefulWidget {
  final VoidCallback? onNextStep;

  const MobileMeasureDock({super.key, this.onNextStep});

  @override
  ConsumerState<MobileMeasureDock> createState() => _MobileMeasureDockState();
}

class _MobileMeasureDockState extends ConsumerState<MobileMeasureDock> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentTool = ref.read(activeToolProvider);
      if (currentTool is! DistanceTool &&
          currentTool is! RectangleTool &&
          currentTool is! PolygonTool &&
          currentTool is! AngleTool &&
          currentTool is! SelectTool) {
        ref.read(activeToolProvider.notifier).setTool(const DistanceTool());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= AppBreakpoints.mobileWidth) {
      return const SizedBox.shrink();
    }

    final activeTool = ref.watch(activeToolProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspaceController = ref.read(workspaceControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final openMeasurement = workspaceState.entities
        .where((e) => e.isMeasurement && e.isOpen)
        .lastOrNull;
    final bool isPoint1Set = openMeasurement != null;

    final completedMeasurements = workspaceState.entities
        .where((e) => e.isMeasurement && e.isCompleted)
        .toList();

    final selectedEntity = completedMeasurements
        .where((e) => e.id == workspaceState.selectedEntityId)
        .firstOrNull;

    final calib = workspaceState.entities
        .whereType<CalibrationEntity>()
        .firstOrNull;
    final info = workspaceState.loadedImage;
    double? pixelsPerMeter;
    final imageSize = info != null && info.width > 0 && info.height > 0
        ? Size(info.width.toDouble(), info.height.toDouble())
        : const Size(1000, 1000);

    if (info != null && calib != null && info.width > 0 && info.height > 0) {
      pixelsPerMeter = GeometryUtils.getPixelsPerMeter(
        imageSize,
        calibP1: calib.p1,
        calibP2: calib.p2,
        calibDistance: calib.enteredDistance,
        unit: calib.selectedUnit,
      );
    }

    final bool canUndo = completedMeasurements.isNotEmpty && !isPoint1Set;
    final bool canExport = completedMeasurements.isNotEmpty && !isPoint1Set;

    // Obere Reihe: Werkzeug-Auswahl
    final isDistance =
        activeTool is DistanceTool ||
        (activeTool is! RectangleTool &&
            activeTool is! PolygonTool &&
            activeTool is! AngleTool &&
            activeTool is! SelectTool);
    final isRectangle = activeTool is RectangleTool;
    final isPolygon = activeTool is PolygonTool;
    final isAngle = activeTool is AngleTool;
    final isEdit = activeTool is SelectTool;

    final distanceLabel = l10n?.measureToolDistance ?? 'Strecke';
    final rectLabel = l10n?.measureToolRectangle ?? 'Rechteck';
    final polygonLabel = l10n?.measureToolPolygon ?? 'Polygon';
    final angleLabel = l10n?.measureToolAngle ?? 'Winkel';
    final editLabel = l10n?.measureToolEdit ?? 'Edit';
    final undoLabel = l10n?.measureActionUndo ?? 'Rückgängig';
    final discardPoint1Label =
        l10n?.measureActionDiscardPoint1 ?? 'Punkt 1 verwerfen';
    final exportLabel =
        l10n?.measureActionExport ?? 'Weiter zu Schritt 5 (Export)';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: selectedEntity != null
            ? _buildInspectorDock(
                context: context,
                selectedEntity: selectedEntity,
                allEntities: workspaceState.entities,
                workspaceController: workspaceController,
                l10n: l10n,
                pixelsPerMeter: pixelsPerMeter,
                imageSize: imageSize,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. OBERE REIHE: 5 WERKZEUGE IM FLOATING DOCK
                  MobileDockContainer(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        _buildToolItem(
                          label: distanceLabel,
                          iconBuilder: (color) =>
                              MeasurementDistanceIcon(color: color, size: 18.0),
                          toolColor: MeasureToolColors.distance,
                          isSelected: isDistance,
                          onTap: () {
                            if (isPoint1Set) return;
                            ref
                                .read(activeToolProvider.notifier)
                                .setTool(const DistanceTool());
                          },
                        ),
                        _buildToolItem(
                          label: rectLabel,
                          icon: Icons.crop_square_outlined,
                          toolColor: MeasureToolColors.rectangle,
                          isSelected: isRectangle,
                          onTap: () {
                            if (isPoint1Set) return;
                            ref
                                .read(activeToolProvider.notifier)
                                .setTool(const RectangleTool());
                          },
                        ),
                        _buildToolItem(
                          label: polygonLabel,
                          icon: Icons.hexagon_outlined,
                          toolColor: MeasureToolColors.polygon,
                          isSelected: isPolygon,
                          onTap: () {
                            if (isPoint1Set) return;
                            ref
                                .read(activeToolProvider.notifier)
                                .setTool(const PolygonTool());
                          },
                        ),
                        _buildToolItem(
                          label: angleLabel,
                          icon: Icons.change_history_outlined,
                          toolColor: MeasureToolColors.angle,
                          isSelected: isAngle,
                          onTap: () {
                            if (isPoint1Set) return;
                            ref
                                .read(activeToolProvider.notifier)
                                .setTool(const AngleTool());
                          },
                        ),
                        _buildToolItem(
                          label: editLabel,
                          icon: Icons.near_me_outlined,
                          toolColor: MeasureToolColors.select,
                          isSelected: isEdit,
                          onTap: () {
                            if (isPoint1Set) return;
                            ref
                                .read(activeToolProvider.notifier)
                                .setTool(const SelectTool());
                            if (workspaceState.selectedEntityId == null &&
                                completedMeasurements.isNotEmpty) {
                              workspaceController.selectEntity(
                                completedMeasurements.last.id,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // 2. UNTERE REIHE: AKTIONEN
                  Row(
                    children: [
                      if (isPoint1Set)
                        // [ ✕ Punkt 1 verwerfen ] (Zustand 2)
                        MobileDockButton(
                          flex: 2,
                          label: discardPoint1Label,
                          icon: Icons.close,
                          iconColor: const Color(0xFF94A3B8),
                          textColor: const Color(0xFFCBD5E1),
                          backgroundColor: const Color(0xFF0F172A)
                              .withValues(alpha: 0.6),
                          borderColor: const Color(0xFF334155)
                              .withValues(alpha: 0.6),
                          onPressed: () =>
                              workspaceController.cancelOpenMeasurement(),
                          semanticsLabel: discardPoint1Label,
                        )
                      else
                        // [ ↺ Rückgängig ] (deaktiviert bei 0 Messungen, aktiv bei >= 1 Messung)
                        MobileDockButton(
                          flex: 2,
                          label: undoLabel,
                          icon: Icons.undo,
                          iconColor: canUndo
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          textColor: canUndo
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          backgroundColor: const Color(0xFF0F172A)
                              .withValues(alpha: 0.6),
                          borderColor: const Color(0xFF334155)
                              .withValues(alpha: 0.6),
                          onPressed: canUndo
                              ? () => workspaceController.undoLastMeasurement()
                              : null,
                          semanticsLabel: '$undoLabel (Messung)',
                        ),
                      const SizedBox(width: 8.0),
                      // [ Weiter zu Schritt 5 (Export) → ] (leuchtend smaragdgrün bei >= 1 Messung, sonst inaktiv)
                      MobileDockButton(
                        flex: 3,
                        label: exportLabel,
                        icon: Icons.arrow_forward,
                        isTrailingIcon: true,
                        iconColor: canExport
                            ? Colors.white
                            : const Color(0xFF64748B),
                        textColor: canExport
                            ? Colors.white
                            : const Color(0xFF64748B),
                        backgroundColor: canExport
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0F172A).withValues(alpha: 0.6),
                        borderColor: canExport
                            ? null
                            : const Color(0xFF334155).withValues(alpha: 0.6),
                        isPrimary: canExport,
                        onPressed: canExport
                            ? () => widget.onNextStep?.call()
                            : null,
                        semanticsLabel: exportLabel,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInspectorDock({
    required BuildContext context,
    required DrawingEntity selectedEntity,
    required List<DrawingEntity> allEntities,
    required WorkspaceController workspaceController,
    required AppLocalizations? l10n,
    double? pixelsPerMeter,
    Size imageSize = const Size(1000, 1000),
  }) {
    final title = MeasurementCalculator.getMobileEntityTitle(
      selectedEntity,
      allEntities,
      l10n: l10n,
    );
    final details =
        MeasurementCalculator.getMobileEntityDetails(
          selectedEntity,
          imageSize,
          pixelsPerMeter,
          l10n: l10n,
          useComma: true,
        ) ??
        '';
    final typeBadge = MeasurementCalculator.getMobileEntityTypeName(
      selectedEntity,
      l10n: l10n,
    );
    final identifier = MeasurementCalculator.getMobileEntityIdentifier(
      selectedEntity,
      allEntities,
    );

    final deleteLabel = l10n?.measureActionDelete ?? 'Löschen';
    final doneLabel = l10n?.measureActionDone ?? 'Fertig';

    final Color entityColor;
    final Widget typeIcon;

    if (selectedEntity is LineEntity) {
      entityColor = MeasureToolColors.distance;
      typeIcon = MeasurementDistanceIcon(color: entityColor, size: 20);
    } else if (selectedEntity is RectangleEntity) {
      entityColor = MeasureToolColors.rectangle;
      typeIcon = Icon(Icons.grid_view_rounded, color: entityColor, size: 20);
    } else if (selectedEntity is PolygonEntity) {
      entityColor = MeasureToolColors.polygon;
      typeIcon = Icon(Icons.hexagon_outlined, color: entityColor, size: 20);
    } else if (selectedEntity is AngleEntity) {
      entityColor = MeasureToolColors.angle;
      typeIcon = Icon(
        Icons.change_history_outlined,
        color: entityColor,
        size: 20,
      );
    } else {
      entityColor = const Color(0xFF38BDF8);
      typeIcon = Icon(Icons.straighten, color: entityColor, size: 20);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // OBERE ZEILE: Inspektor-Info
        MobileDockContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: entityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: entityColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Center(child: typeIcon),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      details,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  typeBadge,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // UNTERE ZEILE: [ 🗑 Löschen ] und [ ✓ Fertig ]
        Row(
          children: [
            MobileDockButton(
              flex: 2,
              label: deleteLabel,
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFFCA5A5),
              textColor: const Color(0xFFFCA5A5),
              backgroundColor: const Color(0xFF450A0A).withValues(alpha: 0.6),
              borderColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
              onPressed: () {
                workspaceController.removeEntity(selectedEntity.id);
                workspaceController.clearSelection();
                ref
                    .read(activeToolProvider.notifier)
                    .setTool(const DistanceTool());
              },
              semanticsLabel: '$deleteLabel $identifier',
            ),
            const SizedBox(width: 8.0),
            MobileDockButton(
              flex: 3,
              label: doneLabel,
              icon: Icons.check,
              iconColor: Colors.white,
              textColor: Colors.white,
              backgroundColor: const Color(0xFF2563EB),
              borderColor: null,
              isPrimary: true,
              onPressed: () {
                workspaceController.clearSelection();
                ref
                    .read(activeToolProvider.notifier)
                    .setTool(const DistanceTool());
              },
              semanticsLabel: doneLabel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem({
    required String label,
    IconData? icon,
    Widget Function(Color color)? iconBuilder,
    required Color toolColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = toolColor;
    final inactiveColor = const Color(0xFF94A3B8);
    final color = isSelected ? activeColor : inactiveColor;

    final renderedIcon = iconBuilder != null
        ? iconBuilder(color)
        : (icon != null ? Icon(icon, size: 18.0, color: color) : null);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Werkzeug $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48.0,
                minWidth: 44.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 2.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? toolColor.withValues(alpha: 0.20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12.0),
                border: isSelected
                    ? Border.all(color: toolColor, width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: toolColor.withValues(alpha: 0.25),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (renderedIcon != null) renderedIcon,
                  const SizedBox(height: 3.0),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Benutzerdefiniertes Icon für Streckenmessung (`|---|`), exakt wie im visuellen Design.
class MeasurementDistanceIcon extends StatelessWidget {
  final Color color;
  final double size;

  const MeasurementDistanceIcon({
    super.key,
    required this.color,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DistanceIconPainter(color: color),
    );
  }
}

class _DistanceIconPainter extends CustomPainter {
  final Color color;

  _DistanceIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    // Linker vertikaler Endstrich
    canvas.drawLine(Offset(2, midY - 4.5), Offset(2, midY + 4.5), paint);
    // Horizontale Verbindungslinie
    canvas.drawLine(Offset(2, midY), Offset(size.width - 2, midY), paint);
    // Rechter vertikaler Endstrich
    canvas.drawLine(
      Offset(size.width - 2, midY - 4.5),
      Offset(size.width - 2, midY + 4.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DistanceIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
