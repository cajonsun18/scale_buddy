import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/entities/drawing_entity.dart';
import '../models/workflow_step.dart';
import '../models/workspace_state.dart';
import '../utils/geometry_utils.dart';
import '../utils/measurement_calculator.dart';
import '../painters/drawing_entity_painter.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class ExportService {
  Future<Uint8List> generateExportImage(WorkspaceState state) async {
    final imgInfo = state.loadedImage;
    if (imgInfo == null) throw Exception('No image loaded');

    final codec = await ui.instantiateImageCodec(imgInfo.bytes);
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Draw background image
    canvas.drawImage(image, Offset.zero, Paint());

    final size = Size(width, height);
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;

    final pixelsPerMeter = GeometryUtils.getPixelsPerMeter(
      size,
      calibP1: calib?.p1,
      calibP2: calib?.p2,
      calibDistance: calib?.enteredDistance,
      unit: calib?.selectedUnit ?? 'm',
    );

    final paintContext = PaintContext(
      activeStep: WorkflowStepType.export,
      primaryColor: Colors.blue,
      successColor: Colors.green,
      pointColor: Colors.white,
    );

    for (final entity in state.entities) {
      EntityPainterDispatcher.paintEntity(canvas, size, entity, paintContext);
    }

    // Draw labels on top of the image
    for (final entity in state.entities) {
      final text = MeasurementCalculator.getMeasurementText(
        entity,
        size,
        pixelsPerMeter,
      );
      final position = MeasurementCalculator.getMeasurementLabelPosition(
        entity,
        size,
      );

      if (text != null && position != null) {
        _drawLabel(
          canvas,
          position,
          text,
          entity.map(
            calibration: (_) => Colors.green,
            perspective: (_) => Colors.blue,
            line: (e) => e.color,
            rectangle: (e) => e.color,
            polygon: (e) => e.color,
            angle: (e) => e.color,
          ),
          size,
        );
      }
    }

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(image.width, image.height);
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  void _drawLabel(
    ui.Canvas canvas,
    Offset center,
    String text,
    Color color,
    Size imageSize,
  ) {
    // Scale font size based on image resolution (assume 14.0 is good for 1000px width)
    final scale = max(1.0, imageSize.width / 1000.0);
    final fontSize = 14.0 * scale;
    final paddingH = 8.0 * scale;
    final paddingV = 4.0 * scale;
    final borderRadius = 8.0 * scale;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final width = textPainter.width + paddingH * 2;
    final height = textPainter.height + paddingV * 2;

    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final bgPaint = Paint()..color = color;
    canvas.drawRRect(rrect, bgPaint);

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  Future<Uint8List> generatePdfReport(WorkspaceState state) async {
    final calib = state.entities.whereType<CalibrationEntity>().firstOrNull;
    final size = Size(
      state.loadedImage?.width.toDouble() ?? 1000,
      state.loadedImage?.height.toDouble() ?? 1000,
    );
    final pixelsPerMeter = GeometryUtils.getPixelsPerMeter(
      size,
      calibP1: calib?.p1,
      calibP2: calib?.p2,
      calibDistance: calib?.enteredDistance,
      unit: calib?.selectedUnit ?? 'm',
    );

    final imageBytes = await generateExportImage(state);

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Messbericht - ScaleBuddy',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Table of measurements
              _buildMeasurementTable(state, size, pixelsPerMeter),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildMeasurementTable(
    WorkspaceState state,
    Size size,
    double? pixelsPerMeter,
  ) {
    final data = <List<String>>[
      ['Typ', 'Wert'],
    ];

    if (pixelsPerMeter != null) {
      for (final entity in state.entities) {
        final label = MeasurementCalculator.getMeasurementTypeLabel(entity);
        final text = MeasurementCalculator.getMeasurementText(
          entity,
          size,
          pixelsPerMeter,
        );
        if (label != null && text != null) {
          data.add([label, text]);
        }
      }
    }

    if (data.length == 1) {
      return pw.Text('Keine Messungen vorhanden.');
    }

    return pw.TableHelper.fromTextArray(
      context: null,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
    );
  }
}
