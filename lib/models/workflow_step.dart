import 'package:flutter/material.dart';

/// Die 4 Hauptschritte des Mess-Workflows.
///
/// Jeder Schritt repräsentiert eines der vier Menüs auf der linken Seite.
enum WorkflowStepType {
  /// Schritt 1: Bildschirmausschnitt oder Datei importieren.
  file,

  /// Schritt 2: Entzerrung schräger Fotos oder stürzender Linien.
  perspective,

  /// Schritt 3: Festlegen des realen Maßstabs über eine Referenzstrecke.
  calibrate,

  /// Schritt 4: Durchführen aller Längen-, Flächen- und Dachmessungen.
  measure,
}

/// Der Bearbeitungsstatus eines Schrittes für optische Indikatoren.
enum StepStatus { open, active, completed }

enum ToolAction {
  snipScreen,
  openFile,
  showInfo,
  autoPerspective,
  manualPerspective,
  fineRotation,
  skipPerspective,
  setReference,
  enterLength,
  selectUnit,
  autoAdjust,
  measureDistance,
  measureRectArea,
  measurePolygon,
  measureRoofAngle,
  selectEdit,
}

class ToolDefinition {
  final ToolAction action;
  final String label;
  final IconData icon;

  const ToolDefinition({
    required this.action,
    required this.label,
    required this.icon,
  });
}

class WorkflowStepData {
  final WorkflowStepType type;
  final int stepNumber;
  final String title;
  final String shortDescription;
  final IconData icon;
  final List<ToolDefinition> availableTools;

  const WorkflowStepData({
    required this.type,
    required this.stepNumber,
    required this.title,
    required this.shortDescription,
    required this.icon,
    required this.availableTools,
  });

  /// Gibt die vordefinierten Daten für alle 4 Schritte zurück.
  static List<WorkflowStepData> get allSteps => const [
    WorkflowStepData(
      type: WorkflowStepType.file,
      stepNumber: 1,
      title: 'Datei laden',
      shortDescription: 'Screenshot aufnehmen oder Bild laden',
      icon: Icons.image_outlined,
      availableTools: [
        ToolDefinition(
          action: ToolAction.snipScreen,
          label: 'Bildschirmbereich aufnehmen (Snip)',
          icon: Icons.crop,
        ),
        ToolDefinition(
          action: ToolAction.openFile,
          label: 'Bilddatei vom Computer öffnen',
          icon: Icons.folder_open,
        ),
        ToolDefinition(
          action: ToolAction.showInfo,
          label: 'Bildinformationen anzeigen',
          icon: Icons.info_outline,
        ),
      ],
    ),
    WorkflowStepData(
      type: WorkflowStepType.perspective,
      stepNumber: 2,
      title: 'Perspektive korrigieren',
      shortDescription: 'Verzerrungen und Fluchtlinien ausgleichen',
      icon: Icons.crop_rotate_outlined,
      availableTools: [
        ToolDefinition(
          action: ToolAction.autoPerspective,
          label: 'Automatische Entzerrung (KI/OpenCV)',
          icon: Icons.auto_fix_high,
        ),
        ToolDefinition(
          action: ToolAction.manualPerspective,
          label: 'Manuelle 4-Punkt-Entzerrung',
          icon: Icons.filter_center_focus,
        ),
        ToolDefinition(
          action: ToolAction.fineRotation,
          label: 'Feinrotation (0,5Â°-Schritte mit Hilfsgitter)',
          icon: Icons.rotate_right,
        ),
        ToolDefinition(
          action: ToolAction.skipPerspective,
          label: 'Ohne Korrektur fortfahren',
          icon: Icons.arrow_forward,
        ),
      ],
    ),
    WorkflowStepData(
      type: WorkflowStepType.calibrate,
      stepNumber: 3,
      title: 'Kalibrieren',
      shortDescription: 'Maßstab über Referenzmaß festlegen',
      icon: Icons.straighten_outlined,
      availableTools: [
        ToolDefinition(
          action: ToolAction.setReference,
          label: 'Referenzstrecke im Bild anklicken (2 Punkte)',
          icon: Icons.straighten,
        ),
        ToolDefinition(
          action: ToolAction.enterLength,
          label: 'Reale Länge eingeben (z. B. 2.50 m)',
          icon: Icons.edit,
        ),
        ToolDefinition(
          action: ToolAction.selectUnit,
          label: 'Einheit wählen: Meter (m) / cm / mm',
          icon: Icons.tune,
        ),
        ToolDefinition(
          action: ToolAction.autoAdjust,
          label: 'Bestehende Messungen automatisch anpassen',
          icon: Icons.sync,
        ),
      ],
    ),
    WorkflowStepData(
      type: WorkflowStepType.measure,
      stepNumber: 4,
      title: 'Messen',
      shortDescription: 'Strecken, Flächen & Dachmaße ermitteln',
      icon: Icons.design_services_outlined,
      availableTools: [
        ToolDefinition(
          action: ToolAction.measureDistance,
          label: 'Länge',
          icon: Icons.timeline,
        ),
        ToolDefinition(
          action: ToolAction.measurePolygon,
          label: 'Fläche (Frei)',
          icon: Icons.polyline,
        ),
        ToolDefinition(
          action: ToolAction.measureRectArea,
          label: 'Fläche (Rechteck)',
          icon: Icons.crop_square,
        ),
        ToolDefinition(
          action: ToolAction.measureRoofAngle,
          label: 'Dachwinkel',
          icon: Icons.roofing,
        ),
        ToolDefinition(
          action: ToolAction.selectEdit,
          label: 'Auswählen/Bearbeiten',
          icon: Icons.pan_tool_alt,
        ),
      ],
    ),
  ];

  static String labelFor(ToolAction action) {
    for (final step in allSteps) {
      for (final def in step.availableTools) {
        if (def.action == action) return def.label;
      }
    }
    return '';
  }
}
