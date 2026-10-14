import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/entities/drawing_entity.dart';
import '../models/loaded_image_info.dart';
import '../models/mobile_calibration_state.dart';
import 'mobile_step_header.dart';

/// Mobiler Header für Schritt 3 („Maßstab kalibrieren“).
///
/// Basiert auf [MobileStepHeader] und bindet die reaktive
/// [MobileCalibrationStatusPill] ein.
/// Texte werden zentral über [AppLocalizations] (Option B) bezogen.
class MobileCalibrationHeader extends ConsumerWidget {
  const MobileCalibrationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calibFlow = ref.watch(mobileCalibrationStateProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);
    final l10n = AppLocalizations.of(context);

    final calibEntity = workspaceState.entities
        .whereType<CalibrationEntity>()
        .firstOrNull;

    final subtitle =
        l10n?.step3HeaderSubtitle ?? 'Schritt 3: Maßstab kalibrieren';
    final semanticsLabel =
        l10n?.step3HeaderSemantics ??
        'Kopfbereich Schritt 3: Maßstab kalibrieren';

    return MobileStepHeader(
      subtitle: subtitle,
      semanticsLabel: semanticsLabel,
      checkDesktopBreakpoint: true,
      statusPill: MobileCalibrationStatusPill(
        flowState: calibFlow.stepState,
        calibEntity: calibEntity,
        loadedImage: workspaceState.loadedImage,
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
        return _buildPhase1Badge(context);
      case MobileCalibrationStepState.onePoint:
        return _buildPhase2Badge(context);
      case MobileCalibrationStepState.twoPointsInput:
        return _buildPhase3Badge(context);
      case MobileCalibrationStepState.confirmed:
        return _buildPhase4Badge(context);
    }
  }

  /// Phase 1 (0 Punkte): Zwei leere Indikatoren (○ ○) und Hilfetext „Tippe auf den 1. Referenzpunkt“.
  Widget _buildPhase1Badge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n?.calibrationPhase1 ?? 'Tippe auf den 1. Referenzpunkt';
    final semantics = l10n?.statusPrefix(text) ?? 'Status: $text';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF1E293B)
          .withValues(alpha: 0.85), // slate-800
      borderColor: const Color(0xFF334155), // slate-700
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              StatusDotIndicator(isActive: false),
              StatusDotIndicator(isActive: false),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCBD5E1), // slate-300
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

  /// Phase 2 (1 Punkt): Indikatoren ● ○ (Punkt 1 leuchtend cyan #38BDF8) und
  /// Hilfetext „Punkt 1 gesetzt – Tippe auf den 2. Punkt“.
  Widget _buildPhase2Badge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text =
        l10n?.calibrationPhase2 ?? 'Punkt 1 gesetzt – Tippe auf den 2. Punkt';
    final semantics = l10n?.statusPrefix(text) ?? 'Status: $text';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF0F172A)
          .withValues(alpha: 0.85), // slate-900
      borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.4), // cyan glow
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              StatusDotIndicator(isActive: true),
              StatusDotIndicator(isActive: false),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
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

  /// Phase 3 (2 Punkte & Eingabe): Indikatoren ● ● (beide cyan) und
  /// Hilfetext „2 Punkte gesetzt – Reale Länge eingeben“.
  Widget _buildPhase3Badge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text =
        l10n?.calibrationPhase3 ?? '2 Punkte gesetzt – Reale Länge eingeben';
    final semantics = l10n?.statusPrefix(text) ?? 'Status: $text';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF0F172A)
          .withValues(alpha: 0.85), // slate-900
      borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.4), // cyan glow
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              StatusDotIndicator(isActive: true),
              StatusDotIndicator(isActive: true),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
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

  /// Phase 4 (Kalibriert): Smaragdgrüner Akzentrahmen (#10B981 / Emerald) mit Häkchen:
  /// „✓ Maßstab kalibriert: 1 m = X px“ (mit dynamischer Berechnung des Pixel-Faktors).
  Widget _buildPhase4Badge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final confirmedText = MobileCalibrationState.formatConfirmedText(
      calib: calibEntity,
      imageInfo: loadedImage,
    );
    final semantics =
        l10n?.statusPrefix(confirmedText) ?? 'Status: $confirmedText';

    return MobileStatusPillContainer(
      semanticsLabel: semantics,
      backgroundColor: const Color(0xFF064E3B)
          .withValues(alpha: 0.85), // emerald-900
      borderColor: const Color(0xFF10B981), // emerald-500
      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
      child: Text(
        confirmedText,
        style: const TextStyle(
          color: Color(0xFF6EE7B7), // emerald-300
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
