import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../models/loaded_image_info.dart';
import '../models/mobile_calibration_state.dart';
import '../theme/responsive.dart';

/// Mobiler Header für Schritt 3 („Maßstab kalibrieren“).
///
/// Enthält:
/// - App-Titel: „Scale Buddy“ (Weiß, bold)
/// - Untertitel: „Schritt 3: Maßstab kalibrieren“ (Slate-400 `#94A3B8`)
/// - Reaktive Status-Pille, die die 4 Phasen visuell und barrierefrei widerspiegelt.
///
/// Wird nur auf mobilen Bildschirmen (< 800 dp) gerendert.
class MobileCalibrationHeader extends ConsumerWidget {
  const MobileCalibrationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).width >= AppBreakpoints.mobileWidth) {
      return const SizedBox.shrink();
    }

    final calibFlow = ref.watch(mobileCalibrationStateProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);

    final calibEntity = workspaceState.entities
        .whereType<CalibrationEntity>()
        .firstOrNull;

    return Semantics(
      container: true,
      label: 'Kopfbereich Schritt 3: Maßstab kalibrieren',
      child: SafeArea(
        bottom: false,
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
                'Schritt 3: Maßstab kalibrieren',
                style: TextStyle(
                  color: Color(0xFF94A3B8), // slate-400
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              MobileCalibrationStatusPill(
                flowState: calibFlow.stepState,
                calibEntity: calibEntity,
                loadedImage: workspaceState.loadedImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die reaktive Status-Pille für Schritt 3 mit 4 Phasen.
class MobileCalibrationStatusPill extends StatelessWidget {
  final MobileCalibrationStepState flowState;
  final CalibrationEntity? calibEntity;
  final LoadedImageInfo? loadedImage;

  const MobileCalibrationStatusPill({
    super.key,
    required this.flowState,
    this.calibEntity,
    this.loadedImage,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveState = MobileCalibrationState(stepState: flowState)
        .calculateEffectiveState(
          p1: calibEntity?.p1,
          p2: calibEntity?.p2,
          isConfirmed: calibEntity?.isConfirmed ?? false,
        );

    switch (effectiveState) {
      case MobileCalibrationStepState.initial:
        return _buildPhase1Badge();
      case MobileCalibrationStepState.onePoint:
        return _buildPhase2Badge();
      case MobileCalibrationStepState.twoPointsInput:
        return _buildPhase3Badge();
      case MobileCalibrationStepState.confirmed:
        return _buildPhase4Badge();
    }
  }

  /// Phase 1 (0 Punkte): Zwei leere Indikatoren (○ ○) und Hilfetext „Tippe auf den 1. Referenzpunkt“.
  Widget _buildPhase1Badge() {
    const text = 'Tippe auf den 1. Referenzpunkt';
    return Semantics(
      liveRegion: true,
      label: 'Status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.85), // slate-800
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDotIndicator(isCyan: false),
                _buildDotIndicator(isCyan: false),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                text,
                style: TextStyle(
                  color: Color(0xFFCBD5E1), // slate-300
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

  /// Phase 2 (1 Punkt): Indikatoren ● ○ (Punkt 1 leuchtend cyan #38BDF8) und
  /// Hilfetext „Punkt 1 gesetzt – Tippe auf den 2. Punkt“.
  Widget _buildPhase2Badge() {
    const text = 'Punkt 1 gesetzt – Tippe auf den 2. Punkt';
    return Semantics(
      liveRegion: true,
      label: 'Status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDotIndicator(isCyan: true),
                _buildDotIndicator(isCyan: false),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                text,
                style: TextStyle(
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

  /// Phase 3 (2 Punkte & Eingabe): Indikatoren ● ● (beide cyan) und
  /// Hilfetext „2 Punkte gesetzt – Reale Länge eingeben“.
  Widget _buildPhase3Badge() {
    const text = '2 Punkte gesetzt – Reale Länge eingeben';
    return Semantics(
      liveRegion: true,
      label: 'Status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDotIndicator(isCyan: true),
                _buildDotIndicator(isCyan: true),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                text,
                style: TextStyle(
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

  /// Phase 4 (Kalibriert): Smaragdgrüner Akzentrahmen (#10B981 / Emerald) mit Häkchen:
  /// „✓ Maßstab kalibriert: 1 m = X px“ (mit dynamischer Berechnung des Pixel-Faktors).
  Widget _buildPhase4Badge() {
    final confirmedText = MobileCalibrationState.formatConfirmedText(
      calib: calibEntity,
      imageInfo: loadedImage,
    );

    return Semantics(
      liveRegion: true,
      label: 'Status: $confirmedText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B).withValues(alpha: 0.85), // emerald-900
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981), // emerald-500
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
          confirmedText,
          style: const TextStyle(
            color: Color(0xFF6EE7B7), // emerald-300
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDotIndicator({required bool isCyan}) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCyan ? const Color(0xFF38BDF8) : Colors.transparent,
        border: isCyan
            ? null
            : Border.all(color: const Color(0xFF475569), width: 1.5),
        boxShadow: isCyan
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}
