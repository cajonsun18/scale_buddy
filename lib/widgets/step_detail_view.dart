import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../models/workflow_step.dart';
import '../controllers/workspace_controller.dart';
import 'workspace_toolbar.dart';
import 'workspace_placeholder.dart';
import 'workspace_image_view.dart';

/// Rechte Arbeits- und Detailansicht passend zum aktiven Workflow-Schritt.
class StepDetailView extends StatefulWidget {
  /// Der aktuell links geöffnete Schritt.
  final WorkflowStepType activeStep;

  /// Status des aktuellen Schritts (offen, aktiv, erledigt).
  final StepStatus currentStatus;

  /// Zuletzt im linken Menü angeklicktes Werkzeug (falls vorhanden).
  final String? lastSelectedTool;

  /// Callback, um diesen Schritt als erledigt oder offen zu markieren.
  final ValueChanged<StepStatus> onStatusChanged;

  /// Das Gehirn der Arbeitsfläche (hält Ladezustand und Bild)
  final WorkspaceController controller;

  const StepDetailView({
    super.key,
    required this.activeStep,
    required this.currentStatus,
    this.lastSelectedTool,
    required this.onStatusChanged,
    required this.controller,
  });

  @override
  State<StepDetailView> createState() => StepDetailViewState();
}

class StepDetailViewState extends State<StepDetailView> {
  bool _isDragHovering = false;

  @override
  Widget build(BuildContext context) {
    final stepData = WorkflowStepData.allSteps.firstWhere(
      (s) => s.type == widget.activeStep,
    );
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFF0F172A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          // ListenableBuilder sorgt dafür, dass sich die UI aktualisiert,
          // wenn der Controller 'notifyListeners()' aufruft!
          return ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isNarrow, theme, stepData),
                    const SizedBox(height: 16),
                    if (widget.lastSelectedTool != null)
                      _buildLastSelectedBanner(widget.lastSelectedTool!),
                    Expanded(child: _buildWorkspace(theme, stepData)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kopfbereich (Info + Status-Toggle)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
    bool isNarrow,
    ThemeData theme,
    WorkflowStepData stepData,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIconBox(theme, stepData),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHeaderText(theme, stepData)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusToggleButton(),
              ],
            )
          : Row(
              children: [
                _buildIconBox(theme, stepData),
                const SizedBox(width: 16),
                Expanded(child: _buildHeaderText(theme, stepData)),
                const SizedBox(width: 12),
                _buildStatusToggleButton(),
              ],
            ),
    );
  }

  Widget _buildIconBox(ThemeData theme, WorkflowStepData stepData) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(stepData.icon, size: 28, color: theme.colorScheme.primary),
    );
  }

  Widget _buildHeaderText(ThemeData theme, WorkflowStepData stepData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCHRITT ${stepData.stepNumber} VON 4 AKTIV',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          stepData.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stepData.shortDescription,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusToggleButton() {
    final isDone = widget.currentStatus == StepStatus.completed;
    return OutlinedButton.icon(
      onPressed: () {
        widget.onStatusChanged(
          isDone ? StepStatus.active : StepStatus.completed,
        );
      },
      icon: Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isDone ? Colors.greenAccent : Colors.white70,
        size: 15,
      ),
      label: Text(
        isDone ? 'Schritt abgeschlossen ✓' : 'Als erledigt markieren',
        style: TextStyle(
          color: isDone ? Colors.greenAccent : Colors.white70,
          fontSize: 11,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDone ? Colors.greenAccent.shade400 : const Color(0xFF475569),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildLastSelectedBanner(String toolName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              'Im Menü links gewählt: "$toolName"',
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

  // ---------------------------------------------------------------------------
  // Arbeitsfläche: Bildanzeige ODER Platzhalter ODER Drop-Zone
  // ---------------------------------------------------------------------------
  Widget _buildWorkspace(ThemeData theme, WorkflowStepData stepData) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragHovering
              ? theme.colorScheme.primary
              : const Color(0xFF334155),
          width: _isDragHovering ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Werkzeugleiste am oberen Rand der Arbeitsfläche
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WorkspaceToolbar(controller: widget.controller),
            ),
            // Bild oder Platzhalter
            Positioned.fill(
              top: 56,
              child: widget.controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    )
                  : (widget.controller.loadedImage != null
                        ? WorkspaceImageView(info: widget.controller.loadedImage!)
                        : WorkspacePlaceholder(stepData: stepData)),
            ),
            // Drag-Hover-Overlay
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
            // Drop-Listener (unsichtbar) deckt die gesamte Arbeitsfläche ab
            Positioned.fill(
              top: 56,
              child: _DropZoneLayer(
                onDragEntered: () {
                  if (!_isDragHovering) {
                    setState(() => _isDragHovering = true);
                  }
                },
                onDragExited: () {
                  if (_isDragHovering) {
                    setState(() => _isDragHovering = false);
                  }
                },
                onBytesDropped: (bytes) {
                  setState(() => _isDragHovering = false);
                  widget.controller.handleDroppedBytes(bytes);
                },
                onFilePathsDropped: (paths) {
                  setState(() => _isDragHovering = false);
                  widget.controller.handleDroppedFilePaths(paths);
                },
              ),
            ),
            // Statusmeldung unten
            if (widget.controller.statusMessage != null)
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
                    widget.controller.statusMessage!,
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

/// Unsichtbare Drop-Zone über [DropTargetShim] (defensiv: wenn `desktop_drop`
/// nicht installiert ist, fällt sie auf einen Listener ohne Effekt zurück).
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

/// Verwendet das `desktop_drop`-Paket, um die Drop-Zone zu aktivieren.
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
      // Wird gefeuert, wenn die Maus mit einer Datei in die Zone fährt (macht den blauen Rahmen)
      onDragEntered: (details) => onEnter(),
      // Wird gefeuert, wenn die Maus die Zone wieder verlässt
      onDragExited: (details) => onExit(),
      // Immer wenn eine oder mehrere Dateien in die Zone fallen
      onDragDone: (details) {
        // details.files ist eine Liste von XFile. Wir sammeln einfach alle Pfade
        // und schicken sie an den Controller.
        final paths = details.files.map((file) => file.path).toList();
        onPaths(paths);
      },
      child: child,
    );
  }
}
