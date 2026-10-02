// Scratch file for hit testing
import 'dart:math';
import 'package:flutter/material.dart';

class HitTestUtils {
  static bool isPointNearLine(Offset p, Offset l1, Offset l2, double threshold) {
    final lineMag = (l2 - l1).distance;
    if (lineMag == 0) return (p - l1).distance <= threshold;

    final u = (((p.dx - l1.dx) * (l2.dx - l1.dx)) + ((p.dy - l1.dy) * (l2.dy - l1.dy))) / (lineMag * lineMag);

    if (u < 0.0 || u > 1.0) return false; // Closest point does not fall within the line segment

    final intersection = Offset(l1.dx + u * (l2.dx - l1.dx), l1.dy + u * (l2.dy - l1.dy));
    final distance = (p - intersection).distance;

    return distance <= threshold;
  }

  static bool isPointInPolygon(Offset p, List<Offset> poly) {
    bool c = false;
    int i, j = 0;
    for (i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      if (((poly[i].dy > p.dy) != (poly[j].dy > p.dy)) &&
          (p.dx < (poly[j].dx - poly[i].dx) * (p.dy - poly[i].dy) / (poly[j].dy - poly[i].dy) + poly[i].dx)) {
        c = !c;
      }
    }
    return c;
  }

  static bool isPointInRect(Offset p, Offset r1, Offset r2) {
    final minX = min(r1.dx, r2.dx);
    final maxX = max(r1.dx, r2.dx);
    final minY = min(r1.dy, r2.dy);
    final maxY = max(r1.dy, r2.dy);
    return p.dx >= minX && p.dx <= maxX && p.dy >= minY && p.dy <= maxY;
  }
}
