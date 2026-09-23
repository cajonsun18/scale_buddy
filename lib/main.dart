import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/workflow_step.dart';
import 'controllers/workspace_controller.dart';
import 'widgets/step_detail_view.dart';
import 'widgets/workflow_sidebar.dart';

void main() {
  runApp(const ScaleBuddyApp());
}

/// Wurzel-Widget der ScaleBuddy-App.
///
/// Hier wird das allgemeine App-Thema (Material 3, Farben, Schriften) definiert.
class ScaleBuddyApp extends StatelessWidget {
  const ScaleBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Primärfarbe: Modernes technisches Blau
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const MainLayoutScreen(),
    );
  }
}

/// Hauptbildschirm der Anwendung (StatefulWidget).
///
/// Verwaltet den Zustand des aktiven Workflow-Schritts, der Statusanzeige
/// sowie das aktuell geladene Bild (Workspace).
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  /// Gibt an, welcher der 4 Schritte links aktuell geöffnet/ausgewählt ist.
  WorkflowStepType _activeStep = WorkflowStepType.file;

  /// Speichert den Status (offen, aktiv, erledigt) für jeden der 4 Schritte.
  final Map<WorkflowStepType, StepStatus> _stepStatuses = {
    WorkflowStepType.file: StepStatus.active,
    WorkflowStepType.perspective: StepStatus.open,
    WorkflowStepType.calibrate: StepStatus.open,
    WorkflowStepType.measure: StepStatus.open,
  };

  /// Speichert zur Veranschaulichung das zuletzt angeklickte Unterwerkzeug.
  String? _lastSelectedTool;

  /// Das neue "Gehirn" der Arbeitsfläche. Hält Bild, Ladezustand und Logik.
  final WorkspaceController _workspaceController = WorkspaceController();

  @override
  void initState() {
    super.initState();
    // Wenn der Controller ein Bild lädt, markieren wir den Schritt "Datei" automatisch als aktiv.
    _workspaceController.addListener(() {
      if (_workspaceController.loadedImage != null &&
          _stepStatuses[WorkflowStepType.file] != StepStatus.completed) {
        setState(() {
          _stepStatuses[WorkflowStepType.file] = StepStatus.active;
        });
      }
    });
  }

  @override
  void dispose() {
    _workspaceController.dispose();
    super.dispose();
  }

  /// Wechselt das aktive Workflow-Menü, wenn der Nutzer links auf eine Karte klickt.
  void _handleStepSelected(WorkflowStepType step) {
    setState(() {
      _activeStep = step;

      if (_stepStatuses[step] != StepStatus.completed) {
        _stepStatuses[step] = StepStatus.active;
      }
    });
  }

  /// Ändert den Status eines Schrittes (z. B. wenn er als erledigt abgehakt wird).
  void _handleStatusChanged(StepStatus newStatus) {
    setState(() {
      _stepStatuses[_activeStep] = newStatus;
    });
  }

  /// Reagiert auf den Klick eines Werkzeugs innerhalb der geöffneten Menükarte.
  void _handleToolSelected(WorkflowStepType step, String toolName) {
    setState(() {
      _lastSelectedTool = toolName;
    });

    // WENN der Nutzer auf "Bilddatei vom Computer öffnen" klickt,
    // sagen wir einfach unserem neuen Controller Bescheid!
    if (step == WorkflowStepType.file &&
        toolName == 'Bilddatei vom Computer öffnen') {
      _workspaceController.loadFromPicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyV, control: true):
            PasteImageIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            PasteImageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PasteImageIntent: CallbackAction<PasteImageIntent>(
            onInvoke: (_) {
              _workspaceController.pasteFromClipboard();
              return null;
            },
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            // =========================================================================
            // 1. OBERE LEISTE (AppBar)
            // =========================================================================
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.architecture,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ScaleBuddy',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Screen-Bauzeichnungs-Messtool',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Schnellauswahl-Aktionen in der Kopfleiste
                FilledButton.tonalIcon(
                  onPressed: () {
                    _handleStepSelected(WorkflowStepType.file);
                    _handleToolSelected(
                      WorkflowStepType.file,
                      'Bildschirmbereich aufnehmen (Snip)',
                    );
                  },
                  icon: const Icon(Icons.crop, size: 18),
                  label: const Text('Weitere Messung'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Verkleinern (Zoom -)',
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {},
                ),
                IconButton(
                  tooltip: 'Vergrößern (Zoom +)',
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
              ],
            ),

            // =========================================================================
            // 2. HAUPTBEREICH: Linke Sidebar (4 Menüs) + Rechte Arbeitsfläche
            // =========================================================================
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LINKS: Die 4 Workflow-Menüs (anklickbar & ausklappbar)
                      WorkflowSidebar(
                        activeStep: _activeStep,
                        stepStatuses: _stepStatuses,
                        onStepSelected: _handleStepSelected,
                        onToolSelected: _handleToolSelected,
                      ),

                      // RECHTS: Die zum geöffneten Menü passende Arbeits- und Detailansicht
                      Expanded(
                        child: StepDetailView(
                          activeStep: _activeStep,
                          currentStatus:
                              _stepStatuses[_activeStep] ?? StepStatus.open,
                          lastSelectedTool: _lastSelectedTool,
                          onStatusChanged: _handleStatusChanged,
                          controller: _workspaceController,
                        ),
                      ),
                    ],
                  ),
                ),

                // =====================================================================
                // 3. UNTERE STATUSLEISTE (StatusBar)
                // =====================================================================
                ListenableBuilder(
                  listenable: _workspaceController,
                  builder: (context, _) {
                    return Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
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
                              _lastSelectedTool != null
                                  ? 'Aktives Menü: ${_stepTitleFor(_activeStep)}  •  Werkzeug: $_lastSelectedTool'
                                  : 'Aktives Menü: ${_stepTitleFor(_activeStep)}',
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
                            _workspaceController.loadedImage != null
                                ? 'Bild: ${_workspaceController.loadedImage!.dimensionsText}  |  ${_workspaceController.loadedImage!.formattedFileSize}'
                                : 'Maßstab: Nicht kalibriert  |  Zoom: 100%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitleFor(WorkflowStepType step) {
    return WorkflowStepData.allSteps.firstWhere((s) => s.type == step).title;
  }
}

/// Marker-Intent für das Einfügen aus der Zwischenablage.
class PasteImageIntent extends Intent {
  const PasteImageIntent();
}
