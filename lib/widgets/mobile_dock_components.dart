import 'package:flutter/material.dart';

/// Wiederverwendbare Komponenten für schwebende mobile Aktionsleisten (Floating Docks).
///
/// Beinhaltet:
/// - [MobileDockContainer]: Kapselt das Kapsel-Styling, den dunklen Hintergrund,
///   den Rahmen, den Tiefenschatten und optionales SafeArea-Wrapping.
/// - [MobileDockButton]: Barrierefreier Aktionsbutton mit Mindest-Touch-Target von 44dp,
///   Glow-Effekten bei Primärbuttons und konfigurierbarem Styling.
/// - [MobileDockTextButton]: Dezenter Text-Button (z. B. für „Überspringen“) mit 44dp Touch-Fläche.
/// - [MobileDockDivider]: Subtiler vertikaler Trenner zwischen Dock-Elementen.
class MobileDockContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;
  final BoxDecoration? decoration;
  final bool wrapSafeAreaAndMargin;

  const MobileDockContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
    this.margin,
    this.constraints,
    this.decoration,
    this.wrapSafeAreaAndMargin = false,
  });

  /// Standard-Dekoration für mobile Docks: Kapselform mit Slate-800, Slate-700-Rahmen und Schatten.
  static BoxDecoration get defaultDecoration => BoxDecoration(
    color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate-800
    borderRadius: BorderRadius.circular(30.0), // Pillenform
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
  );

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      constraints: constraints,
      padding: padding,
      decoration: decoration ?? defaultDecoration,
      child: child,
    );

    if (wrapSafeAreaAndMargin) {
      content = SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Barrierefreier Aktionsbutton für schwebende mobile Docks mit Mindesthöhe von 44dp.
class MobileDockButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isPrimary;
  final int flex;
  final bool expanded;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double iconSpacing;
  final String? semanticsLabel;

  const MobileDockButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.isPrimary = false,
    this.flex = 1,
    this.expanded = true,
    this.onPressed,
    this.padding,
    this.iconSpacing = 6.0,
    this.semanticsLabel,
  });

  /// Factory für primäre Aktionsbuttons (Leuchtend blau mit Glow-Schatten).
  factory MobileDockButton.primary({
    Key? key,
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    int flex = 1,
    bool expanded = true,
    EdgeInsetsGeometry? padding,
    double iconSpacing = 6.0,
    String? semanticsLabel,
  }) {
    return MobileDockButton(
      key: key,
      label: label,
      icon: icon,
      iconColor: Colors.white,
      textColor: Colors.white,
      backgroundColor: const Color(0xFF2563EB),
      isPrimary: true,
      flex: flex,
      expanded: expanded,
      onPressed: onPressed,
      padding: padding,
      iconSpacing: iconSpacing,
      semanticsLabel: semanticsLabel,
    );
  }

  /// Factory für sekundäre Aktionsbuttons (Dunkler Hintergrund mit Rahmen).
  factory MobileDockButton.secondary({
    Key? key,
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    Color iconColor = const Color(0xFF94A3B8),
    Color textColor = const Color(0xFF94A3B8),
    Color borderColor = const Color(0xFF334155),
    Color backgroundColor = const Color(0xFF0F172A),
    int flex = 1,
    bool expanded = true,
    EdgeInsetsGeometry? padding,
    double iconSpacing = 6.0,
    String? semanticsLabel,
  }) {
    return MobileDockButton(
      key: key,
      label: label,
      icon: icon,
      iconColor: iconColor,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      isPrimary: false,
      flex: flex,
      expanded: expanded,
      onPressed: onPressed,
      padding: padding,
      iconSpacing: iconSpacing,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    final Widget buttonContent = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticsLabel ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22.0),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44.0),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: backgroundColor ?? const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(22.0),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 1.0)
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
                SizedBox(width: iconSpacing),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12.0,
                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
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
    );

    if (expanded) {
      return Expanded(flex: flex, child: buttonContent);
    }
    return buttonContent;
  }
}

/// Dezenter Text-Button für mobile Docks (z. B. für „Überspringen“).
///
/// Mindest-Touch-Target von 44x44 dp für Barrierefreiheit.
class MobileDockTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color textColor;
  final EdgeInsetsGeometry padding;

  const MobileDockTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = const Color(0xFF94A3B8),
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44.0, minWidth: 44.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding,
          minimumSize: const Size(44.0, 44.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Subtiler vertikaler Trennstrich zwischen Dock-Elementen.
class MobileDockDivider extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const MobileDockDivider({
    super.key,
    this.width = 1.0,
    this.height = 20.0,
    this.color = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, color: color);
  }
}
