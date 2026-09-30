import 'package:flutter/material.dart';

import '../models/workspace_state.dart';
import '../models/workflow_step.dart';

class WorkspaceStatusBar extends StatelessWidget {
  final WorkflowStepType activeStep;
  final ToolAction? lastSelectedTool;
  final WorkspaceState workspaceState;
  final String Function(WorkflowStepType) stepTitleFor;

  const WorkspaceStatusBar({
    super.key,
    required this.activeStep,
    required this.lastSelectedTool,
    required this.workspaceState,
    required this.stepTitleFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastSelectedTool != null
                  ? 'Aktives Menü: ${stepTitleFor(activeStep)}  •  Werkzeug: ${WorkflowStepData.labelFor(lastSelectedTool!)}'
                  : 'Aktives Menü: ${stepTitleFor(activeStep)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            workspaceState.loadedImage != null
                ? 'Bild: ${workspaceState.loadedImage!.dimensionsText}  |  ${workspaceState.loadedImage!.formattedFileSize}'
                : 'Maßstab: Nicht kalibriert  |  Zoom: 100%',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
