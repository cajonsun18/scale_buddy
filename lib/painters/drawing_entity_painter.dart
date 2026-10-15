import 'dart:math';

import 'package:flutter/material.dart';

import '../models/entities/drawing_entity.dart';
import '../models/workflow_step.dart';
import '../utils/calibration_input_utils.dart';
import '../utils/geometry_utils.dart';

class PaintContext {
  final WorkflowStepType activeStep;
  final Color primaryColor;
  final Color successColor;
  final Color pointColor;
  final String? selectedEntityId;
  final bool isMobile;

  PaintContext({
    required this.activeStep,
    required this.primaryColor,
    required this.successColor,
    required this.pointColor,
    this.selectedEntityId,
    this.isMobile = false,
  });

  double getStrokeWidth(String id) => id == selectedEntityId ? 4.0 : 2.0;
}

/// Wiederverwendbare Hilfsklasse zum Zeichnen von interaktiven Kontrollpunkten/Anfassern (Handles).
class HandlePainter {
  /// Zeichnet einen Standard-Kontrollpunkt / Anfasser (Kreis mit Füllung und Rahmen).
  static void drawStandard(
    Canvas canvas,
    Offset center, {
    double radius = 5.0,
    required Color fillColor,
    required Color borderColor,
    double borderWidth = 2.0,
  }) {
    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paintFill);
    canvas.drawCircle(center, radius, paintBorder);
  }

  /// Zeichnet eine Liste von Standard-Anfassern.
  static void drawStandardList(
    Canvas canvas,
    Iterable<Offset> points, {
    double radius = 5.0,
    required Color fillColor,
    required Color borderColor,
    double borderWidth = 2.0,
  }) {
    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, radius, paintFill);
      canvas.drawCircle(p, radius, paintBorder);
    }
  }

  /// Zeichnet einen mobilen Kontrollpunkt / Anfasser (mit Außenring, optionaler Halo-Aura und weißem Innenkern).
  static void drawMobile(
    Canvas canvas,
    Offset center, {
    required Color strokeColor,
    double innerRadius = 5.0,
    double outerRadius = 9.0,
    Color innerFillColor = Colors.white,
    Color? outerRingColor,
    bool drawHalo = false,
  }) {
    final ringColor = outerRingColor ?? strokeColor;
    if (drawHalo) {
      final paintHalo = Paint()
        ..color = ringColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, outerRadius + 4.0, paintHalo);
    }

    final paintOuterRing = Paint()
      ..color = ringColor.withValues(alpha: 0.35)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerRadius, paintOuterRing);

    final paintInnerFill = Paint()
      ..color = innerFillColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, paintInnerFill);

    final paintInnerBorder = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerRadius, paintInnerBorder);
  }
}

abstract class DrawingEntityPainter<T extends DrawingEntity> {
  const DrawingEntityPainter();
  bool isVisibleInStep(WorkflowStepType step);
  void paint(Canvas canvas, Size size, T entity, PaintContext context);
}

class CalibrationPainter extends DrawingEntityPainter<CalibrationEntity> {
  const CalibrationPainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.calibrate;

