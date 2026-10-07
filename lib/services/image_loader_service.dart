import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

import '../models/loaded_image_info.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageLoaderServiceProvider = Provider<ImageLoaderService>(
  (ref) => ImageLoaderService(),
);

/// Hilfsklasse zum Laden und Erzeugen von Bauzeichnungen.
class MockBlueprintColors {
  static const background = Color(0xFFF8FAFC);
  static const gridLines = Color(0xFFE2E8F0);
  static const textDark = Color(0xFF0F172A);
  static const textLight = Color(0xFF64748B);
  static const wallDark = Color(0xFF1E293B);
  static const wallLight = Color(0xFFF1F5F9);
  static const wallOutline = Color(0xFF334155);
  static const measureLine = Color(0xFFDC2626);
  static const secondaryText = Color(0xFF475569);
}

class ImageLoaderService {
  Future<LoadedImageInfo?> loadFromPaths(List<String> paths) async {
    for (final p in paths) {
      final ext = p.toLowerCase();
      final looksLikeImage = [
        '.png',
        '.jpg',
        '.jpeg',
        '.bmp',
        '.webp',
        '.gif',
      ].any((e) => ext.endsWith(e));
      if (!looksLikeImage) continue;

      final file = File(p);
      if (!await file.exists()) continue;

      final bytes = await file.readAsBytes();
      final info = await loadFromBytes(
        bytes,
        fileName: p.split(Platform.pathSeparator).last,
      );
      if (info != null) return info;
    }
    return null;
  }

