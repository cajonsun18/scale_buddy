import 'package:flutter/material.dart';

import '../models/workspace_state.dart';

/// Die Basis-Klasse für alle Werkzeuge (Tools) in unserer App.
/// Das UI sendet Pointer-Events einfach an das aktuell aktive Tool.
/// Das Tool berechnet die Logik und gibt einen **neuen**, aktualisierten Status zurück.
abstract class WorkspaceTool {
  const WorkspaceTool();

  /// Aufgerufen, wenn der Nutzer auf das Bild tippt (z.B. Punkt setzen)
  WorkspaceState onTapUp(
    WorkspaceState state,
    TapUpDetails details,
    Size size,
  ) => state;

  /// Aufgerufen, wenn das Ziehen beginnt (z.B. Hit-Testing: Welcher Punkt wurde erwischt?)
  WorkspaceState onPanStart(
    WorkspaceState state,
    DragStartDetails details,
    Size size,
  ) => state;

  /// Aufgerufen, während der Finger/die Maus bewegt wird
  WorkspaceState onPanUpdate(
    WorkspaceState state,
    DragUpdateDetails details,
    Size size,
  ) => state;

  /// Aufgerufen, wenn der Nutzer die Aktion abbrechen möchte (z. B. ESC-Taste)
  WorkspaceState onCancel(WorkspaceState state) => state;

  WorkspaceState onPanEnd(
    WorkspaceState state,
    DragEndDetails details,
    Size size,
  ) => state;

  /// Helper to convert local pointer coordinates into normalized (0.0 to 1.0) coordinates.
  Offset normalizePosition(Offset localPosition, Size size) {
    if (size.width == 0 || size.height == 0) return Offset.zero;
    return Offset(
      localPosition.dx / size.width,
      localPosition.dy / size.height,
    );
  }
}

class EmptyTool extends WorkspaceTool {
  const EmptyTool();
}
