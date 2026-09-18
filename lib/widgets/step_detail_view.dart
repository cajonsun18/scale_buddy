import 'package:flutter/material.dart';
import '../models/workflow_step.dart';

/// Die Detail- und Arbeitsansicht auf der rechten Seite, die passend zum links
/// geöffneten Workflow-Schritt angezeigt wird.
///
/// Dient in Schritt 2 als anschauliche Visualisierung des aktiven Menüs
/// und erlaubt das Umschalten des Bearbeitungsstatus (z. B. auf "Erledigt ✓").
class StepDetailView extends StatelessWidget {
  /// Der aktuell links geöffnete Schritt.
  final WorkflowStepType activeStep;

  /// Status des aktuellen Schritts (offen, aktiv, erledigt).
  final StepStatus currentStatus;

  /// Zuletzt im linken Menü angeklicktes Werkzeug (falls vorhanden).
  final String? lastSelectedTool;

  /// Callback, um diesen Schritt als erledigt oder offen zu markieren.
  final ValueChanged<StepStatus> onStatusChanged;

  const StepDetailView({
    super.key,
    required this.activeStep,
    required this.currentStatus,
    this.lastSelectedTool,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stepData = WorkflowStepData.allSteps.firstWhere((s) => s.type == activeStep);
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFF0F172A), // Dunkles CAD/Workspace-Design
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. INFO-HEADER ZUM AKTIV GEÖFFNETEN SCHRITT
                Container(
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
                            _buildStatusToggleButton(context),
                          ],
                        )
                      : Row(
                          children: [
                            _buildIconBox(theme, stepData),
                            const SizedBox(width: 16),
                            Expanded(child: _buildHeaderText(theme, stepData)),
                            const SizedBox(width: 12),
                            _buildStatusToggleButton(context),
                          ],
                        ),
                ),

                const SizedBox(height: 16),

                // 2. ZEIGT DAS ZULETZT GEWÄHLTE WERKZEUG AN (INTERAKTIONSTEST)
                if (lastSelectedTool != null)
                  Container(
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
                            'Im Menü links gewählt: "$lastSelectedTool"',
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
                  ),

                // 3. CANVAS-PLATZHALTER MIT ERKLÄRUNG
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              stepData.icon,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Arbeitsfläche für: ${stepData.title}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                _detailExplanationFor(activeStep),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
      child: Icon(
        stepData.icon,
        size: 28,
        color: theme.colorScheme.primary,
      ),
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Schaltet den Schritt per Knopfdruck zwischen "Aktiv" und "Erledigt ✓" um.
  Widget _buildStatusToggleButton(BuildContext context) {
    final isDone = currentStatus == StepStatus.completed;

    return OutlinedButton.icon(
      onPressed: () {
        onStatusChanged(isDone ? StepStatus.active : StepStatus.completed);
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

  /// Detaillierte Textbeschreibung für jeden der 4 Schritte.
  String _detailExplanationFor(WorkflowStepType step) {
    switch (step) {
      case WorkflowStepType.file:
        return 'In diesem Schritt wird das Foto oder der Bauplan geladen.\n'
            'Hier wird später die Bildaufnahme (Snipping Tool) oder der Datei-Upload eingebunden.';
      case WorkflowStepType.perspective:
        return 'Hier wird die Schräglage des Bildes korrigiert.\n'
            'Du kannst stürzende Linien automatisch begradigen oder 4 Eckpunkte manuell setzen.';
      case WorkflowStepType.calibrate:
        return 'Hier wird der reale Maßstab definiert.\n'
            'Zwei Klicks auf eine bekannte Maßkette im Bild genügen, um den Pixel-zu-Meter-Faktor zu berechnen.';
      case WorkflowStepType.measure:
        return 'Hier stehen alle Zeichen- und Messwerkzeuge zur Verfügung:\n'
            'Strecken, Rechteck- und Dreiecksflächen, Dachneigungswinkel sowie echte Dachflächen.';
    }
  }
}
