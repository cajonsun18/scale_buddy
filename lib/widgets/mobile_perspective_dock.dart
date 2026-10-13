import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../models/mobile_perspective_state.dart';
import '../tools/perspective_tool.dart';
import '../tools/workspace_tool.dart';

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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
            borderRadius: BorderRadius.circular(30.0), // Pillenform
            border: Border.all(
              color: const Color(0xFF334155), // Slate-700
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildButtons(
            context,
            ref,
            effectiveState,
            workspaceController,
            isWarped: isWarped,
          ),
        ),
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
        _buildDockButton(
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
        _buildDockButton(
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
        _buildTextButton(label: 'Überspringen', onPressed: onSkipOrNext),
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
        _buildDockButton(
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
        _buildDockButton(
          label: 'Entzerren',
          icon: Icons.check,
          iconColor: const Color(0xFF475569),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF475569),
          onPressed: null, // Deaktiviert
        ),
        const SizedBox(width: 8),
        // [Überspringen]
        _buildTextButton(label: 'Überspringen', onPressed: onSkipOrNext),
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
        _buildDockButton(
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
        _buildDockButton(
          label: 'Entzerren',
          icon: Icons.check,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF2563EB), // Leuchtend blau
          textColor: Colors.white,
          isPrimary: true,
          onPressed: () async {
            await workspaceController.applyPerspectiveCorrection();
            ref.read(mobilePerspectiveStateProvider.notifier).setRectified();
          },
        ),
        const SizedBox(width: 8),
        // [Überspringen]
        _buildTextButton(label: 'Überspringen', onPressed: onSkipOrNext),
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
        _buildDockButton(
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
        _buildDockButton(
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
        _buildDockButton(
          label: 'Weiter',
          icon: Icons.arrow_forward,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF2563EB),
          textColor: Colors.white,
          isPrimary: true,
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

  /// Touch-freundlicher Dock-Button (Mindestens 44x44 dp)
  Widget _buildDockButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    Color? backgroundColor,
    Color? borderColor,
    bool isPrimary = false,
    VoidCallback? onPressed,
  }) {
    final bool isEnabled = onPressed != null;

    return Expanded(
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22.0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(22.0),
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 1.0)
                    : null,
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16.0, color: iconColor),
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.0,
                        fontWeight: isPrimary
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dezenter Textbutton (z. B. für "Überspringen", Mindestens 44x44 dp)
  Widget _buildTextButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44.0, minWidth: 44.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          minimumSize: const Size(44.0, 44.0),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8), // Slate-400
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
