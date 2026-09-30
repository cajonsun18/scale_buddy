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

class StepDetailView extends ConsumerStatefulWidget {
  final WorkflowStepType activeStep;
  final StepStatus currentStatus;
  final ToolAction? lastSelectedTool;
  final ValueChanged<StepStatus> onStatusChanged;

  const StepDetailView({
    super.key,
    required this.activeStep,
    required this.currentStatus,
    this.lastSelectedTool,
    required this.onStatusChanged,
  });

  @override
  ConsumerState<StepDetailView> createState() => _StepDetailViewState();
}

class _StepDetailViewState extends ConsumerState<StepDetailView> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepData = WorkflowStepData.allSteps.firstWhere(
      (s) => s.type == widget.activeStep,
    );

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepData.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
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
          const SizedBox(height: 8),
          Text(
            stepData.shortDescription,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
              child: workspaceState.status == LoadingStatus.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    )
                  : (workspaceState.loadedImage != null
                        ? WorkspaceImageView(activeStep: widget.activeStep)
                        : WorkspacePlaceholder(stepData: stepData)),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workspaceState.statusMessage ==
                            WorkspaceError.selectionCancelled
                        ? 'Auswahl abgebrochen'
                        : 'Fehler beim Laden',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
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
