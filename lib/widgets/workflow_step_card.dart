import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import '../models/workflow_step.dart';

/// Eine klickbare Menükarte für einen einzelnen Workflow-Schritt in der linken Seitenleiste.
///
/// Funktionsweise:
/// - Klickt der Nutzer auf die Karte, wird [onTap] aufgerufen und dieser Schritt wird zum aktiven Menü.
/// - Ist [isActive] wahr, öffnet sich die Karte (Akkordeon-Prinzip) und zeigt die verfügbaren Werkzeuge.
/// - Über [status] wird optisch angezeigt, ob der Schritt offen, aktuell aktiv oder bereits erledigt ist.
class WorkflowStepCard extends StatelessWidget {
  /// Die inhaltlichen Daten des Schritts (Titel, Symbol, Werkzeugliste).
  final WorkflowStepData stepData;

  /// Gibt an, ob dieses Menü aktuell geöffnet / ausgewählt ist.
  final bool isActive;

  /// Der aktuelle Bearbeitungsstatus (offen, aktiv, erledigt).
  final StepStatus status;

  /// Callback-Funktion, die ausgelöst wird, wenn der Nutzer auf diesen Menüpunkt klickt.
  final VoidCallback onTap;

  /// Optionaler Callback, wenn innerhalb des geöffneten Menüs ein Werkzeug angeklickt wird.
  final ValueChanged<ToolAction>? onToolSelected;
  final ToolAction? activeToolAction;
  final Widget? extraContent;
  final bool isEnabled;

  const WorkflowStepCard({
    super.key,
    required this.stepData,
    required this.isActive,
    required this.status,
    required this.onTap,
    this.onToolSelected,
    this.activeToolAction,
    this.extraContent,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamische Farbgebung je nach Status
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary; // Z.B. #1E88E5 Blau

    // Rahmenfarbe: Aktiv = Akzentfarbe, sonst dezentes Grau
    final borderColor = !isEnabled
        ? Colors.grey.shade300
        : isActive
        ? activeColor
        : (status == StepStatus.completed
              ? AppColors.of(context).success.withValues(alpha: 0.5)
              : AppColors.of(context).sidebarBorder);

    // Hintergrundfarbe: Leicht getönt wenn aktiv
    final cardBgColor = !isEnabled
        ? Colors.grey.shade50
        : isActive
        ? activeColor.withValues(alpha: 0.04)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isActive ? 1.8 : 1.0),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Klickbereich: Ganze Karte ist klickbar
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KOPFZEILE DER KARTE (Nummer, Titel, Status-Icon, Pfeil)
                  Row(
                    children: [
                      // Runder Nummern-/Status-Badge links
                      _buildStatusBadge(context),
                      const SizedBox(width: 10),

                      // Titel und Kurzbeschreibung
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stepData.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isActive
                                    ? activeColor
                                    : AppColors.of(context).toolbarBg,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stepData.shortDescription,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Ausklapp-Indikator (Pfeil nach oben bei offen, nach unten bei geschlossen)
                      Icon(
                        isActive
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: isActive ? activeColor : Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),

                  // 2. AUSKLAPPBARER INHALT (Wird nur angezeigt, wenn dieses Menü geöffnet ist)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _buildExpandedContent(context),
                    crossFadeState: isActive
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Erstellt das runde Badge links (z. B. "1", "2" oder ein grünes Häkchen).
  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);

    if (status == StepStatus.completed) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.of(context).success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : AppColors.of(context).sidebarBorder,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${stepData.stepNumber}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// Baut den Inhalt auf, der sichtbar wird, wenn die Menükarte geöffnet ist.
  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1, color: AppColors.of(context).sidebarBorder),
        ),
        Text(
          'VERFÜGBARE WERKZEUGE:',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),

        // Liste der für diesen Schritt verfügbaren Werkzeug-Schaltflächen
        ...stepData.availableTools.map((toolDef) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: InkWell(
              onTap: () => onToolSelected?.call(toolDef.action),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: toolDef.action == activeToolAction
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: toolDef.action == activeToolAction
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.of(context).sidebarBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      toolDef.icon,
                      size: 14,
                      color: toolDef.action == activeToolAction
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        toolDef.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.of(context).toolbarBorder,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (extraContent != null) ...[
          const SizedBox(height: 12),
          extraContent!,
        ],
      ],
    );
  }
}
