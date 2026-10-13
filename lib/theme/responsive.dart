import 'package:flutter/material.dart';

/// Zentrale Responsive-Breakpoints der ScaleBuddy-Anwendung.
class AppBreakpoints {
  /// Bildschirmbreite (in dp), unterhalb derer das vereinfachte Mobil-Layout aktiv ist.
  static const double mobileWidth = 800.0;

  /// Prüft, ob die gegebene Breite im mobilen Bereich liegt.
  static bool isMobileWidth(double width) => width < mobileWidth;
}

/// Praktische BuildContext-Extensions für Responsive-Abfragen.
extension ResponsiveContext on BuildContext {
  /// Gibt `true` zurück, wenn die aktuelle Bildschirmbreite unter [AppBreakpoints.mobileWidth] liegt.
  bool get isMobile =>
      MediaQuery.sizeOf(this).width < AppBreakpoints.mobileWidth;
}
