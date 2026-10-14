import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/entities/drawing_entity.dart';
import '../models/mobile_calibration_state.dart';
import '../theme/responsive.dart';

/// Schwebende Steuerungsleiste (Floating Dock) am unteren Rand des mobilen Bildschirms in Schritt 3 („Maßstab kalibrieren“).
///
/// Unterstützt 4 Workflow-Zustände:
/// 1. Start (Phase 1): Dezente Hinweispille: „⊙ Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)“ – ohne Überspringen-Button.
/// 2. Punkt 1 gesetzt (Phase 2): [ ↺ Zurücksetzen ] und [ ✓ Bestätigen ] (deaktiviert).
/// 3. Eingabe mit Zifferntastatur (Phase 3): [ 🗑 Löschen ], Eingabefeld mit Einheiten-Dropdown [ m ▾ ] und [ ✓ Bestätigen ] (aktiv ab Wert > 0).
/// 4. Erfolgreich kalibriert (Phase 4): [ ✎ Anpassen ], [ 🗑 Löschen ] und [ Weiter zu Schritt 4 › ] (primär blau).
class MobileCalibrationDock extends ConsumerStatefulWidget {
  final VoidCallback? onNextStep;

  const MobileCalibrationDock({super.key, this.onNextStep});

  @override
  ConsumerState<MobileCalibrationDock> createState() =>
      _MobileCalibrationDockState();
}