  @override
  void paint(
    Canvas canvas,
    Size size,
    CalibrationEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    if (!context.isMobile) {
      // Desktop-Rendering (unverändert beibehalten)
      final color = entity.isConfirmed
          ? context.successColor
          : context.primaryColor;
      final paintLine = Paint()
        ..color = color
        ..strokeWidth = context.getStrokeWidth(entity.id)
        ..strokeCap = StrokeCap.round;

      final p1Pixel = p1?.toPixel(size);
      final p2Pixel = p2?.toPixel(size);

      if (p1Pixel != null && p2Pixel != null) {
        canvas.drawLine(p1Pixel, p2Pixel, paintLine);
      }

      if (p1Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p1Pixel,
          fillColor: context.pointColor,
          borderColor: color,
        );
      }
      if (p2Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p2Pixel,
          fillColor: context.pointColor,
          borderColor: color,
        );
      }
      return;
    }

    // --- MOBIL-RENDERING (Schritt 3) ---
    final strokeColor = entity.isConfirmed
        ? const Color(0xFF10B981) // Smaragdgrün (#10B981)
        : const Color(0xFF38BDF8); // Cyan (#38BDF8)

    final p1Pixel = p1?.toPixel(size);
    final p2Pixel = p2?.toPixel(size);

    // 1. Bemaßungslinie & T-Abschlüsse & Wert-Badge (sobald beide Punkte existieren)
    if (p1Pixel != null && p2Pixel != null) {
      final paintLine = Paint()
        ..color = strokeColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      // Verbindungslinie
      canvas.drawLine(p1Pixel, p2Pixel, paintLine);

      // Rechtwinklige T-Abschlüsse (Querabschlüsse / Bemaßungsbegrenzer nur im Kalibrierschritt)
      if (context.activeStep == WorkflowStepType.calibrate) {
        final vec = p2Pixel - p1Pixel;
        final distance = vec.distance;
        if (distance > 0) {
          final normal = Offset(-vec.dy / distance, vec.dx / distance);
          const tBarHalfLength = 16.0;

          // T-Abschluss an Punkt 1
          canvas.drawLine(
            p1Pixel - normal * tBarHalfLength,
            p1Pixel + normal * tBarHalfLength,
            paintLine,
          );

          // T-Abschluss an Punkt 2
          canvas.drawLine(
            p2Pixel - normal * tBarHalfLength,
            p2Pixel + normal * tBarHalfLength,
            paintLine,
          );
        }
      }

      // Mittiges Kapsel-Wert-Badge auf der Linie
      _drawMeasurementBadge(
        canvas: canvas,
        size: size,
        p1: p1Pixel,
        p2: p2Pixel,
        entity: entity,
        strokeColor: strokeColor,
      );
    }

    // 2. Punkt-Marker & Labels
    if (p1Pixel != null) {
      HandlePainter.drawMobile(
        canvas,
        p1Pixel,
        strokeColor: strokeColor,
        drawHalo: context.activeStep == WorkflowStepType.calibrate,
      );

      if (!entity.isConfirmed) {
        _drawPointLabel(canvas, size, p1Pixel, 1);
      }
    }

    if (p2Pixel != null) {
      HandlePainter.drawMobile(
        canvas,
        p2Pixel,
        strokeColor: strokeColor,
        drawHalo: context.activeStep == WorkflowStepType.calibrate,
      );

      if (!entity.isConfirmed) {
        _drawPointLabel(canvas, size, p2Pixel, 2);
      }
    }
  }

  void _drawMeasurementBadge({
    required Canvas canvas,
    required Size size,
    required Offset p1,
    required Offset p2,
    required CalibrationEntity entity,
    required Color strokeColor,
  }) {
    String badgeText;
    final unit = entity.selectedUnit;
    if (entity.enteredDistance != null && entity.enteredDistance! > 0) {
      final dist = entity.enteredDistance!;
      final formatted = CalibrationInputUtils.formatDistance(
        dist,
        useComma: true,
        decimalPlaces: 2,
      );
      badgeText = entity.isConfirmed
          ? '✓ $formatted $unit'
          : '$formatted $unit';
    } else {
      badgeText = entity.isConfirmed ? '✓ -- $unit' : '-- $unit';
    }

    final textSpan = TextSpan(
      text: badgeText,
      style: TextStyle(
        color: entity.isConfirmed ? const Color(0xFF6EE7B7) : Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const badgePaddingH = 12.0;
    const badgePaddingV = 6.0;
    final badgeWidth = textPainter.width + (badgePaddingH * 2);
    final badgeHeight = textPainter.height + (badgePaddingV * 2);

    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final badgeRect = Rect.fromCenter(
      center: mid,
      width: badgeWidth,
      height: badgeHeight,
    );
    final badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(16),
    );

    // Schatten
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(badgeRRect.shift(const Offset(0, 2)), shadowPaint);

    // Dunkler Kapsel-Hintergrund
    final bgPaint = Paint()
      ..color = entity.isConfirmed
          ? const Color(0xFF064E3B).withValues(alpha: 0.95) // emerald-900
          : const Color(0xFF0F172A).withValues(alpha: 0.95) // slate-900
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, bgPaint);

    // Rahmen (Cyan oder Smaragdgrün)
    final borderPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(badgeRRect, borderPaint);

    // Text zentriert
    final textOffset = Offset(
      badgeRect.left + badgePaddingH,
      badgeRect.top + badgePaddingV,
    );
    textPainter.paint(canvas, textOffset);
  }

  void _drawPointLabel(Canvas canvas, Size size, Offset point, int index) {
    final textSpan = TextSpan(
      text: 'Punkt $index',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Standardmäßig links vom Punkt platzieren (wie in Design-Mockups)
    double labelX = point.dx - textPainter.width - 14;
    double labelY = point.dy - (textPainter.height / 2);

    // Falls links zu wenig Platz ist (< 4), rechts platzieren
    if (labelX < 4) {
      labelX = point.dx + 14;
    }
    // Verhindern, dass Label aus dem rechten/oberen/unteren Canvas ragt
    if (labelX + textPainter.width > size.width - 4) {
      labelX = size.width - textPainter.width - 4;
    }
    if (labelY < 4) {
      labelY = 4;
    }
    if (labelY + textPainter.height > size.height - 4) {
      labelY = size.height - textPainter.height - 4;
    }

    textPainter.paint(canvas, Offset(labelX, labelY));
  }
}

