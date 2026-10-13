import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../models/mobile_perspective_state.dart';

/// Mobiler Header für Schritt 2 („Perspektive korrigieren“).
///
/// Enthält:
/// - App-Titel: „Scale Buddy“ (Weiß, bold)
/// - Untertitel: „Schritt 2: Perspektive korrigieren“ (Slate-400 `#94A3B8`)
/// - Reaktive Status-Pille, die den aktuellen Zustand visuell und barrierefrei widerspiegelt.
class MobilePerspectiveHeader extends ConsumerWidget {
  const MobilePerspectiveHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perspectiveFlow = ref.watch(mobilePerspectiveStateProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);

    final perspectiveEntity = workspaceState.entities
        .whereType<PerspectiveEntity>()
        .firstOrNull;
    final int pointsCount = perspectiveEntity?.points.length ?? 0;
    final bool isWarped = workspaceState.originalImage != null;

    return Semantics(
      container: true,
      label: 'Kopfbereich Schritt 2: Perspektive korrigieren',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Scale Buddy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Schritt 2: Perspektive korrigieren',
              style: TextStyle(
                color: Color(0xFF94A3B8), // slate-400
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            MobilePerspectiveStatusPill(
              flowState: perspectiveFlow.stepState,
              isAutoDetected: perspectiveFlow.isAutoDetected,
              pointsCount: pointsCount,
              isWarped: isWarped,
            ),
          ],
        ),
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
        return _buildRectifiedBadge();
      case MobilePerspectiveStepState.ready4Points:
        return _buildReadyBadge(isAuto: isAutoDetected);
      case MobilePerspectiveStepState.manualInProgress:
        return _buildManualInProgressBadge(pointsCount: pointsCount);
      case MobilePerspectiveStepState.initial:
        return _buildInitialBadge();
    }
  }

  /// Zustand 1: Vor Auswahl
  Widget _buildInitialBadge() {
    const text = 'Wähle eine Methode zur Entzerrung';
    return Semantics(
      liveRegion: true,
      label: 'Status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.8), // slate-800
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF334155), // slate-700
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          text,
          style: TextStyle(
            color: Color(0xFF94A3B8), // slate-400
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Zustand 2: Manuelle Erfassung (< 4 Ecken)
  Widget _buildManualInProgressBadge({required int pointsCount}) {
    final String helperText = switch (pointsCount) {
      0 => 'Ecke 1 von 4 antippen (oben links)',
      1 => 'Ecke 2 von 4 antippen (oben rechts)',
      2 => 'Ecke 3 von 4 antippen (unten rechts)',
      3 => 'Ecke 4 von 4 antippen (unten links)',
      _ => '4 von 4 Ecken gesetzt',
    };

    return Semantics(
      liveRegion: true,
      label: 'Status: $pointsCount von 4 Ecken gesetzt. $helperText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85), // slate-900
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.4), // cyan glow
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 4 Dots Indikator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                final bool isSet = index < pointsCount;
                return Container(
                  margin: EdgeInsets.only(right: index < 3 ? 4.0 : 8.0),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSet
                        ? const Color(0xFF38BDF8) // cyan/blau leuchtend
                        : const Color(0xFF475569), // abgedunkelt grau slate-600
                    boxShadow: isSet
                        ? [
                            BoxShadow(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
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
      ),
    );
  }

  /// Zustand 3: Bereit (4 Ecken gesetzt)
  Widget _buildReadyBadge({required bool isAuto}) {
    final String labelText = isAuto
        ? '✨ Automatisch erkannt'
        : '✓ 4 von 4 Ecken gesetzt – Bereit';

    return Semantics(
      liveRegion: true,
      label: 'Status: $labelText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B).withValues(alpha: 0.85), // emerald-900
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF34D399), // emerald-400
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          labelText,
          style: const TextStyle(
            color: Color(0xFF6EE7B7), // emerald-300
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Zustand 4: Nach Entzerrung
  Widget _buildRectifiedBadge() {
    const text = '✓ Perspektive entzerrt';
    return Semantics(
      liveRegion: true,
      label: 'Status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.85), // blue-900
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF60A5FA), // blue-400
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          text,
          style: TextStyle(
            color: Color(0xFF93C5FD), // blue-300
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
