import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/workflow_step.dart';
import '../models/workspace_state.dart';
import 'workspace_image_view.dart';
import 'workspace_placeholder.dart';
import 'workspace_toolbar.dart';
import 'mobile_perspective_header.dart';
import 'mobile_perspective_dock.dart';
import 'mobile_calibration_header.dart';
import 'mobile_calibration_dock.dart';
import 'mobile_measure_header.dart';
import 'mobile_measure_dock.dart';

class StepDetailView extends ConsumerStatefulWidget {
  final WorkflowStepType activeStep;
  final StepStatus currentStatus;
  final ToolAction? lastSelectedTool;
  final ValueChanged<StepStatus> onStatusChanged;
  final ValueChanged<WorkflowStepType>? onStepSelected;
  final bool isMobile;

  const StepDetailView({
    super.key,
    required this.activeStep,
    required this.currentStatus,
    this.lastSelectedTool,
    required this.onStatusChanged,
    this.onStepSelected,
    this.isMobile = false,
  });

  @override
  ConsumerState<StepDetailView> createState() => _StepDetailViewState();
}

class _StepDetailViewState extends ConsumerState<StepDetailView> {
  bool _isDragHovering = false;
  bool _isForward = true;

  @override
  void didUpdateWidget(StepDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeStep != widget.activeStep) {
      _isForward = widget.activeStep.index >= oldWidget.activeStep.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepData = WorkflowStepData.allSteps.firstWhere(
      (s) => s.type == widget.activeStep,
    );

    if (widget.isMobile) {
      return _buildMobileWorkspace(context, theme, stepData);
    }

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeaderSwitcher(theme, stepData)),
              const SizedBox(width: 16),
              if (widget.currentStatus == StepStatus.active)
                FilledButton.icon(
                  onPressed: () => widget.onStatusChanged(StepStatus.completed),
                  icon: const Icon(Icons.check),
                  label: const Text('Schritt abschließen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.lastSelectedTool != null)
            _buildToolIndicator(widget.lastSelectedTool!),
          const SizedBox(height: 16),
          Expanded(child: _buildWorkspace(theme, stepData)),
        ],
      ),
    );
  }

  Widget _buildHeaderSwitcher(ThemeData theme, WorkflowStepData stepData) {
    const slideOffset = 160.0;
    final isForward = _isForward;
    final sign = isForward ? 1.0 : -1.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: AlignmentDirectional.topStart,
          clipBehavior: Clip.none,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isIncoming =
            child.key == ValueKey<WorkflowStepType>(widget.activeStep);
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, w) {
              final dx = isIncoming
                  ? sign * slideOffset * (1.0 - animation.value)
                  : -sign * slideOffset * (1.0 - animation.value);
              return Transform.translate(offset: Offset(dx, 0.0), child: w);
            },
            child: child,
          ),
        );
      },
      child: SizedBox(
        key: ValueKey<WorkflowStepType>(stepData.type),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stepData.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stepData.shortDescription,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolIndicator(ToolAction action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade700),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app, color: Colors.lightBlueAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Im Menü links gewählt: "${WorkflowStepData.labelFor(action)}"',
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(ThemeData theme, WorkflowStepData stepData) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final controller = ref.watch(workspaceControllerProvider.notifier);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.of(context).toolbarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragHovering
              ? theme.colorScheme.primary
              : AppColors.of(context).toolbarBorder,
          width: _isDragHovering ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const WorkspaceToolbar(),
            ),
            Positioned.fill(
              top: 56,
              child: _WorkspaceContent(
                activeStep: widget.activeStep,
                stepData: stepData,
              ),
            ),
            if (_isDragHovering)
              Positioned.fill(
                top: 56,
                child: IgnorePointer(
                  child: Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_download, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Bild hier ablegen …',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              top: 56,
              child: _DropZoneLayer(
                onDragEntered: () {
                  if (!_isDragHovering) setState(() => _isDragHovering = true);
                },
                onDragExited: () {
                  if (_isDragHovering) setState(() => _isDragHovering = false);
                },
                onBytesDropped: (bytes) {
                  setState(() => _isDragHovering = false);
                  controller.handleDroppedBytes(bytes);
                },
                onFilePathsDropped: (paths) {
                  setState(() => _isDragHovering = false);
                  controller.handleDroppedFilePaths(paths);
                },
              ),
            ),
            if (workspaceState.statusMessage != WorkspaceError.none)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _StatusMessageOverlay(
                  error: workspaceState.statusMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileWorkspace(
    BuildContext context,
    ThemeData theme,
    WorkflowStepData stepData,
  ) {
    final workspaceState = ref.watch(workspaceControllerProvider);

    return Container(
      color: AppColors.of(context).toolbarBg,
      child: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _WorkspaceContent(
                activeStep: widget.activeStep,
                stepData: stepData,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildMobileHeaderSwitcher(workspaceState),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMobileDockSwitcher(workspaceState),
            ),
            if (workspaceState.statusMessage != WorkspaceError.none)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _StatusMessageOverlay(
                  error: workspaceState.statusMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeaderSwitcher(WorkspaceState workspaceState) {
    Widget? headerWidget;
    if (workspaceState.loadedImage != null) {
      if (widget.activeStep == WorkflowStepType.perspective) {
        headerWidget = const MobilePerspectiveHeader(
          key: ValueKey<WorkflowStepType>(WorkflowStepType.perspective),
        );
      } else if (widget.activeStep == WorkflowStepType.calibrate) {
        headerWidget = const MobileCalibrationHeader(
          key: ValueKey<WorkflowStepType>(WorkflowStepType.calibrate),
        );
      } else if (widget.activeStep == WorkflowStepType.measure) {
        headerWidget = const MobileMeasureHeader(
          key: ValueKey<WorkflowStepType>(WorkflowStepType.measure),
        );
      }
    }

    const slideOffset = 88.0;
    final isForward = _isForward;
    final sign = isForward ? 1.0 : -1.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: <Widget>[
            ...previousChildren.map((w) => IgnorePointer(child: w)),
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isIncoming =
            child.key == ValueKey<WorkflowStepType>(widget.activeStep);
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, w) {
              final dx = isIncoming
                  ? sign * slideOffset * (1.0 - animation.value)
                  : -sign * slideOffset * (1.0 - animation.value);
              return Transform.translate(offset: Offset(dx, 0.0), child: w);
            },
            child: child,
          ),
        );
      },
      child:
          headerWidget ??
          const SizedBox.shrink(key: ValueKey<WorkflowStepType?>(null)),
    );
  }

  Widget _buildMobileDockSwitcher(WorkspaceState workspaceState) {
    Widget? dockWidget;
    if (workspaceState.loadedImage != null) {
      if (widget.activeStep == WorkflowStepType.perspective) {
        dockWidget = MobilePerspectiveDock(
          key: const ValueKey('mobile_dock_perspective'),
          onSkipOrNext: () {
            widget.onStatusChanged(StepStatus.completed);
            widget.onStepSelected?.call(WorkflowStepType.calibrate);
          },
        );
      } else if (widget.activeStep == WorkflowStepType.calibrate) {
        dockWidget = MobileCalibrationDock(
          key: const ValueKey('mobile_dock_calibrate'),
          onNextStep: () {
            widget.onStatusChanged(StepStatus.completed);
            widget.onStepSelected?.call(WorkflowStepType.measure);
          },
        );
      } else if (widget.activeStep == WorkflowStepType.measure) {
        dockWidget = MobileMeasureDock(
          key: const ValueKey('mobile_dock_measure'),
          onNextStep: () {
            widget.onStatusChanged(StepStatus.completed);
            widget.onStepSelected?.call(WorkflowStepType.export);
          },
        );
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: <Widget>[
            ...previousChildren.map((w) => IgnorePointer(child: w)),
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child:
          dockWidget ??
          const SizedBox.shrink(key: ValueKey('mobile_dock_none')),
    );
  }
}

class _WorkspaceContent extends ConsumerWidget {
  final WorkflowStepType activeStep;
  final WorkflowStepData stepData;

  const _WorkspaceContent({required this.activeStep, required this.stepData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);

    if (workspaceState.status == LoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (workspaceState.loadedImage != null) {
      return WorkspaceImageView(activeStep: activeStep);
    }

    return WorkspacePlaceholder(stepData: stepData);
  }
}

class _StatusMessageOverlay extends StatelessWidget {
  final WorkspaceError error;

  const _StatusMessageOverlay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        error == WorkspaceError.selectionCancelled
            ? 'Auswahl abgebrochen'
            : 'Fehler beim Laden',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DropZoneLayer extends StatefulWidget {
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final ValueChanged<List<Uint8List>> onBytesDropped;
  final ValueChanged<List<String>> onFilePathsDropped;

  const _DropZoneLayer({
    required this.onDragEntered,
    required this.onDragExited,
    required this.onBytesDropped,
    required this.onFilePathsDropped,
  });

  @override
  State<_DropZoneLayer> createState() => _DropZoneLayerState();
}

class _DropZoneLayerState extends State<_DropZoneLayer> {
  @override
  Widget build(BuildContext context) {
    return _DesktopDropAdapter(
      onEnter: widget.onDragEntered,
      onExit: widget.onDragExited,
      onBytes: widget.onBytesDropped,
      onPaths: widget.onFilePathsDropped,
      child: const SizedBox.expand(),
    );
  }
}

class _DesktopDropAdapter extends StatelessWidget {
  final Widget child;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final ValueChanged<List<Uint8List>> onBytes;
  final ValueChanged<List<String>> onPaths;

  const _DesktopDropAdapter({
    required this.child,
    required this.onEnter,
    required this.onExit,
    required this.onBytes,
    required this.onPaths,
  });

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => onEnter(),
      onDragExited: (details) => onExit(),
      onDragDone: (details) {
        final paths = details.files.map((file) => file.path).toList();
        onPaths(paths);
      },
      child: child,
    );
  }
}
