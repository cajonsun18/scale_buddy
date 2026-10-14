import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/responsive.dart';

/// Wiederverwendbares Kopfbereich-Widget für mobile Workflow-Schritte (< 800 dp).
///
/// Vereinheitlicht:
/// - App-Titel („Scale Buddy“)
/// - Schritt-Untertitel (z. B. „Schritt 2: Perspektive korrigieren“)
/// - Barrierefreie Semantics-Kapselung
/// - Responsive Ausblendung auf Desktop-Bildschirmen (>= 800 dp)
/// - Mehrsprachigkeit ausschließlich über [AppLocalizations] (Option B).
class MobileStepHeader extends StatelessWidget {
  final String? subtitle;
  final String? semanticsLabel;
  final Widget statusPill;
  final String? appTitle;
  final bool checkDesktopBreakpoint;

  const MobileStepHeader({
    super.key,
    this.subtitle,
    this.semanticsLabel,
    required this.statusPill,
    this.appTitle,
    this.checkDesktopBreakpoint = false,
  });

  @override
  Widget build(BuildContext context) {
    if (checkDesktopBreakpoint &&
        MediaQuery.sizeOf(context).width >= AppBreakpoints.mobileWidth) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final resolvedTitle = appTitle ?? l10n?.appName ?? 'Scale Buddy';
    final resolvedSubtitle = subtitle ?? '';
    final resolvedSemantics = semanticsLabel ?? resolvedSubtitle;

    return Semantics(
      container: true,
      label: resolvedSemantics,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                resolvedTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                resolvedSubtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8), // slate-400
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              statusPill,
            ],
          ),
        ),
      ),
    );
  }
}

/// Einheitliche Kapselung für die Status-Pillen mit abgerundetem Rahmen,
/// dezentem Glow/Schatten und Screen-Reader-LiveRegion.
class MobileStatusPillContainer extends StatelessWidget {
  final String semanticsLabel;
  final Color backgroundColor;
  final Color borderColor;
  final Color? shadowColor;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const MobileStatusPillContainer({
    super.key,
    required this.semanticsLabel,
    required this.backgroundColor,
    required this.borderColor,
    this.shadowColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: semanticsLabel,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Wiederverwendbarer Punkt-Indikator für Mehrschritt-Fortschritt
/// (z. B. 2 Referenzpunkte oder 4 Ecken).
class StatusDotIndicator extends StatelessWidget {
  final bool isActive;
  final EdgeInsetsGeometry margin;
  final bool useBorderWhenInactive;

  const StatusDotIndicator({
    super.key,
    required this.isActive,
    this.margin = const EdgeInsets.only(right: 5),
    this.useBorderWhenInactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? const Color(0xFF38BDF8) // cyan
            : (useBorderWhenInactive
                  ? Colors.transparent
                  : const Color(0xFF475569)),
        border: isActive || !useBorderWhenInactive
            ? null
            : Border.all(color: const Color(0xFF475569), width: 1.5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}