class LinePainter extends DrawingEntityPainter<LineEntity> {
  const LinePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    LineEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    if (!context.isMobile) {
      final paintLine = Paint()
        ..color = entity.color
        ..strokeWidth = context.getStrokeWidth(entity.id)
        ..strokeCap = StrokeCap.round;

      final p1Pixel = p1?.toPixel(size);
      final p2Pixel = p2?.toPixel(size);

      if (p1Pixel != null && p2Pixel != null) {
        canvas.drawLine(p1Pixel, p2Pixel, paintLine);
      }

      if (p1Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p1Pixel,
          fillColor: context.pointColor,
          borderColor: entity.color,
        );
      }
      if (p2Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p2Pixel,
          fillColor: context.pointColor,
          borderColor: entity.color,
        );
      }
      return;
    }

    // --- MOBIL-RENDERING (Schritt 4: Messwerkzeuge) ---
    final p1Pixel = p1?.toPixel(size);
    final p2Pixel = p2?.toPixel(size);

    // Zustand 2: 1. Punkt gesetzt, 2. Punkt ausstehend
    if (p1Pixel != null && p2Pixel == null) {
      // Startpunkt: weißer Rand, blauer Kern, Aura
      HandlePainter.drawMobile(
        canvas,
        p1Pixel,
        strokeColor: Colors.white,
        innerFillColor: const Color(0xFF0284C7),
        outerRingColor: const Color(0xFF38BDF8),
        drawHalo: true,
      );

      // Schwebendes Hinweisschild ▪ Startpunkt
      _drawTooltipBadge(
        canvas: canvas,
        size: size,
        anchor: p1Pixel,
        text: '▪ Startpunkt',
        backgroundColor: const Color(0xFF0284C7),
        borderColor: const Color(0xFF38BDF8),
        textColor: Colors.white,
      );

      // Dezenter gestrichelter Kreis mit Label „Tippe Punkt 2“
      final ghostOffset = _calculateGhostPosition(p1Pixel, size);
      _drawDashedCircle(
        canvas,
        ghostOffset,
        radius: 9.0,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
      );
      _drawTooltipBadge(
        canvas: canvas,
        size: size,
        anchor: ghostOffset,
        text: 'Tippe Punkt 2',
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderColor: const Color(0xFF38BDF8),
        textColor: const Color(0xFF38BDF8),
      );
      return;
    }

    // Zustand 3: Strecke abgeschlossen (Cyan #38BDF8)
    if (p1Pixel != null && p2Pixel != null) {
      final cyan = entity.color;
      final paintLine = Paint()
        ..color = cyan
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1Pixel, p2Pixel, paintLine);

      final isSelected = entity.id == context.selectedEntityId;

      // Bemaßungs-Endpunkte
      HandlePainter.drawMobile(
        canvas,
        p1Pixel,
        strokeColor: cyan,
        innerFillColor: Colors.white,
        drawHalo: isSelected,
      );
      HandlePainter.drawMobile(
        canvas,
        p2Pixel,
        strokeColor: cyan,
        innerFillColor: Colors.white,
        drawHalo: isSelected,
      );
    }
  }
}

