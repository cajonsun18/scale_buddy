import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/entities/drawing_entity.dart';
import '../models/loaded_image_info.dart';
import '../tools/workspace_tool.dart';
import '../utils/geometry_utils.dart';
import '../utils/measurement_calculator.dart';
import 'mobile_step_header.dart';

/// Mobiler Header für Schritt 4 („Messwerkzeuge“).
///
/// Basiert auf [MobileStepHeader] und bindet die reaktive
/// [MobileMeasureStatusPill] ein.
/// Texte werden zentral über [AppLocalizations] bezogen.
class MobileMeasureHeader extends ConsumerWidget {
  const MobileMeasureHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final activeTool = ref.watch(activeToolProvider);
    final l10n = AppLocalizations.of(context);

    final calibEntity = workspaceState.entities
        .whereType<CalibrationEntity>()
        .firstOrNull;

    final subtitle = l10n?.step4HeaderSubtitle ?? 'Schritt 4: Messwerkzeuge';
    final semanticsLabel =
        l10n?.step4HeaderSemantics ?? 'Kopfbereich Schritt 4: Messwerkzeuge';

    return MobileStepHeader(
      subtitle: subtitle,
      semanticsLabel: semanticsLabel,
      checkDesktopBreakpoint: true,
      statusPill: MobileMeasureStatusPill(
        calibEntity: calibEntity,
        loadedImage: workspaceState.loadedImage,
        entities: workspaceState.entities,
        activeTool: activeTool,
        selectedEntityId: workspaceState.selectedEntityId,
      ),
    );
  }
}

/// Die reaktive Status-Pille für Schritt 4:
/// - Zustand 1 (Start / 0 Messungen): „○ Tippe auf das Bild... · 1 m = 99 px“
/// - Zustand 2 (Punkt 1 gesetzt): „● ○ Strecke: Punkt 1 gesetzt – Klicke auf Punkt 2“
/// - Zustand 3 (Messungen abgeschlossen): „● ✓ X Messungen erfasst • Bereit für Export“
/// - Zustand 4 (Element ausgewählt): „● Element ausgewählt: F1 (Rechteck)“
class MobileMeasureStatusPill extends StatelessWidget {
  final CalibrationEntity? calibEntity;
  final LoadedImageInfo? loadedImage;
  final List<DrawingEntity> entities;
  final WorkspaceTool? activeTool;
  final String? selectedEntityId;

