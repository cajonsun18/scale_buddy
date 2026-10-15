import 'package:flutter/material.dart';

/// Einheitliche Farbpalette für alle Messwerkzeuge auf Desktop und Mobile.
abstract final class MeasureToolColors {
  /// Strecke / Distance Tool: Cyan (#38BDF8)
  static const Color distance = Color(0xFF38BDF8);

  /// Rechteck / Rectangle Tool: Smaragdgrün / Emerald (#10B981)
  static const Color rectangle = Color(0xFF10B981);

  /// Polygon Tool / Freiform-Fläche: Lila / Purple (#A855F7)
  static const Color polygon = Color(0xFFA855F7);

  /// Dachwinkel / Angle Tool: Bernstein / Amber (#F59E0B)
  static const Color angle = Color(0xFFF59E0B);

  /// Auswählen / Bearbeiten / Select Tool: Blau (#3B82F6)
  static const Color select = Color(0xFF3B82F6);
}
