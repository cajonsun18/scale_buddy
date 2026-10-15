import 'package:flutter/services.dart';

/// Gemeinsame Validierungs-, Bereinigungs-, Formatierungs- und Konvertierungslogik
/// für Kalibrierungseingaben (sowohl Desktop-Overlay als auch mobiles Numpad-Dock).
class CalibrationInputUtils {
  /// Alle unterstützten Einheiten für die Kalibrierung.
  static const List<String> supportedUnits = ['m', 'cm', 'mm'];

  /// Standardeinheit.
  static const String defaultUnit = 'm';

  /// Prüft, ob eine gegebene Einheit gültig und unterstützt ist.
  static bool isValidUnit(String? unit) {
    return unit != null && supportedUnits.contains(unit);
  }

  /// Bereinigt und parst einen Benutzereingabe-String in eine positive Gleitkommazahl.
  ///
  /// - Entfernt führende und nachfolgende Leerzeichen (`trim`)
  /// - Ersetzt Dezimalkomma (`,`) durch Punkt (`.`)
  /// - Behandelt Vorzeichen, führende Nullen und Formatierungen
  /// - Gibt `null` zurück bei ungültigen Zeichen, Leerstrings, `0`, negativen Werten oder `NaN`/`Infinity`.
  static double? parseDistance(String? input) {
    if (input == null) return null;
    final cleaned = input.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;

    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed <= 0 || parsed.isNaN || parsed.isInfinite) {
      return null;
    }
    return parsed;
  }

  /// Prüft, ob ein gegebener Eingabestring eine gültige positive Kalibrierungsdistanz darstellt.
  static bool isValidDistance(String? input) => parseDistance(input) != null;

  /// Rechnet eine gegebene Distanz unter Berücksichtigung der Einheit ('m', 'cm', 'mm') in Meter um.
  static double? convertToMeters(double? distance, String unit) {
    if (distance == null || distance <= 0) return null;
    switch (unit) {
      case 'cm':
        return distance / 100.0;
      case 'mm':
        return distance / 1000.0;
      case 'm':
      default:
        return distance;
    }
  }

  /// Formatiert eine Zahl für die Anzeige im Eingabefeld oder Label.
  ///
  /// - [useComma]: Wenn `true`, wird `.` durch `,` ersetzt.
  /// - [decimalPlaces]: Wenn angegeben, wird auf diese Anzahl Nachkommastellen gerundet.
  ///   Falls `null`, wird `.0` am Ende entfernt (z. B. `5.0` -> `5`).
  static String formatDistance(
    double? distance, {
    bool useComma = false,
    int? decimalPlaces,
  }) {
    if (distance == null) return '';
    String formatted;
    if (decimalPlaces != null) {
      formatted = distance.toStringAsFixed(decimalPlaces);
    } else {
      formatted = distance.toString().replaceAll(RegExp(r'\.0$'), '');
    }
    if (useComma) {
      formatted = formatted.replaceAll('.', ',');
    }
    return formatted;
  }

  /// Prüft, ob ein Zeichen bei der Tastatureingabe eingefügt werden darf
  /// (Verhindert mehrfache Dezimaltrennzeichen und begrenzt die Nachkommastellen).
  static bool canInsertChar(
    String currentText,
    String char, {
    int maxDecimals = 2,
    TextSelection? selection,
  }) {
    if (char == ',' || char == '.') {
      return !currentText.contains(',') && !currentText.contains('.');
    }
    if (!RegExp(r'^[0-9]$').hasMatch(char)) {
      return false;
    }

    final sep = currentText.contains(',')
        ? ','
        : (currentText.contains('.') ? '.' : null);
    if (sep != null) {
      final parts = currentText.split(sep);
      if (parts.length > 1 && parts[1].length >= maxDecimals) {
        if (selection != null && selection.isValid && !selection.isCollapsed) {
          return true;
        }
        if (selection != null &&
            selection.isValid &&
            selection.start <= currentText.indexOf(sep)) {
          return true;
        }
        return false;
      }
    }
    return true;
  }
}
