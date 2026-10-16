import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../utils/calibration_input_utils.dart';

class CalibrationInputWidget extends ConsumerStatefulWidget {
  static const double cardWidth = 220.0;
  static const double cardHeight = 44.0;

  final VoidCallback? onDragStart;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDoubleTap;
  final bool isDraggable;

  const CalibrationInputWidget({
    super.key,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDoubleTap,
    this.isDraggable = true,
  });

  @override
  ConsumerState<CalibrationInputWidget> createState() =>
      _CalibrationInputWidgetState();
}

class _CalibrationInputWidgetState extends ConsumerState<CalibrationInputWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedUnit = 'm';
  String? _errorText;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.watch(workspaceControllerProvider);
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    if (calib != null) {
      if (calib.enteredDistance != null && _textController.text.isEmpty) {
        _textController.text = CalibrationInputUtils.formatDistance(
          calib.enteredDistance,
        );
      }
      if (calib.selectedUnit != _selectedUnit &&
          CalibrationInputUtils.isValidUnit(calib.selectedUnit)) {
        _selectedUnit = calib.selectedUnit;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final val = CalibrationInputUtils.parseDistance(_textController.text);

    if (val == null) {
      setState(() => _errorText = 'Ungültig');
      _shakeController.forward(from: 0.0);
      _focusNode.requestFocus();
      return;
    }

    setState(() => _errorText = null);
    ref
        .read(workspaceControllerProvider.notifier)
        .confirmCalibration(distance: val, unit: _selectedUnit);
  }

  @override
  Widget build(BuildContext context) {
    const double uiHeight = 32.0;
    final boxStyle = BoxDecoration(
      color: AppColors.of(context).toolbarBg,
      border: Border.all(color: AppColors.of(context).inputBorder),
      borderRadius: BorderRadius.circular(4),
    );

    final calib = ref
        .watch(workspaceControllerProvider)
        .entities
        .whereType<CalibrationEntity>()
        .firstOrNull;
    final isConfirmed = calib?.isConfirmed ?? false;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.of(context).inputBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isConfirmed
                  ? AppColors.of(context).success
                  : Colors.white24,
              width: isConfirmed ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.isDraggable)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => widget.onDragStart?.call(),
                      onPanUpdate: widget.onDragUpdate,
                      onPanEnd: (_) => widget.onDragEnd?.call(),
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.drag_indicator,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  if (isConfirmed) ...[
                    // READ-ONLY MODE
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ref
                            .read(workspaceControllerProvider.notifier)
                            .unconfirmCalibration();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _focusNode.requestFocus();
                        });
                      },
                      onDoubleTap: widget.onDoubleTap,
                      child: Container(
                        height: uiHeight,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: boxStyle,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${CalibrationInputUtils.formatDistance(calib?.enteredDistance)} $_selectedUnit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit,
                              color: Colors.white54,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // EDIT MODE
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final dx =
                            math.sin(_shakeController.value * math.pi * 4) *
                            8 *
                            (1 - _shakeController.value);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 70,
                        height: uiHeight,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.of(context).inputBorder,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Länge',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          onSubmitted: (_) => _handleConfirm(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.3),
                        splashColor: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.4),
                      ),
                      child: Container(
                        height: uiHeight,
                        decoration: boxStyle,
                        child: PopupMenuButton<String>(
                          initialValue: _selectedUnit,
                          color: AppColors.of(context).toolbarBg,
                          position: PopupMenuPosition.under,
                          constraints: const BoxConstraints(
                            minWidth: 60,
                            maxWidth: 70,
                          ),
                          onSelected: (val) {
                            setState(() => _selectedUnit = val);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'mm',
                              height: 32,
                              child: Center(
                                child: Text(
                                  'mm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cm',
                              height: 32,
                              child: Center(
                                child: Text(
                                  'cm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'm',
                              height: 32,
                              child: Center(
                                child: Text(
                                  'm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedUnit,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _handleConfirm,
                      child: Container(
                        height: uiHeight,
                        width: uiHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.check,
                          color: AppColors.of(context).iconActive,
                          size: 18,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(workspaceControllerProvider.notifier)
                          .clearCalibration();
                    },
                    child: Container(
                      height: uiHeight,
                      width: uiHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isConfirmed && _errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
