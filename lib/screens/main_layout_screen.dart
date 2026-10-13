import '../models/app_intents.dart';
import '../widgets/scale_buddy_app_bar.dart';
import '../widgets/workspace_status_bar.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workflow_step.dart';
import '../models/entities/drawing_entity.dart';
import '../models/workspace_state.dart';
import '../controllers/workspace_controller.dart';
import '../widgets/step_detail_view.dart';
import '../widgets/workflow_sidebar.dart';
import '../services/export_service.dart';
import '../tools/distance_tool.dart';
import '../tools/calibration_tool.dart';
import '../tools/polygon_tool.dart';
import '../tools/rectangle_tool.dart';
import '../tools/angle_tool.dart';
import '../tools/select_tool.dart';
import '../tools/perspective_tool.dart';
import '../tools/workspace_tool.dart';

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
    WorkflowStepType.export: StepStatus.open,
  };
  ToolAction? _lastSelectedTool;
  // ignore: unused_field
  bool _isExporting = false;

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

  bool _isStepEnabled(
    WorkflowStepType step,
    WorkspaceState state,
    bool isCalibConfirmed,
  ) {
    switch (step) {
      case WorkflowStepType.file:
        return true;
      case WorkflowStepType.perspective:
        return state.loadedImage != null;
      case WorkflowStepType.calibrate:
        return _stepStatuses[WorkflowStepType.perspective] ==
            StepStatus.completed;
      case WorkflowStepType.measure:
        return isCalibConfirmed &&
            _stepStatuses[WorkflowStepType.calibrate] == StepStatus.completed;
      case WorkflowStepType.export:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspaceController = ref.watch(workspaceControllerProvider.notifier);
    final activeTool = ref.watch(activeToolProvider);
    ToolAction? currentToolAction;
    if (activeTool is DistanceTool) {
      currentToolAction = ToolAction.measureDistance;
    } else if (activeTool is PolygonTool) {
      currentToolAction = ToolAction.measurePolygon;
    } else if (activeTool is RectangleTool) {
      currentToolAction = ToolAction.measureRectArea;
    } else if (activeTool is AngleTool) {
      currentToolAction = ToolAction.measureRoofAngle;
    } else if (activeTool is SelectTool) {
      currentToolAction = ToolAction.selectEdit;
    } else if (activeTool is CalibrationTool) {
      currentToolAction = ToolAction.setReference;
    }

    ref.listen(workspaceControllerProvider, (previous, next) {
      final prevImage = previous?.loadedImage;
      final nextImage = next.loadedImage;

      if (nextImage != null && prevImage == null) {
        setState(() {
          _stepStatuses[WorkflowStepType.file] = StepStatus.completed;
          _activeStep = WorkflowStepType.perspective;
          if (_stepStatuses[WorkflowStepType.perspective] !=
              StepStatus.completed) {
            _stepStatuses[WorkflowStepType.perspective] = StepStatus.active;
          }
        });
      } else if (nextImage != null &&
          _stepStatuses[WorkflowStepType.file] != StepStatus.completed) {
        setState(() {
          _stepStatuses[WorkflowStepType.file] = StepStatus.completed;
        });
      } else if (nextImage == null && prevImage != null) {
        setState(() {
          _activeStep = WorkflowStepType.file;
          _stepStatuses[WorkflowStepType.file] = StepStatus.active;
          _stepStatuses[WorkflowStepType.perspective] = StepStatus.open;
          _stepStatuses[WorkflowStepType.calibrate] = StepStatus.open;
          _stepStatuses[WorkflowStepType.measure] = StepStatus.open;
        });
      }

      final nextCalib = next.entities
          .whereType<CalibrationEntity>()
          .firstOrNull;
      final prevCalib = previous?.entities
          .whereType<CalibrationEntity>()
          .firstOrNull;

      if (nextCalib?.isConfirmed == true && prevCalib?.isConfirmed != true) {
        setState(() {
          _stepStatuses[WorkflowStepType.calibrate] = StepStatus.completed;
          _activeStep = WorkflowStepType.measure;
          if (_stepStatuses[WorkflowStepType.measure] != StepStatus.completed) {
            _stepStatuses[WorkflowStepType.measure] = StepStatus.active;
          }
        });
      } else if (nextCalib?.isConfirmed == false &&
          prevCalib?.isConfirmed == true) {
        setState(() {
          _stepStatuses[WorkflowStepType.calibrate] = StepStatus.active;
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = AppBreakpoints.isMobileWidth(
                constraints.maxWidth,
              );
              final sidebar = WorkflowSidebar(
                activeStep: _activeStep,
                stepStatuses: _stepStatuses,
                activeToolAction: currentToolAction ?? _lastSelectedTool,
                onStepSelected: (step) {
                  _handleStepSelected(step, calib);
                },
                onToolSelected: (step, action) {
                  _handleToolSelected(step, action, workspaceController);
                },
                isStepEnabled: (step) =>
                    _isStepEnabled(step, workspaceState, isCalibConfirmed),
                extraContentBuilder: (context, step) {
                  if (step == WorkflowStepType.perspective) {
                    final pEntity = workspaceState.entities
                        .whereType<PerspectiveEntity>()
                        .firstOrNull;
                    Widget? actionButton;
                    if (pEntity != null && pEntity.points.length == 4) {
                      actionButton = SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            workspaceController.applyPerspectiveCorrection();
                            setState(() {
                              _stepStatuses[WorkflowStepType.perspective] =
                                  StepStatus.completed;
                            });
                          },
                          icon: const Icon(Icons.transform, size: 16),
                          label: const Text('Entzerren'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      );
                    } else if (workspaceState.originalImage != null &&
                        workspaceState.preWarpEntities != null) {
                      actionButton = SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            workspaceController.resetPerspective();
                            setState(() {
                              _stepStatuses[WorkflowStepType.perspective] =
                                  StepStatus.active;
                            });
                          },
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text('Punkte anpassen'),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Seitenverhältnis anpassen',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'X-Skalierung',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              workspaceState.perspectiveScaleX.toStringAsFixed(
                                2,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: workspaceState.perspectiveScaleX,
                          min: 0.1,
                          max: 3.0,
                          onChanged: (v) =>
                              workspaceController.setPerspectiveScaleX(v),
                          onChangeEnd: (v) =>
                              workspaceController.reapplyPerspectiveIfWarped(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Y-Skalierung',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              workspaceState.perspectiveScaleY.toStringAsFixed(
                                2,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: workspaceState.perspectiveScaleY,
                          min: 0.1,
                          max: 3.0,
                          onChanged: (v) =>
                              workspaceController.setPerspectiveScaleY(v),
                          onChangeEnd: (v) =>
                              workspaceController.reapplyPerspectiveIfWarped(),
                        ),
                        if (actionButton != null) const SizedBox(height: 16),
                        ?actionButton,
                      ],
                    );
                  }
                  return null;
                },
              );

              return Scaffold(
                backgroundColor: isMobile
                    ? AppColors.of(context).toolbarBg
                    : null,
                drawer: null,
                floatingActionButton: null,
                appBar: isMobile
                    ? null
                    : ScaleBuddyAppBar(
                        onNewMeasurement: () {
                          _handleStepSelected(WorkflowStepType.file, calib);
                          _handleToolSelected(
                            WorkflowStepType.file,
                            ToolAction.snipScreen,
                            workspaceController,
                          );
                        },
                        onZoomIn: () {
                          final controller = ref.read(
                            transformationControllerProvider,
                          );
                          final matrix = controller.value.clone();
                          // ignore: deprecated_member_use
                          matrix.scale(1.2);
                          controller.value = matrix;
                        },
                        onZoomOut: () {
                          final controller = ref.read(
                            transformationControllerProvider,
                          );
                          final matrix = controller.value.clone();
                          // ignore: deprecated_member_use
                          matrix.scale(1.0 / 1.2);
                          controller.value = matrix;
                        },
                      ),
                body: isMobile
                    ? StepDetailView(
                        activeStep: _activeStep,
                        currentStatus:
                            _stepStatuses[_activeStep] ?? StepStatus.open,
                        lastSelectedTool: _lastSelectedTool,
                        onStatusChanged: _handleStatusChanged,
                        onStepSelected: (step) =>
                            _handleStepSelected(step, calib),
                        isMobile: true,
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                sidebar,
                                Expanded(
                                  child: StepDetailView(
                                    activeStep: _activeStep,
                                    currentStatus:
                                        _stepStatuses[_activeStep] ??
                                        StepStatus.open,
                                    lastSelectedTool: _lastSelectedTool,
                                    onStatusChanged: _handleStatusChanged,
                                    isMobile: false,
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
              );
            },
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
      _handleToolSelected(step, ToolAction.setReference, controller, false);
    } else if (step == WorkflowStepType.perspective) {
      ref.read(activeToolProvider.notifier).setTool(const PerspectiveTool());
      setState(() {
        _lastSelectedTool = null;
      });
    } else if (step == WorkflowStepType.file) {
      ref.read(activeToolProvider.notifier).setTool(const EmptyTool());
      setState(() {
        _lastSelectedTool = null;
      });
    } else if (step == WorkflowStepType.measure) {
      final currentTool = ref.read(activeToolProvider);
      if (currentTool is EmptyTool ||
          currentTool is CalibrationTool ||
          currentTool is PerspectiveTool) {
        _handleToolSelected(step, ToolAction.selectEdit, controller, false);
      }
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
    WorkspaceController controller, [
    bool fromUserClick = true,
  ]) {
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
      case ToolAction.autoPerspective:
        ref.read(activeToolProvider.notifier).setTool(const PerspectiveTool());
        if (fromUserClick) {
          controller.autoDetectPerspective().then((_) {
            if (mounted) {
              final state = ref.read(workspaceControllerProvider);
              final hasPerspective = state.entities.any(
                (e) => e is PerspectiveEntity && e.points.length == 4,
              );
              if (!hasPerspective) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keine geeignete Form gefunden.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perspektive automatisch erkannt.'),
                  ),
                );
              }
            }
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _lastSelectedTool == ToolAction.autoPerspective) {
              setState(() {
                _lastSelectedTool = null;
              });
            }
          });
        }
        break;
      case ToolAction.skipPerspective:
        setState(() {
          _stepStatuses[WorkflowStepType.perspective] = StepStatus.completed;
          _activeStep = WorkflowStepType.calibrate;
          if (_stepStatuses[WorkflowStepType.calibrate] !=
              StepStatus.completed) {
            _stepStatuses[WorkflowStepType.calibrate] = StepStatus.active;
          }
        });
        break;
      case ToolAction.manualPerspective:
        ref.read(activeToolProvider.notifier).setTool(const PerspectiveTool());
        break;
      case ToolAction.exportImage:
        _exportImage(
          ref.read(workspaceControllerProvider),
          ref.read(exportServiceProvider),
        );
        break;
      case ToolAction.exportPdf:
        _exportPdf(
          ref.read(workspaceControllerProvider),
          ref.read(exportServiceProvider),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _runExportTask({
    required String dialogTitle,
    required String fileName,
    required Future<Uint8List> Function() generateBytes,
    List<String>? allowedExtensions,
    required String successMessage,
  }) async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'Export',
      extensions: allowedExtensions,
    );

    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: allowedExtensions != null ? [typeGroup] : [],
    );

    if (result == null) return;

    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final bytes = await generateBytes();
      final file = File(result.path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler beim Export: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportImage(
    WorkspaceState state,
    ExportService exportService,
  ) async {
    await _runExportTask(
      dialogTitle: 'Bild exportieren',
      fileName: 'export.png',
      generateBytes: () => exportService.generateExportImage(state),
      successMessage: 'Bild erfolgreich exportiert.',
    );
  }

  Future<void> _exportPdf(
    WorkspaceState state,
    ExportService exportService,
  ) async {
    await _runExportTask(
      dialogTitle: 'PDF-Bericht exportieren',
      fileName: 'bericht.pdf',
      allowedExtensions: ['pdf'],
      generateBytes: () => exportService.generatePdfReport(state),
      successMessage: 'PDF-Bericht erfolgreich exportiert.',
    );
  }

  String _stepTitleFor(WorkflowStepType step) {
    return WorkflowStepData.allSteps.firstWhere((s) => s.type == step).title;
  }
}
