import '../models/app_intents.dart';
import '../widgets/scale_buddy_app_bar.dart';
import '../widgets/workspace_status_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workflow_step.dart';
import '../models/entities/drawing_entity.dart';
import '../controllers/workspace_controller.dart';
import '../widgets/step_detail_view.dart';
import '../widgets/workflow_sidebar.dart';
import '../tools/distance_tool.dart';
import '../tools/calibration_tool.dart';
import '../tools/polygon_tool.dart';
import '../tools/rectangle_tool.dart';
import '../tools/angle_tool.dart';
import '../tools/select_tool.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  WorkflowStepType _activeStep = WorkflowStepType.file;
  final Map<WorkflowStepType, StepStatus> _stepStatuses = {
    WorkflowStepType.file: StepStatus.active,
    WorkflowStepType.perspective: StepStatus.open,
    WorkflowStepType.calibrate: StepStatus.open,
    WorkflowStepType.measure: StepStatus.open,
  };
  ToolAction? _lastSelectedTool;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      ref.read(workspaceControllerProvider.notifier).cancelCurrentTool();
      return false; // Not fully consuming so dialogs can still close if needed
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspaceController = ref.watch(workspaceControllerProvider.notifier);
    final activeTool = ref.watch(activeToolProvider);
    ToolAction? currentToolAction;
    if (activeTool is DistanceTool) {
      currentToolAction = ToolAction.measureDistance;
    } else if (activeTool is PolygonTool)
      currentToolAction = ToolAction.measurePolygon;
    else if (activeTool is RectangleTool)
      currentToolAction = ToolAction.measureRectArea;
    else if (activeTool is AngleTool)
      currentToolAction = ToolAction.measureRoofAngle;
    else if (activeTool is SelectTool)
      currentToolAction = ToolAction.selectEdit;
    else if (activeTool is CalibrationTool)
      currentToolAction = ToolAction.setReference;

    ref.listen(workspaceControllerProvider, (previous, next) {
      if (next.loadedImage != null &&
          _stepStatuses[WorkflowStepType.file] != StepStatus.completed) {
        setState(() {
          _stepStatuses[WorkflowStepType.file] = StepStatus.active;
        });
      }
    });

    final calib = workspaceState.entities
        .whereType<CalibrationEntity>()
        .firstOrNull;
    final isCalibConfirmed = calib?.isConfirmed ?? false;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyV, control: true):
            PasteImageIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            PasteImageIntent(),
        SingleActivator(LogicalKeyboardKey.delete): DeleteScaleIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): DeleteScaleIntent(),
        SingleActivator(LogicalKeyboardKey.escape): EscapeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PasteImageIntent: CallbackAction<PasteImageIntent>(
            onInvoke: (_) {
              workspaceController.pasteFromClipboard();
              return null;
            },
          ),
          DeleteScaleIntent: CallbackAction<DeleteScaleIntent>(
            onInvoke: (_) {
              if (workspaceState.selectedEntityId != null) {
                workspaceController.removeEntity(
                  workspaceState.selectedEntityId!,
                );
              } else if (_activeStep == WorkflowStepType.calibrate) {
                workspaceController.clearCalibration();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: ScaleBuddyAppBar(
              onNewMeasurement: () {
                _handleStepSelected(WorkflowStepType.file, calib);
                _handleToolSelected(
                  WorkflowStepType.file,
                  ToolAction.snipScreen,
                  workspaceController,
                );
              },
              onZoomIn: () {
                final controller = ref.read(transformationControllerProvider);
                final matrix = controller.value.clone();
                // ignore: deprecated_member_use
                matrix.scale(1.2);
                controller.value = matrix;
              },
              onZoomOut: () {
                final controller = ref.read(transformationControllerProvider);
                final matrix = controller.value.clone();
                // ignore: deprecated_member_use
                matrix.scale(1.0 / 1.2);
                controller.value = matrix;
              },
            ),
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkflowSidebar(
                        activeStep: _activeStep,
                        stepStatuses: _stepStatuses,
                        activeToolAction: currentToolAction,
                        onStepSelected: (step) =>
                            _handleStepSelected(step, calib),
                        onToolSelected: (step, action) => _handleToolSelected(
                          step,
                          action,
                          workspaceController,
                        ),
                        isNextEnabled:
                            _activeStep != WorkflowStepType.calibrate ||
                            isCalibConfirmed,
                      ),
                      Expanded(
                        child: StepDetailView(
                          activeStep: _activeStep,
                          currentStatus:
                              _stepStatuses[_activeStep] ?? StepStatus.open,
                          lastSelectedTool: _lastSelectedTool,
                          onStatusChanged: _handleStatusChanged,
                        ),
                      ),
                    ],
                  ),
                ),
                WorkspaceStatusBar(
                  activeStep: _activeStep,
                  lastSelectedTool: _lastSelectedTool,
                  workspaceState: workspaceState,
                  stepTitleFor: _stepTitleFor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleStepSelected(
    WorkflowStepType step,
    CalibrationEntity? calib,
  ) async {
    final controller = ref.read(workspaceControllerProvider.notifier);
    if (_activeStep == WorkflowStepType.calibrate &&
        step != WorkflowStepType.calibrate) {
      if (!controller.canLeaveCalibrationStep()) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ungespeicherte Änderungen'),
            content: const Text(
              'Du hast Punkte für den Maßstab gesetzt, diese aber noch nicht bestätigt. Möchtest du die Änderungen wirklich verwerfen und den Schritt verlassen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.redAccent),
                ),
                child: const Text('Verwerfen'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          return;
        } else {
          ref.read(workspaceControllerProvider.notifier).clearCalibration();
        }
      }
    }
    setState(() {
      _activeStep = step;
      if (_stepStatuses[step] != StepStatus.completed) {
        _stepStatuses[step] = StepStatus.active;
      }
    });

    if (step == WorkflowStepType.calibrate) {
      _handleToolSelected(step, ToolAction.setReference, controller);
    }
  }

  void _handleStatusChanged(StepStatus newStatus) {
    setState(() {
      _stepStatuses[_activeStep] = newStatus;
    });
  }

  void _handleToolSelected(
    WorkflowStepType step,
    ToolAction action,
    WorkspaceController controller,
  ) {
    setState(() {
      _lastSelectedTool = action;
    });
    switch (action) {
      case ToolAction.openFile:
        controller.loadFromPicker();
        break;
      case ToolAction.measureDistance:
        ref.read(activeToolProvider.notifier).setTool(const DistanceTool());
        break;
      case ToolAction.measureRectArea:
        ref.read(activeToolProvider.notifier).setTool(const RectangleTool());
        break;
      case ToolAction.measurePolygon:
        ref.read(activeToolProvider.notifier).setTool(const PolygonTool());
        break;
      case ToolAction.measureRoofAngle:
        ref.read(activeToolProvider.notifier).setTool(const AngleTool());
        break;
      case ToolAction.setReference:
        ref.read(activeToolProvider.notifier).setTool(const CalibrationTool());
        break;
      case ToolAction.selectEdit:
        ref.read(activeToolProvider.notifier).setTool(const SelectTool());
        break;
      default:
        break;
    }
  }

  String _stepTitleFor(WorkflowStepType step) {
    return WorkflowStepData.allSteps.firstWhere((s) => s.type == step).title;
  }
}
