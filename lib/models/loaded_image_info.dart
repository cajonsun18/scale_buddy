import 'dart:typed_data';

/// Enthält alle Metadaten und die Bilddaten eines in ScaleBuddy geladenen Bauplans.
class LoadedImageInfo {
  /// Dateiname (z. B. "Grundriss_EG.png").
  final String fileName;

  /// Vollständiger Dateipfad auf der Festplatte (null bei Zwischenablage/Beispielplan).
  final String? filePath;

  /// Rohdaten des Bildes für die Anzeige in Flutter (`Image.memory`).
  final Uint8List bytes;

  /// Bildbreite in echten Bildpixeln.
  final int width;

  /// Bildhöhe in echten Bildpixeln.
  final int height;

  /// Dateigröße in Bytes.
  final int fileSizeBytes;

  const LoadedImageInfo({
    required this.fileName,
    this.filePath,
    required this.bytes,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
  });

  /// Gibt eine lesbare formatierte Dateigröße zurück (z. B. "1.8 MB" oder "450 KB").
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      final kb = (fileSizeBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);
      return '$mb MB';
    }
  }

  /// Gibt die Bilddimensionen formatiert zurück (z. B. "1920 × 1080 px").
  String get dimensionsText => '$width × $height px';
}
