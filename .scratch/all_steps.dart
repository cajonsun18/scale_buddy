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
          label: 'Feinrotation (0,5°-Schritte mit Hilfsgitter)',
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
