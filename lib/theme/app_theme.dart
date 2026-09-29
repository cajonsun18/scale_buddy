import 'package:flutter/material.dart';

/// Extension für spezifische App-Farben (wie die dunkle Toolbar oder helle Sidebar),
/// die über die Standard-Material-Colors (primary, error, etc.) hinausgehen.
class AppColors extends ThemeExtension<AppColors> {
  final Color sidebarBg;
  final Color sidebarBorder;
  final Color toolbarBg;
  final Color toolbarBorder;
  final Color inputBg;
  final Color inputBorder;
  final Color success;
  final Color iconActive;
  final Color iconInactive;

  const AppColors({
    required this.sidebarBg,
    required this.sidebarBorder,
    required this.toolbarBg,
    required this.toolbarBorder,
    required this.inputBg,
    required this.inputBorder,
    required this.success,
    required this.iconActive,
    required this.iconInactive,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? sidebarBg,
    Color? sidebarBorder,
    Color? toolbarBg,
    Color? toolbarBorder,
    Color? inputBg,
    Color? inputBorder,
    Color? success,
    Color? iconActive,
    Color? iconInactive,
  }) {
    return AppColors(
      sidebarBg: sidebarBg ?? this.sidebarBg,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      toolbarBg: toolbarBg ?? this.toolbarBg,
      toolbarBorder: toolbarBorder ?? this.toolbarBorder,
      inputBg: inputBg ?? this.inputBg,
      inputBorder: inputBorder ?? this.inputBorder,
      success: success ?? this.success,
      iconActive: iconActive ?? this.iconActive,
      iconInactive: iconInactive ?? this.iconInactive,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      toolbarBg: Color.lerp(toolbarBg, other.toolbarBg, t)!,
      toolbarBorder: Color.lerp(toolbarBorder, other.toolbarBorder, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      iconActive: Color.lerp(iconActive, other.iconActive, t)!,
      iconInactive: Color.lerp(iconInactive, other.iconInactive, t)!,
    );
  }

  // Hilfsmethode für leichteren Zugriff in Widgets: AppColors.of(context).toolbarBg
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent, // Standard Primary (0xFF1E88E5 ähnlich)
        brightness: Brightness.light,
        primary: Colors.blueAccent,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate-100
      extensions: const [
        AppColors(
          sidebarBg: Color(0xFFF8FAFC),      // Slate-50
          sidebarBorder: Color(0xFFE2E8F0),  // Slate-200
          toolbarBg: Color(0xFF1E293B),      // Slate-800
          toolbarBorder: Color(0xFF334155),  // Slate-700
          inputBg: Color(0xFF0F172A),        // Slate-900
          inputBorder: Color(0xFF475569),    // Slate-600
          success: Colors.green,
          iconActive: Colors.white,
          iconInactive: Colors.white30,
        ),
      ],
    );
  }
}
