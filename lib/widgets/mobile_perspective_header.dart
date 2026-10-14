import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/entities/drawing_entity.dart';
import '../models/mobile_perspective_state.dart';
import 'mobile_step_header.dart';

/// Mobiler Header für Schritt 2 („Perspektive korrigieren“).
///
/// Basiert auf [MobileStepHeader] und bindet die reaktive
/// [MobilePerspectiveStatusPill] ein.
/// Texte werden zentral über [AppLocalizations] (Option B) bezogen.
class MobilePerspectiveHeader extends ConsumerWidget {
  const MobilePerspectiveHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perspectiveFlow = ref.watch(mobilePerspectiveStateProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);
    final l10n = AppLocalizations.of(context);

    final perspectiveEntity = workspaceState.entities
        .whereType<PerspectiveEntity>()
        .firstOrNull;
    final int pointsCount = perspectiveEntity?.points.length ?? 0;
    final bool isWarped = workspaceState.originalImage != null;

    final subtitle =
        l10n?.step2HeaderSubtitle ?? 'Schritt 2: Perspektive korrigieren';
    final semanticsLabel =
        l10n?.step2HeaderSemantics ??
        'Kopfbereich Schritt 2: Perspektive korrigieren';

    return MobileStepHeader(
      subtitle: subtitle,
      semanticsLabel: semanticsLabel,
      statusPill: MobilePerspectiveStatusPill(
        flowState: perspectiveFlow.stepState,
        isAutoDetected: perspectiveFlow.isAutoDetected,
        pointsCount: pointsCount,
        isWarped: isWarped,
      ),
    );
  }
}

/// Die reaktive Status-Pille für Schritt 2.
class MobilePerspectiveStatusPill extends StatelessWidget {
  final MobilePerspectiveStepState flowState;
  final bool isAutoDetected;
  final int pointsCount;
  final bool isWarped;

  const MobilePerspectiveStatusPill({
    super.key,
    required this.flowState,
    required this.isAutoDetected,
    required this.pointsCount,
    required this.isWarped,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveState = MobilePerspectiveState(
      stepState: flowState,
      isAutoDetected: isAutoDetected,
    ).calculateEffectiveState(pointsCount: pointsCount, isWarped: isWarped);

    switch (effectiveState) {
      case MobilePerspectiveStepState.rectified:
        return _buildRectifiedBadge(context);
      case MobilePerspectiveStepState.ready4Points:
        return _buildReadyBadge(context, isAuto: isAutoDetected);
      case MobilePerspectiveStepState.manualInProgress:
        return _buildManualInProgressBadge(context, pointsCount: pointsCount);
      case MobilePerspectiveStepState.initial:
        return _buildInitialBadge(context);
    }
  }

  /// Zustand 1: Vor Auswahl
  Widget _buildInitialBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text =
        l10n?.perspectiveInitial ?? 'Wähle eine Methode zur Entzerrung';
    final semantics = l10n?.statusPrefix(text) ?? 'Status: $text';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF1E293B)
          .withValues(alpha: 0.8), // slate-800
      borderColor: const Color(0xFF334155), // slate-700
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8), // slate-400
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Zustand 2: Manuelle Erfassung (< 4 Ecken)
  Widget _buildManualInProgressBadge(
    BuildContext context, {
    required int pointsCount,
  }) {
    final l10n = AppLocalizations.of(context);
    final helperText = switch (pointsCount) {
      0 =>
        l10n?.perspectiveCornerTopLeft ?? 'Ecke 1 von 4 antippen (oben links)',
      1 =>
        l10n?.perspectiveCornerTopRight ??
            'Ecke 2 von 4 antippen (oben rechts)',
      2 =>
        l10n?.perspectiveCornerBottomRight ??
            'Ecke 3 von 4 antippen (unten rechts)',
      3 =>
        l10n?.perspectiveCornerBottomLeft ??
            'Ecke 4 von 4 antippen (unten links)',
      _ => l10n?.perspectiveCornersAllSet ?? '4 von 4 Ecken gesetzt',
    };

    final semantics =
        l10n?.perspectiveManualStatusSemantics(pointsCount, helperText) ??
        'Status: $pointsCount von 4 Ecken gesetzt. $helperText';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF0F172A)
          .withValues(alpha: 0.85), // slate-900
      borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.4), // cyan glow
      shadowColor: Colors.black.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              return StatusDotIndicator(
                isActive: index < pointsCount,
                useBorderWhenInactive: false,
                margin: EdgeInsets.only(right: index < 3 ? 4.0 : 8.0),
              );
            }),
          ),
          Flexible(
            child: Text(
              helperText,
              style: const TextStyle(
                color: Color(0xFFF1F5F9), // slate-100
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

  /// Zustand 3: Bereit (4 Ecken gesetzt)
  Widget _buildReadyBadge(BuildContext context, {required bool isAuto}) {
    final l10n = AppLocalizations.of(context);
    final String labelText = isAuto
        ? (l10n?.perspectiveAutoDetected ?? '✨ Automatisch erkannt')
        : (l10n?.perspectiveManualReady ?? '✓ 4 von 4 Ecken gesetzt – Bereit');
    final semantics = l10n?.statusPrefix(labelText) ?? 'Status: $labelText';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF064E3B)
          .withValues(alpha: 0.85), // emerald-900
      borderColor: const Color(0xFF34D399), // emerald-400
      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Text(
        labelText,
        style: const TextStyle(
          color: Color(0xFF6EE7B7), // emerald-300
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Zustand 4: Nach Entzerrung
  Widget _buildRectifiedBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n?.perspectiveRectified ?? '✓ Perspektive entzerrt';
    final semantics = l10n?.statusPrefix(text) ?? 'Status: $text';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF1E3A8A)
          .withValues(alpha: 0.85), // blue-900
      borderColor: const Color(0xFF60A5FA), // blue-400
      shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF93C5FD), // blue-300
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