class PolygonPainter extends DrawingEntityPainter<PolygonEntity> {
  const PolygonPainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    PolygonEntity entity,
    PaintContext context,
  ) {
    if (entity.points.isEmpty) return;

    if (!context.isMobile) {
      final paintLine = Paint()
        ..color = entity.color
        ..strokeWidth = context.getStrokeWidth(entity.id)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final paintFill = Paint()
        ..color = entity.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final pixelPoints = entity.points.toPixels(size);
      final path = Path()..moveTo(pixelPoints.first.dx, pixelPoints.first.dy);

      for (int i = 1; i < pixelPoints.length; i++) {
        path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
      }

      if (entity.isClosed) {
        path.close();
        canvas.drawPath(path, paintFill);
      }

      canvas.drawPath(path, paintLine);

      HandlePainter.drawStandardList(
        canvas,
        pixelPoints,
        fillColor: context.pointColor,
        borderColor: entity.color,
      );
      return;
    }

    // --- MOBIL-RENDERING (Schritt 4: Polygon) ---
    final pixelPoints = entity.points.toPixels(size);
    final purple = entity.color;

    // Zustand 2: Noch nicht abgeschlossen
    if (!entity.isClosed) {
      if (pixelPoints.length == 1) {
        HandlePainter.drawMobile(
          canvas,
          pixelPoints.first,
          strokeColor: Colors.white,
          innerFillColor: const Color(0xFF0284C7),
          outerRingColor: purple,
          drawHalo: true,
        );

        _drawTooltipBadge(
          canvas: canvas,
          size: size,
          anchor: pixelPoints.first,
          text: '▪ Startpunkt',
          backgroundColor: const Color(0xFF0284C7),
          borderColor: const Color(0xFF38BDF8),
          textColor: Colors.white,
        );

        final ghostOffset = _calculateGhostPosition(pixelPoints.first, size);
        _drawDashedCircle(
          canvas,
          ghostOffset,
          radius: 9.0,
          color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
        );
        _drawTooltipBadge(
          canvas: canvas,
          size: size,
          anchor: ghostOffset,
          text: 'Tippe Punkt 2',
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderColor: const Color(0xFF38BDF8),
          textColor: const Color(0xFF38BDF8),
        );
        return;
      }

      // Bei >= 2 Punkten: Konturlinien zeichnen
      final paintLine = Paint()
        ..color = purple
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
      for (int i = 1; i < pixelPoints.length; i++) {
        path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
      }
      canvas.drawPath(path, paintLine);

      // Alle bisherigen Eckpunkte mit HandlePainter.drawMobile
      for (int i = 0; i < pixelPoints.length; i++) {
        final isFirst = i == 0;
        HandlePainter.drawMobile(
          canvas,
          pixelPoints[i],
          strokeColor: isFirst ? Colors.white : purple,
          innerFillColor: isFirst ? const Color(0xFF0284C7) : Colors.white,
          outerRingColor: purple,
          drawHalo: isFirst,
        );
      }
      return;
    }

    // Zustand 3: Abgeschlossenes Polygon (Lila #A855F7, 20% Transparenz)
    final paintLine = Paint()
      ..color = purple
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = purple.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
    for (int i = 1; i < pixelPoints.length; i++) {
      path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
    }
    path.close();
    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintLine);

    final isSelected = entity.id == context.selectedEntityId;

    for (final p in pixelPoints) {
      HandlePainter.drawMobile(
        canvas,
        p,
        strokeColor: purple,
        innerFillColor: Colors.white,
        drawHalo: isSelected,
      );
    }
  }
}

