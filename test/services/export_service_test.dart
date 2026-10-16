import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/services/export_service.dart';

final samplePngBytes = Uint8List.fromList([
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  11,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  96,
  0,
  2,
  0,
  0,
  5,
  0,
  1,
  226,
  38,
  5,
  155,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService', () {
    test('generateExportImage creates valid PNG bytes with customLabelOffset and leader lines', () async {
      final service = ExportService();

      final calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: const Offset(0.1, 0.1),
        p2: const Offset(0.9, 0.1),
        isConfirmed: true,
        enteredDistance: 10.0,
        selectedUnit: 'm',
      );

      final lineWithOffset = DrawingEntity.line(
        id: 'line_1',
        p1: const Offset(0.2, 0.4),
        p2: const Offset(0.6, 0.4),
        color: Colors.blue,
        customLabelOffset: const Offset(0.05, -0.05),
      );

      final rectWithOffset = DrawingEntity.rectangle(
        id: 'rect_1',
        p1: const Offset(0.3, 0.6),
        p2: const Offset(0.7, 0.8),
        color: Colors.green,
        customLabelOffset: const Offset(0.02, 0.04),
      );

      final polyWithOffset = DrawingEntity.polygon(
        id: 'poly_1',
        points: const [Offset(0.2, 0.2), Offset(0.4, 0.2), Offset(0.3, 0.5)],
        isClosed: true,
        color: Colors.purple,
        customLabelOffset: const Offset(-0.03, -0.02),
      );

      final angleNormal = DrawingEntity.angle(
        id: 'angle_1',
        p1: const Offset(0.5, 0.5),
        p2: const Offset(0.8, 0.5),
        color: Colors.orange,
      );

      final angleWithOffset = DrawingEntity.angle(
        id: 'angle_2',
        p1: const Offset(0.4, 0.4),
        p2: const Offset(0.7, 0.4),
        color: Colors.orange,
        customLabelOffset: const Offset(0.1, 0.1),
      );

      final state = WorkspaceState(
        loadedImage: LoadedImageInfo(
          fileName: 'test.png',
          fileSizeBytes: samplePngBytes.length,
          bytes: samplePngBytes,
          width: 800,
          height: 600,
        ),
        entities: [
          calib,
          lineWithOffset,
          rectWithOffset,
          polyWithOffset,
          angleNormal,
          angleWithOffset,
        ],
      );

      final resultBytes = await service.generateExportImage(state);

      expect(resultBytes, isNotNull);
      expect(resultBytes.isNotEmpty, isTrue);
      // Valid PNG header check
      expect(resultBytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    });

    test('generatePdfReport creates valid PDF document bytes', () async {
      final service = ExportService();

      final calib = DrawingEntity.calibration(
        id: 'calib_1',
        p1: const Offset(0.1, 0.1),
        p2: const Offset(0.9, 0.1),
        isConfirmed: true,
        enteredDistance: 10.0,
        selectedUnit: 'm',
      );

      final lineWithOffset = DrawingEntity.line(
        id: 'line_1',
        p1: const Offset(0.2, 0.4),
        p2: const Offset(0.6, 0.4),
        color: Colors.blue,
        customLabelOffset: const Offset(0.05, -0.05),
      );

      final state = WorkspaceState(
        loadedImage: LoadedImageInfo(
          fileName: 'test.png',
          fileSizeBytes: samplePngBytes.length,
          bytes: samplePngBytes,
          width: 800,
          height: 600,
        ),
        entities: [calib, lineWithOffset],
      );

      final pdfBytes = await service.generatePdfReport(state);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF header check "%PDF" -> [37, 80, 68, 70]
      expect(pdfBytes.sublist(0, 4), [37, 80, 68, 70]);
    });
  });
}