  static const List<String> _kAllowedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'bmp',
    'webp',
    'gif',
  ];

  /// Öffnet den systemweiten Dateidialog zur Auswahl einer Bilddatei.
  ///
  /// Wird vom "Datei laden"-Button in [StepDetailView] aufgerufen.
  Future<LoadedImageInfo?> pickImageFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _kAllowedExtensions,
        windowsOptions: const WindowsOptions(lockParentWindow: true),
      );

      if (result.isEmpty) {
        return null;
      }

      final file = result.first;
      final bytes = await file.readAsBytes();

      return await _buildFromBytes(
        bytes: bytes,
        pathFallback: file.path,
        fileName: file.name,
      );
    } catch (e) {
      debugPrint('Fehler beim Laden der Datei (pickFiles): $e');
      return null;
    }
  }

  /// Lädt ein Bild aus rohen Bytes (z. B. aus Drag-and-Drop).
  ///
  /// [fileName] ist optional und wird als Anzeigename verwendet.
  Future<LoadedImageInfo?> loadFromBytes(Uint8List bytes, {String? fileName}) {
    return _buildFromBytes(
      bytes: bytes,
      pathFallback: null,
      fileName: fileName,
    );
  }

  /// Liest ein Bild aus der Zwischenablage.
  ///
  /// Vorgehensweise (Plattform-spezifisch):
  ///  1. Versuche, einen Dateipfad aus `Clipboard.kTextPlain` zu lesen und
  ///     die Datei von dort zu laden (funktioniert z. B. wenn ein Datei-Pfad
  ///     aus dem Explorer kopiert wurde).
  ///  2. Andernfalls wird `null` zurückgegeben und der Aufrufer kann
  ///     eine passende Fehlermeldung anzeigen.
  ///
  /// Hinweis: Für "echtes" Bild-Paste aus der Zwischenablage kann auf
  /// Desktop-Plattformen optional das Paket `pasteboard` eingebunden
  /// werden â€“ die API hier ist plattformneutral gehalten.
  Future<LoadedImageInfo?> pasteFromClipboard() async {
    try {
      // Variante 1: Richtiges Bild (Bytes) in der Zwischenablage
      // z.B. wenn man einen Screenshot mit dem Snipping Tool macht.
      final Uint8List? imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        return await _buildFromBytes(
          bytes: imageBytes,
          fileName: 'Aus_Zwischenablage_eingefügt.png',
        );
      }

      // Variante 2: Jemand hat eine Datei im Windows-Explorer kopiert (Dateipfad)
      final List<String> files = await Pasteboard.files();
      if (files.isNotEmpty) {
        for (final text in files) {
          final ext = _extensionOf(text).toLowerCase();
          if (_kAllowedExtensions.contains(ext)) {
            final file = File(text);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              return await _buildFromBytes(
                bytes: bytes,
                pathFallback: file.path,
                fileName: file.uri.pathSegments.isNotEmpty
                    ? file.uri.pathSegments.last
                    : file.path,
              );
            }
          }
        }
      }

      // Variante 3 (Fallback): Normaler Text, der vielleicht ein Pfad ist
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      final String? text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        final ext = _extensionOf(text).toLowerCase();
        if (_kAllowedExtensions.contains(ext)) {
          final file = File(text);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            return await _buildFromBytes(
              bytes: bytes,
              pathFallback: file.path,
              fileName: file.uri.pathSegments.isNotEmpty
                  ? file.uri.pathSegments.last
                  : file.path,
            );
          }
        }
      }

      debugPrint(
        'Kein Bild in der Zwischenablage gefunden (kein Pfad, kein Binärbild).',
      );
      return null;
    } catch (e) {
      debugPrint('Fehler beim Lesen der Zwischenablage: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Interne Helfer
  // ---------------------------------------------------------------------------

  Future<LoadedImageInfo?> _buildFromBytes({
    Uint8List? bytes,
    String? pathFallback,
    String? fileName,
  }) async {
    Uint8List? data = bytes;
    if (data == null && pathFallback != null) {
      try {
        data = await File(pathFallback).readAsBytes();
      } catch (e) {
        debugPrint('Datei konnte nicht gelesen werden: $pathFallback ($e)');
        return null;
      }
    }

    if (data == null || data.isEmpty) {
      return null;
    }

    try {
      final decoded = await decodeImageFromList(data);
      return LoadedImageInfo(
        fileName: fileName ?? 'Bild_${DateTime.now().millisecondsSinceEpoch}',
        filePath: pathFallback,
        bytes: data,
        width: decoded.width,
        height: decoded.height,
        fileSizeBytes: data.lengthInBytes,
      );
    } catch (e) {
      debugPrint('Bild konnte nicht dekodiert werden: $e');
      return null;
    }
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1);
  }

  /// Erzeugt programmgesteuert einen hochauflösenden Beispiel-Bauplan (1400 Ã— 900 px).
  ///
  /// Enthält Außenwände, Innenräume (Wohnen, Schlafen, Bad, Küche), Maßketten
  /// und eine 5,00-Meter-Referenzlinie zum sofortigen Testen der Kalibrierung.
  Future<LoadedImageInfo> generateSampleFloorPlan() async {
    const width = 1400;
    const height = 900;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // 1. Hintergrund (helles Architektur-Planpapier mit dezentem Raster)
    final bgPaint = Paint()..color = MockBlueprintColors.background;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = MockBlueprintColors.gridLines
      ..strokeWidth = 1.0;

    for (double x = 0; x < width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, height.toDouble()), gridPaint);
    }
    for (double y = 0; y < height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(width.toDouble(), y), gridPaint);
    }

    // 2. Plankopf oben
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: 'BEISPIEL-GRUNDRISS: EINFAMILIENHAUS EG',
      style: TextStyle(
        color: MockBlueprintColors.textDark,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(60, 45));

    textPainter.text = const TextSpan(
      text: 'Maßstab 1:100 • Entwurfsplanung • ScaleBuddy Testzeichnung',
      style: TextStyle(color: MockBlueprintColors.textLight, fontSize: 13),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(60, 78));

    // 3. Außenwände (Dunkle starke Linien)
    const houseX = 140.0;
    const houseY = 160.0;
    const houseW = 1000.0;
    const houseH = 600.0;

    final outerWallPaint = Paint()
      ..color = MockBlueprintColors.wallDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;

    final wallFillPaint = Paint()
      ..color = MockBlueprintColors.wallLight
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(houseX, houseY, houseW, houseH),
      wallFillPaint,
    );
    canvas.drawRect(
      const Rect.fromLTWH(houseX, houseY, houseW, houseH),
      outerWallPaint,
    );

    // 4. Innenwände (Mitteldicke Linien)
    final innerWallPaint = Paint()
      ..color = MockBlueprintColors.wallOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    // Trennwand vertikal (Wohnzimmer links, Schlafen/Bad rechts)
    canvas.drawLine(
      const Offset(houseX + 540, houseY),
      const Offset(houseX + 540, houseY + houseH),
      innerWallPaint,
    );
    // Trennwand horizontal rechts oben (Schlafen oben, Küche/Bad unten)
    canvas.drawLine(
      const Offset(houseX + 540, houseY + 300),
      const Offset(houseX + houseW, houseY + 300),
      innerWallPaint,
    );
    // Trennwand Bad / Küche
    canvas.drawLine(
      const Offset(houseX + 780, houseY + 300),
      const Offset(houseX + 780, houseY + houseH),
      innerWallPaint,
    );

    // 5. Raumbezeichnungen
    _drawRoomLabel(
      canvas,
      'WOHNEN / ESSEN\n32.4 mÂ²',
      houseX + 270,
      houseY + 300,
    );
    _drawRoomLabel(canvas, 'SCHLAFEN\n18.5 mÂ²', houseX + 770, houseY + 150);
    _drawRoomLabel(canvas, 'KÜCHE\n14.2 mÂ²', houseX + 660, houseY + 450);
    _drawRoomLabel(canvas, 'BAD / WC\n8.6 mÂ²', houseX + 890, houseY + 450);

    // 6. Referenz-Maßkette unten (Ideal für Kalibrierung)
    final dimLinePaint = Paint()
      ..color = MockBlueprintColors
          .measureLine // Rote Maßlinie
      ..strokeWidth = 2.5;

    const dimY = houseY + houseH + 50;
    canvas.drawLine(
      const Offset(houseX, dimY),
      const Offset(houseX + houseW, dimY),
      dimLinePaint,
    );
    // Maßstriche
    canvas.drawLine(
      const Offset(houseX, dimY - 12),
      const Offset(houseX, dimY + 12),
      dimLinePaint,
    );
    canvas.drawLine(
      const Offset(houseX + houseW, dimY - 12),
      const Offset(houseX + houseW, dimY + 12),
      dimLinePaint,
    );

    // Maßketten-Beschriftung
    textPainter.text = const TextSpan(
      text: 'â—„  REFERENZMASS: 10,00 m  â–º',
      style: TextStyle(
        color: MockBlueprintColors.measureLine,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(houseX + (houseW - textPainter.width) / 2, dimY - 10),
    );

    // Maßkette links (Höhe: 6,00 m)
    const dimX = houseX - 40;
    canvas.drawLine(
      const Offset(dimX, houseY),
      const Offset(dimX, houseY + houseH),
      dimLinePaint,
    );
    canvas.drawLine(
      const Offset(dimX - 12, houseY),
      const Offset(dimX + 12, houseY),
      dimLinePaint,
    );
    canvas.drawLine(
      const Offset(dimX - 12, houseY + houseH),
      const Offset(dimX + 12, houseY + houseH),
      dimLinePaint,
    );

    // Bild rendern und in PNG-Bytes umwandeln
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return LoadedImageInfo(
      fileName: 'Muster_Grundriss_EG.png',
      filePath: null,
      bytes: bytes,
      width: width,
      height: height,
      fileSizeBytes: bytes.lengthInBytes,
    );
  }

  void _drawRoomLabel(Canvas canvas, String text, double cx, double cy) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: MockBlueprintColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(cx - painter.width / 2, cy - painter.height / 2),
    );
  }
}