class RectanglePainter extends DrawingEntityPainter<RectangleEntity> {
  const RectanglePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    RectangleEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    if (!context.isMobile) {
      final paintLine = Paint()
        ..color = entity.color
        ..strokeWidth = context.getStrokeWidth(entity.id)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final paintFill = Paint()
        ..color = entity.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final p1Pixel = p1?.toPixel(size);
      final p2Pixel = p2?.toPixel(size);

      if (p1Pixel != null && p2Pixel != null) {
        final rectShape = Rect.fromPoints(p1Pixel, p2Pixel);
        canvas.drawRect(rectShape, paintFill);
        canvas.drawRect(rectShape, paintLine);
      }

      if (p1Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p1Pixel,
          fillColor: context.pointColor,
          borderColor: entity.color,
        );
      }
      if (p2Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p2Pixel,
          fillColor: context.pointColor,
          borderColor: entity.color,
        );
      }
      return;
    }

    // --- MOBIL-RENDERING (Schritt 4: Rechteck) ---
    final p1Pixel = p1?.toPixel(size);
    final p2Pixel = p2?.toPixel(size);

    // Zustand 2: 1. Punkt gesetzt, 2. Punkt ausstehend
    if (p1Pixel != null && p2Pixel == null) {
      HandlePainter.drawMobile(
        canvas,
        p1Pixel,
        strokeColor: Colors.white,
        innerFillColor: const Color(0xFF0284C7),
        outerRingColor: const Color(0xFF38BDF8),
        drawHalo: true,
      );

      _drawTooltipBadge(
        canvas: canvas,
        size: size,
        anchor: p1Pixel,
        text: '▪ Startpunkt',
        backgroundColor: const Color(0xFF0284C7),
        borderColor: const Color(0xFF38BDF8),
        textColor: Colors.white,
      );

      final ghostOffset = _calculateGhostPosition(p1Pixel, size);
      _drawDashedCircle(
        canvas,
        ghostOffset,
        radius: 9.0,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
      );
      _drawTooltipBadge(
        canvas: canvas,
        size: size,
        anchor: ghostOffset,
        text: 'Tippe Punkt 2',
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderColor: const Color(0xFF38BDF8),
        textColor: const Color(0xFF38BDF8),
      );
      return;
    }

    // Zustand 3: Rechteck aufgespannt (Smaragdgrün #10B981, 20% Transparenz)
    if (p1Pixel != null && p2Pixel != null) {
      final emerald = entity.color;
      final paintLine = Paint()
        ..color = emerald
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final paintFill = Paint()
        ..color = emerald.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill;

      final rectShape = Rect.fromPoints(p1Pixel, p2Pixel);
      canvas.drawRect(rectShape, paintFill);
      canvas.drawRect(rectShape, paintLine);

      final isSelected = entity.id == context.selectedEntityId;

      // Eckpunkte mit HandlePainter.drawMobile
      final corners = [
        rectShape.topLeft,
        rectShape.topRight,
        rectShape.bottomRight,
        rectShape.bottomLeft,
      ];
      for (final corner in corners) {
        HandlePainter.drawMobile(
          canvas,
          corner,
          strokeColor: emerald,
          innerFillColor: Colors.white,
          drawHalo: isSelected,
        );
      }
    }
  }
}

Offset _calculateGhostPosition(Offset p1, Size size) {
  double gx = p1.dx + 65.0;
  double gy = p1.dy;
  if (gx > size.width - 35) {
    gx = p1.dx - 65.0;
  }
  return Offset(gx, gy);
}

void _drawDashedCircle(
  Canvas canvas,
  Offset center, {
  required double radius,
  required Color color,
  double strokeWidth = 1.5,
  int dashCount = 12,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;

  final sweepAngle = (2 * pi) / dashCount;
  final dashAngle = sweepAngle * 0.6;
  final rect = Rect.fromCircle(center: center, radius: radius);

  for (int i = 0; i < dashCount; i++) {
    final startAngle = i * sweepAngle;
    canvas.drawArc(rect, startAngle, dashAngle, false, paint);
  }
}

void _drawTooltipBadge({
  required Canvas canvas,
  required Size size,
  required Offset anchor,
  required String text,
  required Color backgroundColor,
  required Color borderColor,
  required Color textColor,
  double verticalOffset = 20.0,
}) {
  final textSpan = TextSpan(
    text: text,
    style: TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    ),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();

  const padH = 8.0;
  const padV = 4.0;
  final width = textPainter.width + padH * 2;
  final height = textPainter.height + padV * 2;

  double left = anchor.dx - (width / 2);
  double top = anchor.dy - verticalOffset - height;

  if (left < 4) left = 4;
  if (left + width > size.width - 4) left = size.width - width - 4;
  if (top < 4) top = anchor.dy + verticalOffset;

  final rect = Rect.fromLTWH(left, top, width, height);
  final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

  // Schatten
  canvas.drawRRect(
    rrect.shift(const Offset(0, 2)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );

  // Hintergrund
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill,
  );

  // Rand
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = borderColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke,
  );

  textPainter.paint(canvas, Offset(left + padH, top + padV));
}

class AnglePainter extends DrawingEntityPainter<AngleEntity> {
  const AnglePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.measure || step == WorkflowStepType.export;

