import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../models/mobile_perspective_state.dart';
import '../tools/perspective_tool.dart';
import '../tools/workspace_tool.dart';
import 'mobile_dock_components.dart';

/// Schwebende Steuerungsleiste (Floating Dock) am unteren Rand des mobilen Bildschirms in Schritt 2.
///
/// Unterstützt 4 Workflow-Zustände:
/// 1. Start-Auswahl: [✨ Auto-Entzerrung], [🎯 Manuelle-Entzerrung], [Überspringen]
/// 2. Manuelle Erfassung (< 4 Ecken): [↺ Zurücksetzen], [Entzerren] (deaktiviert), [Überspringen]
/// 3. 4 Ecken bereit: [↺ Zurücksetzen], [✓ Entzerren] (Primär blau), [Überspringen]
/// 4. Nach dem Entzerren: [✏️ Punkte anpassen], [↺ Zurücksetzen], [Weiter ➔] (Primär blau)
class MobilePerspectiveDock extends ConsumerWidget {
  final VoidCallback onSkipOrNext;

  const MobilePerspectiveDock({super.key, required this.onSkipOrNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perspectiveFlow = ref.watch(mobilePerspectiveStateProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspaceController = ref.read(workspaceControllerProvider.notifier);

    final perspectiveEntity = workspaceState.entities
        .whereType<PerspectiveEntity>()
        .firstOrNull;
    final int pointsCount = perspectiveEntity?.points.length ?? 0;
    final bool isWarped = workspaceState.originalImage != null;

    final effectiveState = perspectiveFlow.calculateEffectiveState(
      pointsCount: pointsCount,
      isWarped: isWarped,
    );

    return MobileDockContainer(
      wrapSafeAreaAndMargin: true,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: _buildButtons(
        context,
        ref,
        effectiveState,
        workspaceController,
        isWarped: isWarped,
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    WidgetRef ref,
    MobilePerspectiveStepState state,
    WorkspaceController workspaceController, {
    required bool isWarped,
  }) {
    switch (state) {
      case MobilePerspectiveStepState.initial:
        return _buildState1Initial(context, ref, workspaceController);
      case MobilePerspectiveStepState.manualInProgress:
        return _buildState2ManualInProgress(context, ref, workspaceController);
      case MobilePerspectiveStepState.ready4Points:
        return _buildState3Ready(context, ref, workspaceController);
      case MobilePerspectiveStepState.rectified:
        return _buildState4Rectified(context, ref, workspaceController);
    }
  }

  /// Zustand 1: Start-Auswahl
  Widget _buildState1Initial(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // [✨ Auto-Entzerrung]
        MobileDockButton(
          label: 'Auto-Entzerrung',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFF38BDF8),
          borderColor: const Color(0xFF475569),
          backgroundColor: const Color(0xFF0F172A),
          textColor: Colors.white,
          onPressed: () async {
            ref
                .read(activeToolProvider.notifier)
                .setTool(const PerspectiveTool());
            await workspaceController.autoDetectPerspective();
            final state = ref.read(workspaceControllerProvider);
            final pEntity = state.entities
                .whereType<PerspectiveEntity>()
                .firstOrNull;
            if (pEntity != null && pEntity.points.length == 4) {
              ref
                  .read(mobilePerspectiveStateProvider.notifier)
                  .setReady(isAuto: true);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keine geeignete Form gefunden.'),
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(width: 8),
        // [🎯 Manuelle-Entzerrung]
        MobileDockButton(
          label: 'Manuell',
          icon: Icons.filter_center_focus,
          iconColor: const Color(0xFF60A5FA),
          borderColor: const Color(0xFF2563EB).withValues(alpha: 0.6),
          backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
          textColor: Colors.white,
          onPressed: () {
            ref
                .read(activeToolProvider.notifier)
                .setTool(const PerspectiveTool());
            ref.read(mobilePerspectiveStateProvider.notifier).startManual();
          },
        ),
        const SizedBox(width: 8),
        // [Überspringen]
        MobileDockTextButton(label: 'Überspringen', onPressed: onSkipOrNext),
      ],
    );
  }

  /// Zustand 2: Manuelle Erfassung (< 4 Ecken)
  Widget _buildState2ManualInProgress(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // [↺ Zurücksetzen]
        MobileDockButton(
          label: 'Zurücksetzen',
          icon: Icons.refresh,
          iconColor: const Color(0xFF94A3B8),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF94A3B8),
          onPressed: () => _handleReset(ref, workspaceController),
        ),
        const SizedBox(width: 8),
        // [Entzerren] (deaktiviert)
        const MobileDockButton(
          label: 'Entzerren',
          icon: Icons.check,
          iconColor: Color(0xFF475569),
          borderColor: Color(0xFF334155),
          backgroundColor: Color(0xFF0F172A),
          textColor: Color(0xFF475569),
          onPressed: null, // Deaktiviert
        ),
        const SizedBox(width: 8),
        // [Überspringen]
        MobileDockTextButton(label: 'Überspringen', onPressed: onSkipOrNext),
      ],
    );
  }

  /// Zustand 3: 4 Ecken bereit
  Widget _buildState3Ready(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // [↺ Zurücksetzen]
        MobileDockButton(
          label: 'Zurücksetzen',
          icon: Icons.refresh,
          iconColor: const Color(0xFF94A3B8),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF94A3B8),
          onPressed: () => _handleReset(ref, workspaceController),
        ),
        const SizedBox(width: 8),
        // [✓ Entzerren] (Leuchtend blau primär)
        MobileDockButton.primary(
          label: 'Entzerren',
          icon: Icons.check,
          onPressed: () async {
            await workspaceController.applyPerspectiveCorrection();
            ref.read(mobilePerspectiveStateProvider.notifier).setRectified();
          },
        ),
        const SizedBox(width: 8),
        // [Überspringen]
        MobileDockTextButton(label: 'Überspringen', onPressed: onSkipOrNext),
      ],
    );
  }

  /// Zustand 4: Nach dem Entzerren
  Widget _buildState4Rectified(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // [✏️ Punkte anpassen]
        MobileDockButton(
          label: 'Punkte anpassen',
          icon: Icons.edit,
          iconColor: const Color(0xFF38BDF8),
          borderColor: const Color(0xFF0284C7).withValues(alpha: 0.6),
          backgroundColor: const Color(0xFF0F172A),
          textColor: Colors.white,
          onPressed: () {
            workspaceController.resetPerspective();
            ref
                .read(mobilePerspectiveStateProvider.notifier)
                .setReady(isAuto: false);
            ref
                .read(activeToolProvider.notifier)
                .setTool(const PerspectiveTool());
          },
        ),
        const SizedBox(width: 8),
        // [↺ Zurücksetzen]
        MobileDockButton(
          label: 'Zurücksetzen',
          icon: Icons.refresh,
          iconColor: const Color(0xFF94A3B8),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF94A3B8),
          onPressed: () => _handleReset(ref, workspaceController),
        ),
        const SizedBox(width: 8),
        // [Weiter ➔] (Leuchtend blau primär)
        MobileDockButton.primary(
          label: 'Weiter',
          icon: Icons.arrow_forward,
          onPressed: onSkipOrNext,
        ),
      ],
    );
  }

  /// Behandelt das Zurücksetzen ausnahmslos in Zustand 1 (Start-Auswahl)
  void _handleReset(WidgetRef ref, WorkspaceController workspaceController) {
    workspaceController.clearPerspectiveEntities();
    ref.read(activeToolProvider.notifier).setTool(const EmptyTool());
    ref.read(mobilePerspectiveStateProvider.notifier).setInitial();
  }
}
