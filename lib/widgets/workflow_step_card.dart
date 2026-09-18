import 'package:flutter/material.dart';
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
  final ValueChanged<String>? onToolSelected;

  const WorkflowStepCard({
    super.key,
    required this.stepData,
    required this.isActive,
    required this.status,
    required this.onTap,
    this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamische Farbgebung je nach Status
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary; // Z.B. #1E88E5 Blau

    // Rahmenfarbe: Aktiv = Akzentfarbe, sonst dezentes Grau
    final borderColor = isActive
        ? activeColor
        : (status == StepStatus.completed ? Colors.green.shade300 : const Color(0xFFE2E8F0));

    // Hintergrundfarbe: Leicht getönt wenn aktiv
    final cardBgColor = isActive
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
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
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                              color: isActive ? activeColor : const Color(0xFF1E293B),
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
                      isActive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: isActive ? activeColor : Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),

                // 2. AUSKLAPPBARER INHALT (Wird nur angezeigt, wenn dieses Menü geöffnet ist)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedContent(context),
                  crossFadeState: isActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
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
          color: Colors.green.shade600,
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
            : const Color(0xFFE2E8F0),
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
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
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
        ...stepData.availableTools.map((toolName) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: InkWell(
              onTap: () => onToolSelected?.call(toolName),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForTool(toolName),
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        toolName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
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
      ],
    );
  }

  /// Passendes Mini-Symbol für das jeweilige Werkzeug.
  IconData _iconForTool(String toolName) {
    if (toolName.contains('Aufnehmen') || toolName.contains('Snip')) return Icons.crop;
    if (toolName.contains('Öffnen') || toolName.contains('laden')) return Icons.folder_open;
    if (toolName.contains('Automatisch')) return Icons.auto_fix_high;
    if (toolName.contains('4-Punkt')) return Icons.filter_center_focus;
    if (toolName.contains('Rotation')) return Icons.rotate_right;
    if (toolName.contains('Strecke')) return Icons.timeline;
    if (toolName.contains('Rechteck')) return Icons.crop_square;
    if (toolName.contains('Dreieck')) return Icons.change_history;
    if (toolName.contains('Polygon')) return Icons.polyline;
    if (toolName.contains('Dach')) return Icons.roofing;
    if (toolName.contains('Einheit')) return Icons.tune;
    return Icons.arrow_right;
  }
}