  @override
  void paint(
    Canvas canvas,
    Size size,
    AngleEntity entity,
    PaintContext context,
  ) {
    final p1 = entity.p1;
    final p2 = entity.p2;

    if (p1 == null && p2 == null) return;

    if (!context.isMobile) {
      final paintLine = Paint()
        ..color = entity.color
        ..strokeWidth = context.getStrokeWidth(entity.id)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final paintHelper = Paint()
        ..color = entity.color.withValues(alpha: 0.5)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final p1Pixel = p1?.toPixel(size);
      final p2Pixel = p2?.toPixel(size);

      if (p1Pixel != null && p2Pixel != null) {
        canvas.drawLine(p1Pixel, p2Pixel, paintLine);

        final distance = (p2Pixel - p1Pixel).distance;
        if (distance > 0) {
          final dx = p2Pixel.dx - p1Pixel.dx;
          final dy = p2Pixel.dy - p1Pixel.dy;

          final direction = dx >= 0 ? 1.0 : -1.0;
          final helperEnd = Offset(
            p1Pixel.dx + (distance * direction),
            p1Pixel.dy,
          );

          const dashWidth = 5.0;
          const dashSpace = 5.0;
          double currentX = p1Pixel.dx;
          if (direction > 0) {
            while (currentX < helperEnd.dx) {
              canvas.drawLine(
                Offset(currentX, p1Pixel.dy),
                Offset(min(currentX + dashWidth, helperEnd.dx), p1Pixel.dy),
                paintHelper,
              );
              currentX += dashWidth + dashSpace;
            }
          } else {
            while (currentX > helperEnd.dx) {
              canvas.drawLine(
                Offset(currentX, p1Pixel.dy),
                Offset(max(currentX - dashWidth, helperEnd.dx), p1Pixel.dy),
                paintHelper,
              );
              currentX -= dashWidth + dashSpace;
            }
          }

          final rect = Rect.fromCircle(center: p1Pixel, radius: distance * 0.3);
          final baseAngle = direction > 0 ? 0.0 : pi;

          final angleRad = atan2(dy, dx);
          final sweepAngle = angleRad - baseAngle;

          double normalizedSweep = sweepAngle;
          while (normalizedSweep > pi) {
            normalizedSweep -= 2 * pi;
          }
          while (normalizedSweep < -pi) {
            normalizedSweep += 2 * pi;
          }

          canvas.drawArc(rect, baseAngle, normalizedSweep, false, paintLine);

          final arrowEndX = p1Pixel.dx + cos(angleRad) * (distance * 0.3);
          final arrowEndY = p1Pixel.dy + sin(angleRad) * (distance * 0.3);

          final tangentAngle =
              angleRad + (normalizedSweep > 0 ? pi / 2 : -pi / 2);

          const arrowLength = 10.0;
          const arrowAngle = pi / 6;

          final arrowP1 = Offset(
            arrowEndX + cos(tangentAngle + pi + arrowAngle) * arrowLength,
            arrowEndY + sin(tangentAngle + pi + arrowAngle) * arrowLength,
          );
          final arrowP2 = Offset(
            arrowEndX + cos(tangentAngle + pi - arrowAngle) * arrowLength,
            arrowEndY + sin(tangentAngle + pi - arrowAngle) * arrowLength,
          );

          canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP1, paintLine);
          canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP2, paintLine);
        }
      }