class _MobileCalibrationDockState extends ConsumerState<MobileCalibrationDock> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedUnit = 'm';
  MobileCalibrationStepState? _lastState;
  bool _isKeypadOpen = true;

  OverlayEntry? _unitOverlay;
  final LayerLink _unitLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _closeUnitOverlay();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncEntityData(CalibrationEntity? calibEntity) {
    if (calibEntity == null) return;

    if (calibEntity.selectedUnit != _selectedUnit &&
        (calibEntity.selectedUnit == 'm' ||
            calibEntity.selectedUnit == 'cm' ||
            calibEntity.selectedUnit == 'mm')) {
      _selectedUnit = calibEntity.selectedUnit;
    }

    if (_textController.text.isEmpty &&
        calibEntity.enteredDistance != null &&
        calibEntity.enteredDistance! > 0) {
      final dist = calibEntity.enteredDistance!;
      final formatted = dist.toStringAsFixed(2).replaceAll('.', ',');
      _textController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= AppBreakpoints.mobileWidth) {
      return const SizedBox.shrink();
    }

    final calibFlow = ref.watch(mobileCalibrationStateProvider);
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspaceController = ref.read(workspaceControllerProvider.notifier);

    final calibEntity = workspaceState.entities
        .whereType<CalibrationEntity>()
        .firstOrNull;

    final effectiveState = calibFlow.calculateEffectiveState(
      p1: calibEntity?.p1,
      p2: calibEntity?.p2,
      isConfirmed: calibEntity?.isConfirmed ?? false,
    );

    _syncEntityData(calibEntity);

    // Automatischer Tastaturfokus beim Betreten von Phase 3
    if (effectiveState == MobileCalibrationStepState.twoPointsInput &&
        _lastState != MobileCalibrationStepState.twoPointsInput) {
      _isKeypadOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    } else if (effectiveState != MobileCalibrationStepState.twoPointsInput &&
        _lastState == MobileCalibrationStepState.twoPointsInput) {
      _closeUnitOverlay();
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
    _lastState = effectiveState;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: effectiveState == MobileCalibrationStepState.initial
            ? _buildPhase1HintPill()
            : (effectiveState == MobileCalibrationStepState.twoPointsInput
                  ? _buildPhase3WithKeypad(context, ref, workspaceController)
                  : _buildDockContainer(
                      child: _buildDockContent(
                        context,
                        ref,
                        effectiveState,
                        workspaceController,
                      ),
                    )),
      ),
    );
  }

  /// Schwebende Hinweispille für Phase 1 (0 Punkte gesetzt).
  Widget _buildPhase1HintPill() {
    const text = 'Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)';

    return Semantics(
      container: true,
      label: 'Hinweis: $text',
      child: Center(
        child: Container(
          constraints: const BoxConstraints(minHeight: 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: const Color(0xFF334155), // Slate-700
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.gps_fixed,
                size: 16.0,
                color: Color(0xFF38BDF8), // Leuchtend cyan
              ),
              SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Color(0xFFCBD5E1), // Slate-300
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Äußerer Container für das schwebende Dock in den Phasen 2, 3 und 4.
  Widget _buildDockContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
        borderRadius: BorderRadius.circular(30.0), // Pillenform (Radius >= 24)
        border: Border.all(
          color: const Color(0xFF334155), // Slate-700
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDockContent(
    BuildContext context,
    WidgetRef ref,
    MobileCalibrationStepState state,
    WorkspaceController workspaceController,
  ) {
    switch (state) {
      case MobileCalibrationStepState.initial:
        return const SizedBox.shrink();
      case MobileCalibrationStepState.onePoint:
        return _buildPhase2OnePoint(context, ref, workspaceController);
      case MobileCalibrationStepState.twoPointsInput:
        return const SizedBox.shrink();
      case MobileCalibrationStepState.confirmed:
        return _buildPhase4Confirmed(context, ref, workspaceController);
    }
  }

  /// Phase 2: Punkt 1 gesetzt.
  /// [ ↺ Zurücksetzen ] | [ ✓ Bestätigen ] (deaktiviert)
  Widget _buildPhase2OnePoint(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // [ ↺ Zurücksetzen ]
        _buildDockButton(
          flex: 1,
          label: 'Zurücksetzen',
          icon: Icons.refresh,
          iconColor: const Color(0xFF94A3B8),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF94A3B8),
          onPressed: () => _handleReset(ref, workspaceController),
        ),
        const SizedBox(width: 8.0),
        // Vertikaler Trennstrich
        Container(width: 1.0, height: 20.0, color: const Color(0xFF334155)),
        const SizedBox(width: 8.0),
        // [ ✓ Bestätigen ] (strikt deaktiviert)
        _buildDockButton(
          flex: 1,
          label: 'Bestätigen',
          icon: Icons.check,
          iconColor: const Color(0xFF64748B),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF64748B),
          onPressed: null,
        ),
      ],
    );
  }

  /// Phase 3: Eingabe mit nativer Zifferntastatur.
  /// [ 🗑 Löschen ], Eingabe-Pille mit Einheiten-Dropdown, [ ✓ Bestätigen ]
  Widget _buildPhase3Input(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    final cleanText = _textController.text.replaceAll(',', '.');
    final val = double.tryParse(cleanText);
    final bool isValid = val != null && val > 0;

    return Row(
      children: [
        // [ 🗑 Löschen ]
        _buildDeleteButton(ref, workspaceController, flex: 1),
        const SizedBox(width: 6.0),
        // Eingabe-Pille (Cyan-Fokusrahmen, TextField + Dropdown)
        Expanded(
          flex: 2,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Slate-900
              borderRadius: BorderRadius.circular(22.0),
              border: Border.all(
                color: const Color(0xFF38BDF8), // Cyan aktiver Fokusrahmen
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  blurRadius: 8.0,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.backspace) {
                          _handleKeypadBackspace();
                          return KeyEventResult.handled;
                        }
                        final char = event.character;
                        if (char != null) {
                          if (RegExp(r'^[0-9]$').hasMatch(char)) {
                            _handleKeypadDigit(char);
                            return KeyEventResult.handled;
                          } else if (char == ',' || char == '.') {
                            _handleKeypadDigit(',');
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: true,
                      readOnly: true,
                      showCursor: true,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.none,
                      onTap: () {
                        if (!_isKeypadOpen) {
                          setState(() => _isKeypadOpen = true);
                        }
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                      cursorColor: const Color(0xFF38BDF8),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '0,00',
                        hintStyle: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0,
                  height: 18.0,
                  color: const Color(0xFF334155),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                ),
                _buildUnitDropdown(workspaceController),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        // [ ✓ Bestätigen ]
        _buildDockButton(
          flex: 1,
          label: 'Bestätigen',
          icon: Icons.check,
          iconColor: isValid ? Colors.white : const Color(0xFF64748B),
          backgroundColor: isValid
              ? const Color(0xFF2563EB)
              : const Color(0xFF0F172A),
          textColor: isValid ? Colors.white : const Color(0xFF64748B),
          borderColor: isValid ? null : const Color(0xFF334155),
          isPrimary: isValid,
          onPressed: isValid
              ? () => _handleConfirm(ref, workspaceController, val)
              : null,
        ),
      ],
    );
  }

  Widget _buildDeleteButton(
    WidgetRef ref,
    WorkspaceController workspaceController, {
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Semantics(
        button: true,
        enabled: true,
        label: 'Löschen',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleDelete(ref, workspaceController),
            borderRadius: BorderRadius.circular(22.0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 8.0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 16.0,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      'Löschen',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown(WorkspaceController workspaceController) {
    return CompositedTransformTarget(
      link: _unitLayerLink,
      child: Semantics(
        button: true,
        label: 'Einheit wählen: $_selectedUnit',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleUnitOverlay(workspaceController),
            borderRadius: BorderRadius.circular(14.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedUnit,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF38BDF8),
                    size: 16.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleUnitOverlay(WorkspaceController workspaceController) {
    if (_unitOverlay != null) {
      _closeUnitOverlay();
      return;
    }

    _unitOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier: Schließt das Menü bei Klick daneben, ohne Tastaturfokus zu verlieren
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeUnitOverlay,
              ),
            ),
            // Schwebendes Menü direkt oberhalb des Einheiten-Buttons
            Positioned(
              width: 58,
              child: CompositedTransformFollower(
                link: _unitLayerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                offset: const Offset(0, -6),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['m', 'cm', 'mm'].map((unit) {
                          final isSelected = unit == _selectedUnit;
                          return InkWell(
                            onTap: () {
                              if (unit != _selectedUnit) {
                                setState(() => _selectedUnit = unit);
                                workspaceController.updateCalibrationUnit(unit);
                              }
                              _closeUnitOverlay();
                              _focusNode.requestFocus();
                            },
                            child: Container(
                              height: 38.0,
                              alignment: Alignment.center,
                              color: isSelected
                                  ? const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.15)
                                  : Colors.transparent,
                              child: Text(
                                unit,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_unitOverlay!);
  }

  void _closeUnitOverlay() {
    _unitOverlay?.remove();
    _unitOverlay = null;
  }

  /// Phase 4: Erfolgreich kalibriert.
  /// [ ✎ Anpassen ], [ 🗑 Löschen ], [ Weiter zu Schritt 4 › ]
  Widget _buildPhase4Confirmed(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Row(
      children: [
        // [ ✎ Anpassen ]
        _buildDockButton(
          flex: 2,
          label: 'Anpassen',
          icon: Icons.edit_outlined,
          iconColor: const Color(0xFF38BDF8),
          borderColor: const Color(0xFF0284C7).withValues(alpha: 0.6),
          backgroundColor: const Color(0xFF0F172A),
          textColor: Colors.white,
          onPressed: () {
            setState(() => _isKeypadOpen = true);
            workspaceController.unconfirmCalibration();
            ref
                .read(mobileCalibrationStateProvider.notifier)
                .setTwoPointsInput();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _focusNode.requestFocus();
            });
          },
        ),
        const SizedBox(width: 6.0),
        // [ 🗑 Löschen ]
        _buildDockButton(
          flex: 2,
          label: 'Löschen',
          icon: Icons.delete_outline,
          iconColor: const Color(0xFF94A3B8),
          borderColor: const Color(0xFF334155),
          backgroundColor: const Color(0xFF0F172A),
          textColor: const Color(0xFF94A3B8),
          onPressed: () => _handleReset(ref, workspaceController),
        ),
        const SizedBox(width: 6.0),
        // [ Weiter zu Schritt 4 › ]
        _buildDockButton(
          flex: 3,
          label: 'Weiter zu Schritt 4',
          icon: Icons.chevron_right,
          iconColor: Colors.white,
          backgroundColor: const Color(0xFF2563EB), // Leuchtend blau
          textColor: Colors.white,
          isPrimary: true,
          onPressed: widget.onNextStep,
        ),
      ],
    );
  }

  Widget _buildPhase3WithKeypad(
    BuildContext context,
    WidgetRef ref,
    WorkspaceController workspaceController,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDockContainer(
          child: _buildPhase3Input(context, ref, workspaceController),
        ),
        if (_isKeypadOpen) ...[
          const SizedBox(height: 8.0),
          _buildKeypad(),
        ] else ...[
          const SizedBox(height: 6.0),
          _buildKeypadOpenButton(),
        ],
      ],
    );
  }

  Widget _buildKeypadOpenButton() {
    return Center(
      child: Semantics(
        button: true,
        label: 'Zifferntastatur einblenden',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _isKeypadOpen = true);
              _focusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFF334155), width: 1.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard, size: 14.0, color: Color(0xFF38BDF8)),
                  SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      'Tastatur öffnen ▴',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.98), // Slate-800
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF334155), // Slate-700
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'NATIVE ZIFFERNTASATUR (NUR ZAHLEN & KOMMA)',
                    style: TextStyle(
                      color: Color(0xFF94A3B8), // Slate-400
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8.0),
                Semantics(
                  button: true,
                  label: 'Tastatur schließen',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _isKeypadOpen = false);
                      },
                      borderRadius: BorderRadius.circular(6.0),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Schließen',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2.0),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF38BDF8),
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 6.0),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 6.0),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 6.0),
          _buildKeypadBottomRow(),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: _buildKeypadButton(
              label: key,
              semanticsLabel: 'Ziffer $key',
              onPressed: () => _handleKeypadDigit(key),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadBottomRow() {
    return Row(
      children: [
        // Komma ','
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: _buildKeypadButton(
              label: ',',
              semanticsLabel: 'Komma',
              onPressed: () => _handleKeypadDigit(','),
            ),
          ),
        ),
        // Ziffer '0'
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: _buildKeypadButton(
              label: '0',
              semanticsLabel: 'Ziffer 0',
              onPressed: () => _handleKeypadDigit('0'),
            ),
          ),
        ),
        // Backspace '⌫' (Löschen)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: _buildKeypadButton(
              icon: Icons.backspace_outlined,
              semanticsLabel: 'Ziffer löschen',
              onPressed: _handleKeypadBackspace,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton({
    String? label,
    IconData? icon,
    required String semanticsLabel,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: const Color(0xFF334155).withValues(alpha: 0.8), // Slate-700
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          highlightColor: const Color(0xFF38BDF8).withValues(alpha: 0.1),
          child: Container(
            height: 46.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF475569).withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 22.0)
                : Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleKeypadBackspace() {
    final text = _textController.text;
    if (text.isEmpty) return;

    final selection = _textController.selection;
    String nextText;
    int nextOffset;

    if (selection.isValid && !selection.isCollapsed) {
      nextText = text.replaceRange(selection.start, selection.end, '');
      nextOffset = selection.start;
    } else {
      final cursor = selection.isValid ? selection.baseOffset : text.length;
      if (cursor > 0) {
        nextText = text.substring(0, cursor - 1) + text.substring(cursor);
        nextOffset = cursor - 1;
      } else {
        nextText = text.substring(0, text.length - 1);
        nextOffset = nextText.length;
      }
    }

    _textController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: nextOffset.clamp(0, nextText.length),
      ),
    );

    _syncDistanceToController(nextText);
  }

  void _handleKeypadDigit(String digit) {
    final text = _textController.text;
    if (digit == ',') {
      if (text.contains(',') || text.contains('.')) return;
      if (text.isEmpty) {
        _insertKeypadText('0,');
        return;
      }
    } else {
      final sep = text.contains(',') ? ',' : (text.contains('.') ? '.' : null);
      if (sep != null) {
        final parts = text.split(sep);
        if (parts.length > 1 && parts[1].length >= 2) {
          final sel = _textController.selection;
          if (!sel.isValid ||
              sel.isCollapsed ||
              sel.start <= text.indexOf(sep)) {
            return;
          }
        }
      }
    }
    _insertKeypadText(digit);
  }

  void _insertKeypadText(String str) {
    final text = _textController.text;
    final selection = _textController.selection;
    String nextText;
    int nextOffset;

    if (selection.isValid && !selection.isCollapsed) {
      nextText = text.replaceRange(selection.start, selection.end, str);
      nextOffset = selection.start + str.length;
    } else {
      final cursor = selection.isValid ? selection.baseOffset : text.length;
      nextText = text.substring(0, cursor) + str + text.substring(cursor);
      nextOffset = cursor + str.length;
    }

    _textController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: nextOffset.clamp(0, nextText.length),
      ),
    );

    _syncDistanceToController(nextText);
  }

  void _syncDistanceToController(String text) {
    final cText = text.replaceAll(',', '.');
    final parsed = double.tryParse(cText);
    if (parsed != null && parsed > 0) {
      ref
          .read(workspaceControllerProvider.notifier)
          .updateCalibrationDistance(parsed);
    } else {
      ref
          .read(workspaceControllerProvider.notifier)
          .updateCalibrationDistance(null);
    }
    setState(() {});
  }

  void _handleDelete(WidgetRef ref, WorkspaceController workspaceController) {
    _closeUnitOverlay();
    _handleReset(ref, workspaceController);
  }

  void _handleReset(WidgetRef ref, WorkspaceController workspaceController) {
    _closeUnitOverlay();
    setState(() => _isKeypadOpen = false);
    workspaceController.clearCalibration();
    _textController.clear();
    ref.read(mobileCalibrationStateProvider.notifier).setInitial();
  }

  void _handleConfirm(
    WidgetRef ref,
    WorkspaceController workspaceController,
    double distance,
  ) {
    _closeUnitOverlay();
    setState(() => _isKeypadOpen = false);
    FocusScope.of(context).unfocus();
    workspaceController.confirmCalibration(
      distance: distance,
      unit: _selectedUnit,
    );
    ref.read(mobileCalibrationStateProvider.notifier).setConfirmed();
  }

  /// Touch-freundlicher Dock-Button (Mindestens 44x44 dp)
  Widget _buildDockButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    Color? backgroundColor,
    Color? borderColor,
    bool isPrimary = false,
    int flex = 1,
    VoidCallback? onPressed,
  }) {
    final bool isEnabled = onPressed != null;

    return Expanded(
      flex: flex,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22.0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(22.0),
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 1.0)
                    : null,
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16.0, color: iconColor),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.0,
                        fontWeight: isPrimary
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
