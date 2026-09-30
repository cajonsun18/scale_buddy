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
  measureTriangleArea,
  measurePolygon,
  measureRoofAngle,
  measureSlopedRoof,
  movePointOrLabel,
}

class ToolDefinition {
  final ToolAction action;
  final String label;

  const ToolDefinition({required this.action, required this.label});
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
        ),
        ToolDefinition(
          action: ToolAction.openFile,
          label: 'Bilddatei vom Computer öffnen',
        ),
        ToolDefinition(
          action: ToolAction.showInfo,
          label: 'Bildinformationen anzeigen',
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
        ),
        ToolDefinition(
          action: ToolAction.manualPerspective,
          label: 'Manuelle 4-Punkt-Entzerrung',
        ),
        ToolDefinition(
          action: ToolAction.fineRotation,
          label: 'Feinrotation (0,5°-Schritte mit Hilfsgitter)',
        ),
        ToolDefinition(
          action: ToolAction.skipPerspective,
          label: 'Ohne Korrektur fortfahren',
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
        ),
        ToolDefinition(
          action: ToolAction.enterLength,
          label: 'Reale Länge eingeben (z. B. 2.50 m)',
        ),
        ToolDefinition(
          action: ToolAction.selectUnit,
          label: 'Einheit wählen: Meter (m) / cm / mm',
        ),
        ToolDefinition(
          action: ToolAction.autoAdjust,
          label: 'Bestehende Messungen automatisch anpassen',
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
          label: 'Strecke messen (S01, S02...)',
        ),
        ToolDefinition(
          action: ToolAction.measureRectArea,
          label: 'Rechteckfläche messen (F01, F02...)',
        ),
        ToolDefinition(
          action: ToolAction.measureTriangleArea,
          label: 'Dreiecksfläche messen',
        ),
        ToolDefinition(
          action: ToolAction.measurePolygon,
          label: 'Polygon (Vieleck) messen',
        ),
        ToolDefinition(
          action: ToolAction.measureRoofAngle,
          label: 'Dachneigungswinkel ermitteln',
        ),
        ToolDefinition(
          action: ToolAction.measureSlopedRoof,
          label: 'Geneigte Dachfläche (Rechteck / Dreieck)',
        ),
        ToolDefinition(
          action: ToolAction.movePointOrLabel,
          label: 'Messpunkt oder Beschriftung verschieben',
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