      if (p1Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p1Pixel,
          fillColor: context.pointColor,
          borderColor: entity.color,
        );
      }
      if (p2Pixel != null) {
        HandlePainter.drawStandard(
          canvas,
          p2Pixel,
          fillColor: context.pointColor,
          borderColor: entity.color,
        );
      }
      return;
    }

    // --- MOBIL-RENDERING (Schritt 4: Dachwinkel) ---
    final p1Pixel = p1?.toPixel(size);
    final p2Pixel = p2?.toPixel(size);
    final amber = entity.color;

    // Zustand 2: Scheitelpunkt gesetzt, 2. Punkt ausstehend
    if (p1Pixel != null && p2Pixel == null) {
      HandlePainter.drawMobile(
        canvas,
        p1Pixel,
        strokeColor: Colors.white,
        innerFillColor: const Color(0xFF0284C7),
        outerRingColor: amber,
        drawHalo: true,
      );

      _drawTooltipBadge(
        canvas: canvas,
        size: size,
        anchor: p1Pixel,
        text: '▪ Startpunkt',
        backgroundColor: const Color(0xFF0284C7),
        borderColor: const Color(0xFF38BDF8),
        textColor: Colors.white,
      );

      final ghostOffset = _calculateGhostPosition(p1Pixel, size);
      _drawDashedCircle(
        canvas,
        ghostOffset,
        radius: 9.0,
        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
      );
      _drawTooltipBadge(
        canvas: canvas,
        size: size,
        anchor: ghostOffset,
        text: 'Tippe Punkt 2',
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderColor: const Color(0xFF38BDF8),
        textColor: const Color(0xFF38BDF8),
      );
      return;
    }

    // Zustand 3: Dachwinkel aufgespannt
    if (p1Pixel != null && p2Pixel != null) {
      final paintLine = Paint()
        ..color = amber
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final paintHelper = Paint()
        ..color = amber.withValues(alpha: 0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1Pixel, p2Pixel, paintLine);

      final distance = (p2Pixel - p1Pixel).distance;
      if (distance > 0) {
        final dx = p2Pixel.dx - p1Pixel.dx;
        final dy = p2Pixel.dy - p1Pixel.dy;

        final direction = dx >= 0 ? 1.0 : -1.0;
        final helperEnd = Offset(
          p1Pixel.dx + (distance * direction),
          p1Pixel.dy,
        );

        // Gestrichelte horizontale Referenzlinie
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        double currentX = p1Pixel.dx;
        if (direction > 0) {
          while (currentX < helperEnd.dx) {
            canvas.drawLine(
              Offset(currentX, p1Pixel.dy),
              Offset(min(currentX + dashWidth, helperEnd.dx), p1Pixel.dy),
              paintHelper,
            );
            currentX += dashWidth + dashSpace;
          }
        } else {
          while (currentX > helperEnd.dx) {
            canvas.drawLine(
              Offset(currentX, p1Pixel.dy),
              Offset(max(currentX - dashWidth, helperEnd.dx), p1Pixel.dy),
              paintHelper,
            );
            currentX -= dashWidth + dashSpace;
          }
        }

        // Winkelbogen
        final rect = Rect.fromCircle(center: p1Pixel, radius: distance * 0.3);
        final baseAngle = direction > 0 ? 0.0 : pi;

        final angleRad = atan2(dy, dx);
        final sweepAngle = angleRad - baseAngle;

        double normalizedSweep = sweepAngle;
        while (normalizedSweep > pi) {
          normalizedSweep -= 2 * pi;
        }
        while (normalizedSweep < -pi) {
          normalizedSweep += 2 * pi;
        }

        canvas.drawArc(rect, baseAngle, normalizedSweep, false, paintLine);

        // Pfeilspitze am Ende des Winkelbogens
        final arrowEndX = p1Pixel.dx + cos(angleRad) * (distance * 0.3);
        final arrowEndY = p1Pixel.dy + sin(angleRad) * (distance * 0.3);

        final tangentAngle =
            angleRad + (normalizedSweep > 0 ? pi / 2 : -pi / 2);

        const arrowLength = 9.0;
        const arrowAngle = pi / 6;

        final arrowP1 = Offset(
          arrowEndX + cos(tangentAngle + pi + arrowAngle) * arrowLength,
          arrowEndY + sin(tangentAngle + pi + arrowAngle) * arrowLength,
        );
        final arrowP2 = Offset(
          arrowEndX + cos(tangentAngle + pi - arrowAngle) * arrowLength,
          arrowEndY + sin(tangentAngle + pi - arrowAngle) * arrowLength,
        );

        canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP1, paintLine);
        canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowP2, paintLine);
      }

      final isSelected = entity.id == context.selectedEntityId;

      // Eckpunkte mit HandlePainter.drawMobile
      HandlePainter.drawMobile(
        canvas,
        p1Pixel,
        strokeColor: amber,
        innerFillColor: Colors.white,
        drawHalo: isSelected,
      );
      HandlePainter.drawMobile(
        canvas,
        p2Pixel,
        strokeColor: amber,
        innerFillColor: Colors.white,
        drawHalo: isSelected,
      );
    }
  }
}

class PerspectivePainter extends DrawingEntityPainter<PerspectiveEntity> {
  const PerspectivePainter();

  @override
  bool isVisibleInStep(WorkflowStepType step) =>
      step == WorkflowStepType.perspective;

