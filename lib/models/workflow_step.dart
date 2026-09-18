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
enum StepStatus {
  /// Schritt ist noch nicht bearbeitet (grauer Indikator).
  open,

  /// Schritt ist aktuell ausgewählt und geöffnet (Akzentfarbe / Orange oder Blau).
  active,

  /// Schritt wurde erfolgreich abgeschlossen (grünes Häkchen).
  completed,
}

/// Datenmodell für einen Workflow-Menüpunkt.
///
/// Enthält alle beschreibenden Texte, Symbole und die für den Schritt
/// typischen Werkzeuge/Schaltflächen.
class WorkflowStepData {
  final WorkflowStepType type;
  final int stepNumber;
  final String title;
  final String shortDescription;
  final IconData icon;
  final List<String> availableTools;

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
        'Bildschirmbereich aufnehmen (Snip)',
        'Bilddatei vom Computer öffnen',
        'Bildinformationen anzeigen',
      ],
    ),
    WorkflowStepData(
      type: WorkflowStepType.perspective,
      stepNumber: 2,
      title: 'Perspektive korrigieren',
      shortDescription: 'Verzerrungen und Fluchtlinien ausgleichen',
      icon: Icons.crop_rotate_outlined,
      availableTools: [
        'Automatische Entzerrung (KI/OpenCV)',
        'Manuelle 4-Punkt-Entzerrung',
        'Feinrotation (0,5°-Schritte mit Hilfsgitter)',
        'Ohne Korrektur fortfahren',
      ],
    ),
    WorkflowStepData(
      type: WorkflowStepType.calibrate,
      stepNumber: 3,
      title: 'Kalibrieren',
      shortDescription: 'Maßstab über Referenzmaß festlegen',
      icon: Icons.straighten_outlined,
      availableTools: [
        'Referenzstrecke im Bild anklicken (2 Punkte)',
        'Reale Länge eingeben (z. B. 2.50 m)',
        'Einheit wählen: Meter (m) / cm / mm',
        'Bestehende Messungen automatisch anpassen',
      ],
    ),
    WorkflowStepData(
      type: WorkflowStepType.measure,
      stepNumber: 4,
      title: 'Messen',
      shortDescription: 'Strecken, Flächen & Dachmaße ermitteln',
      icon: Icons.design_services_outlined,
      availableTools: [
        'Strecke messen (S01, S02...)',
        'Rechteckfläche messen (F01, F02...)',
        'Dreiecksfläche messen',
        'Polygon (Vieleck) messen',
        'Dachneigungswinkel ermitteln',
        'Geneigte Dachfläche (Rechteck / Dreieck)',
        'Messpunkt oder Beschriftung verschieben',
      ],
    ),
  ];
}