  const MobileMeasureStatusPill({
    super.key,
    this.calibEntity,
    this.loadedImage,
    this.entities = const [],
    this.activeTool,
    this.selectedEntityId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 1. Prüfen auf offenen Messpunkt (Zustand 2)
    final openMeasurement = entities
        .where((e) => e.isMeasurement && e.isOpen)
        .lastOrNull;

    // 2. Abgeschlossene Messungen (Zustand 3)
    final completedMeasurements = entities
        .where((e) => e.isMeasurement && e.isCompleted)
        .toList();

    // ZUSTAND 4: Element ausgewählt
    if (selectedEntityId != null) {
      final selectedEntity = completedMeasurements
          .where((e) => e.id == selectedEntityId)
          .firstOrNull;
      if (selectedEntity != null) {
        final id = MeasurementCalculator.getMobileEntityIdentifier(
          selectedEntity,
          entities,
        );
        final type = MeasurementCalculator.getMobileEntityTypeName(
          selectedEntity,
          l10n: l10n,
        );
        final statusText =
            l10n?.measureStatusElementSelected(id, type) ??
            'Element ausgewählt: $id ($type)';
        final semantics = 'Status: $statusText';

        return MobileStatusPillContainer(
          semanticsLabel: semantics,
          backgroundColor: const Color(0xFF064E3B).withValues(alpha: 0.5),
          borderColor: const Color(0xFF10B981), // Smaragdgrün (#10B981)
          shadowColor: const Color(0xFF10B981).withValues(alpha: 0.25),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              Flexible(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
    }

    // ZUSTAND 2: Punkt 1 gesetzt
    if (openMeasurement != null) {
      final toolName = openMeasurement.map(
        calibration: (_) => l10n?.measureTypeCalibration ?? 'Kalibrierung',
        perspective: (_) => l10n?.measureTypePerspective ?? 'Perspektive',
        line: (_) => l10n?.measureToolDistance ?? 'Strecke',
        rectangle: (_) => l10n?.measureToolRectangle ?? 'Rechteck',
        polygon: (_) => l10n?.measureToolPolygon ?? 'Polygon',
        angle: (_) => l10n?.measureToolAngle ?? 'Winkel',
      );

      String statusText;
      if (openMeasurement is PolygonEntity &&
          openMeasurement.points.length >= 2) {
        statusText =
            l10n?.measureStatusPolygonPointsSet(
              openMeasurement.points.length,
            ) ??
            'Polygon: ${openMeasurement.points.length} Punkte gesetzt – Klicke Startpunkt zum Schließen';
      } else {
        statusText =
            l10n?.measureStatusPoint1Set(toolName) ??
            '$toolName: Punkt 1 gesetzt – Klicke auf Punkt 2';
      }
      final semantics = 'Status: $statusText';

      return MobileStatusPillContainer(
        semanticsLabel: semantics,
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderColor: const Color(0xFF38BDF8), // blaue Randung (#38BDF8)
        shadowColor: const Color(0xFF38BDF8).withValues(alpha: 0.25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StatusDotIndicator(isActive: true),
            const StatusDotIndicator(isActive: false),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // ZUSTAND 3: Messungen abgeschlossen / Bereit für Export
    if (completedMeasurements.isNotEmpty) {
      final count = completedMeasurements.length;
      final fullStatusSemantics = count == 1
          ? (l10n?.measureStatusReadySingular ??
                '1 Messung erfasst • Bereit für Export')
          : (l10n?.measureStatusReadyPlural(count) ??
                '$count Messungen erfasst • Bereit für Export');

      return MobileStatusPillContainer(
        semanticsLabel: 'Status: $fullStatusSemantics',
        backgroundColor: const Color(0xFF064E3B).withValues(alpha: 0.5),
        borderColor: const Color(0xFF10B981), // Smaragdgrün (#10B981)
        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
              ),
            ),
            const Icon(Icons.check, size: 13, color: Color(0xFF34D399)),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '$count ${count == 1 ? "Messung" : "Messungen"} erfasst',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' • ',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: 'Bereit für Export',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // ZUSTAND 1: Start / 0 Messungen
    final leadText =
        l10n?.measureStatusStart ??
        'Tippe auf das Bild, um die 1. Messung zu starten';

    String scaleText = '1 m = 99 px';
    if (loadedImage != null &&
        calibEntity != null &&
        calibEntity!.isConfirmed &&
        loadedImage!.width > 0 &&
        loadedImage!.height > 0) {
      final pixelsPerMeter = GeometryUtils.getPixelsPerMeter(
        Size(loadedImage!.width.toDouble(), loadedImage!.height.toDouble()),
        calibP1: calibEntity!.p1,
        calibP2: calibEntity!.p2,
        calibDistance: calibEntity!.enteredDistance,
        unit: calibEntity!.selectedUnit,
      );
      if (pixelsPerMeter != null && pixelsPerMeter > 0) {
        scaleText = '1 m = ${pixelsPerMeter.round()} px';
      }
    }

    final fullStatusSemantics = 'Status: $leadText · Maßstab: $scaleText';

    return MobileStatusPillContainer(
      semanticsLabel: fullStatusSemantics,
      backgroundColor: const Color(0xFF1E293B)
          .withValues(alpha: 0.85), // slate-800
      borderColor: const Color(0xFF334155), // slate-700
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusDotIndicator(isActive: false),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$leadText · ',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1), // slate-300
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: scaleText,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8), // cyan (#38BDF8)
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
