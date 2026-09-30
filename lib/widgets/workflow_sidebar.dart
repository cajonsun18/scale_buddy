import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/workflow_step.dart';
import 'workflow_step_card.dart';

/// Die linke Seitenleiste der Anwendung, die alle 4 Workflow-Menüs enthält.
///
/// Verantwortlichkeiten:
/// - Anzeige der Überschrift und des Arbeitsfortschritts.
/// - Rendern der 4 Menü-Karten (`Datei laden`, `Perspektive`, `Kalibrieren`, `Messen`).
/// - Steuerung, welcher Menüpunkt gerade geöffnet/ausgeklappt ist.
class WorkflowSidebar extends StatelessWidget {
  /// Der aktuell ausgewählte/geöffnete Schritt.
  final WorkflowStepType activeStep;

  /// Map mit dem Bearbeitungsstatus für jeden der 4 Schritte.
  final Map<WorkflowStepType, StepStatus> stepStatuses;

  /// Wird aufgerufen, wenn der Nutzer auf einen der 4 Menüpunkte klickt.
  final ValueChanged<WorkflowStepType> onStepSelected;

  /// Optionaler Callback, wenn innerhalb eines Menüs ein konkretes Werkzeug angeklickt wird.
  final void Function(WorkflowStepType step, ToolAction action)? onToolSelected;
  final bool isNextEnabled;

  const WorkflowSidebar({
    this.isNextEnabled = true,
    super.key,
    required this.activeStep,
    required this.stepStatuses,
    required this.onStepSelected,
    this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allSteps = WorkflowStepData.allSteps;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.of(context)
            .sidebarBg, // Leicht abgesetztes, helles Slate-Hintergrundgrau
        border: Border(
          right: BorderSide(
            color: AppColors.of(context).sidebarBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KOPFBEREICH DER SEITENLEISTE
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ARBEITSABLAUF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Kleiner Zähler "Schritt X von 4"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Schritt ${_stepNumberFor(activeStep)} von 4',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Klicke auf einen Schritt, um ihn zu öffnen.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.of(context).sidebarBorder),

          // 2. SCROLLBARE LISTE DER 4 MENÜPUNKTE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allSteps.length,
              itemBuilder: (context, index) {
                final step = allSteps[index];
                final isActive = step.type == activeStep;
                final status = stepStatuses[step.type] ?? StepStatus.open;

                return WorkflowStepCard(
                  stepData: step,
                  isActive: isActive,
                  status: status,
                  // Beim Klick auf eine Karte wird diese im State aktiviert/geöffnet
                  onTap: () => onStepSelected(step.type),
                  onToolSelected: (action) {
                    onToolSelected?.call(step.type, action);
                  },
                );
              },
            ),
          ),

          // 3. FUSSBEREICH DER SEITENLEISTE (Navigation vor / zurück)
          _buildBottomNavigationBar(context),
        ],
      ),
    );
  }

  /// Baut eine praktische "Nächster Schritt"-Leiste am unteren Ende der Sidebar.
  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentIndex = WorkflowStepData.allSteps.indexWhere(
      (s) => s.type == activeStep,
    );
    final hasNext = currentIndex < WorkflowStepData.allSteps.length - 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.of(context).sidebarBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (hasNext && isNextEnabled)
                  ? () {
                      final nextStep =
                          WorkflowStepData.allSteps[currentIndex + 1].type;
                      onStepSelected(nextStep);
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(
                hasNext
                    ? 'Weiter zu Schritt ${currentIndex + 2}'
                    : 'Alle Schritte erreicht',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _stepNumberFor(WorkflowStepType type) {
    switch (type) {
      case WorkflowStepType.file:
        return 1;
      case WorkflowStepType.perspective:
        return 2;
      case WorkflowStepType.calibrate:
        return 3;
      case WorkflowStepType.measure:
        return 4;
    }
  }
}
