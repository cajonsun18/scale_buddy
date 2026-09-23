import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/loaded_image_info.dart';
import '../services/image_loader_service.dart';

/// Der Controller, der als "Gehirn" für die Arbeitsfläche fungiert.
/// Er merkt sich das geladene Bild, den Ladezustand und Statusnachrichten.
/// Jedes Mal, wenn sich etwas ändert, ruft er [notifyListeners] auf.
class WorkspaceController extends ChangeNotifier {
  LoadedImageInfo? _loadedImage;
  bool _isLoading = false;
  String? _statusMessage;

  // Sogenannte "Getter", damit Widgets die Daten lesen, aber nicht heimlich verändern können.
  LoadedImageInfo? get loadedImage => _loadedImage;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;

  /// Entfernt das aktuelle Bild
  void clearImage() {
    _loadedImage = null;
    _statusMessage = 'Bild entfernt.';
    notifyListeners();
  }

  /// Zentrale Hilfsfunktion für alle Lade-Aktionen
  Future<void> _performImageLoad(
    Future<LoadedImageInfo?> Function() loaderAction,
    String successPrefix,
    String failureMessage,
  ) async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners(); // Sagt der UI: Zeig den Lade-Kringel!

    try {
      final info = await loaderAction();
      if (info != null) {
        _loadedImage = info;
        _statusMessage = '$successPrefix: ${info.fileName}';
      } else {
        _statusMessage = failureMessage;
      }
    } catch (e) {
      _statusMessage = 'Fehler beim Laden: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Sagt der UI: Lade-Kringel weg, Bild/Text zeigen!
    }
  }

  // --- Die konkreten Aktionen (früher in step_detail_view.dart) ---

  void loadFromPicker() => _performImageLoad(
        () => ImageLoaderService.pickImageFromFile(),
        'Geladen',
        'Auswahl abgebrochen.',
      );

  void loadSample() => _performImageLoad(
        () => ImageLoaderService.generateSampleFloorPlan(),
        'Beispielplan geladen',
        'Fehler beim Laden des Beispiels.',
      );

  void pasteFromClipboard() => _performImageLoad(
        () => ImageLoaderService.pasteFromClipboard(),
        'Aus Zwischenablage eingefügt',
        'Kein Bild gefunden. Tipp: Bilddatei im Explorer kopieren.',
      );

  void handleDroppedBytes(List<Uint8List> chunks) {
    if (chunks.isEmpty) return;
    final combined = chunks.length == 1
        ? chunks.first
        : (() {
            final builder = BytesBuilder(copy: false);
            for (final c in chunks) {
              builder.add(c);
            }
            return builder.toBytes();
          })();
    
    _performImageLoad(
      () => ImageLoaderService.loadFromBytes(combined),
      'Per Drag-and-Drop geladen',
      'Bild konnte nicht gelesen werden.',
    );
  }

  void handleDroppedFilePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      for (final p in paths) {
        final ext = p.toLowerCase();
        final looksLikeImage = ['.png', '.jpg', '.jpeg', '.bmp', '.webp', '.gif'].any(ext.endsWith);
        if (!looksLikeImage) continue;
        
        final file = File(p);
        if (!await file.exists()) continue;
        
        final bytes = await file.readAsBytes();
        final info = await ImageLoaderService.loadFromBytes(
          bytes,
          fileName: p.split(Platform.pathSeparator).last,
        );
        
        if (info != null) {
          _loadedImage = info;
          _statusMessage = 'Per Drag-and-Drop geladen: ${info.fileName}';
          return;
        }
      }
      _statusMessage = 'Drag-and-Drop: Keine Bilddatei gefunden.';
    } catch (e) {
      _statusMessage = 'Fehler beim Lesen der Datei: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