  @override
  void paint(
    Canvas canvas,
    Size size,
    PerspectiveEntity entity,
    PaintContext context,
  ) {
    if (entity.points.isEmpty) return;

    final isMobile = context.isMobile;
    final strokeColor = isMobile ? const Color(0xFF38BDF8) : entity.color;
    final fillColor = isMobile
        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
        : entity.color.withValues(alpha: 0.2);

    final paintLine = Paint()
      ..color = strokeColor
      ..strokeWidth = isMobile ? 2.5 : context.getStrokeWidth(entity.id)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final pixelPoints = entity.points.toPixels(size);
    final path = Path()..moveTo(pixelPoints.first.dx, pixelPoints.first.dy);

    for (int i = 1; i < pixelPoints.length; i++) {
      path.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
    }

    if (pixelPoints.length == 4) {
      path.close();
      canvas.drawPath(path, paintFill);
    }

    canvas.drawPath(path, paintLine);

    // Gestrichelte Linie zur Andeutung der Schließung (bei 3 Punkten)
    if (isMobile && pixelPoints.length == 3) {
      _drawDashedLine(
        canvas,
        pixelPoints[2],
        pixelPoints.first,
        strokeColor.withValues(alpha: 0.6),
      );
    }

    // Punkte zeichnen
    for (int i = 0; i < pixelPoints.length; i++) {
      final p = pixelPoints[i];

      if (isMobile) {
        HandlePainter.drawMobile(
          canvas,
          p,
          strokeColor: strokeColor,
          drawHalo: false,
        );
        _drawCornerLabel(canvas, size, p, i + 1, entity.points);
      } else {
        HandlePainter.drawStandard(
          canvas,
          p,
          radius: 6.0,
          fillColor: Colors.white,
          borderColor: strokeColor,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double drawn = 0.0;

    while (drawn < distance) {
      final startFraction = drawn / distance;
      final endFraction = min((drawn + dashWidth) / distance, 1.0);

      canvas.drawLine(
        Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
        Offset(p1.dx + dx * endFraction, p1.dy + dy * endFraction),
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  void _drawCornerLabel(
    Canvas canvas,
    Size size,
    Offset point,
    int index,
    List<Offset> allPoints,
  ) {
    final textSpan = TextSpan(
      text: 'Ecke $index',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Positionierung mit leichtem Offset, damit es nicht direkt auf dem Punkt liegt
    double labelX = point.dx + 12;
    double labelY = point.dy + 8;

    // Verhindern, dass Label aus dem Canvas ragt
    if (labelX + textPainter.width > size.width - 4) {
      labelX = point.dx - textPainter.width - 12;
    }
    if (labelY + textPainter.height > size.height - 4) {
      labelY = point.dy - textPainter.height - 8;
    }

    textPainter.paint(canvas, Offset(labelX, labelY));
  }
}

class EntityPainterDispatcher {
  static const _calibrationPainter = CalibrationPainter();
  static const _linePainter = LinePainter();
  static const _polygonPainter = PolygonPainter();
  static const _rectanglePainter = RectanglePainter();
  static const _anglePainter = AnglePainter();
  static const _perspectivePainter = PerspectivePainter();

  static void paintEntity(
    Canvas canvas,
    Size size,
    DrawingEntity entity,
    PaintContext context,
  ) {
    final shouldDim =
        context.isMobile &&
        context.activeStep == WorkflowStepType.measure &&
        context.selectedEntityId != null &&
        context.selectedEntityId != entity.id &&
        entity is! CalibrationEntity;

    if (shouldDim) {
      canvas.saveLayer(null, Paint()..color = const Color(0x55FFFFFF));
    }

    entity.map(
      calibration: (e) {
        if (_calibrationPainter.isVisibleInStep(context.activeStep)) {
          _calibrationPainter.paint(canvas, size, e, context);
        }
      },
      line: (e) {
        if (_linePainter.isVisibleInStep(context.activeStep)) {
          _linePainter.paint(canvas, size, e, context);
        }
      },
      polygon: (e) {
        if (_polygonPainter.isVisibleInStep(context.activeStep)) {
          _polygonPainter.paint(canvas, size, e, context);
        }
      },
      rectangle: (e) {
        if (_rectanglePainter.isVisibleInStep(context.activeStep)) {
          _rectanglePainter.paint(canvas, size, e, context);
        }
      },
      angle: (e) {
        if (_anglePainter.isVisibleInStep(context.activeStep)) {
          _anglePainter.paint(canvas, size, e, context);
        }
      },
      perspective: (e) {
        if (_perspectivePainter.isVisibleInStep(context.activeStep)) {
          _perspectivePainter.paint(canvas, size, e, context);
        }
      },
    );

    if (shouldDim) {
      canvas.restore();
    }
  }
}
