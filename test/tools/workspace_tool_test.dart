import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scale_buddy/tools/workspace_tool.dart';

class _TestTool extends WorkspaceTool {
  const _TestTool();
}

void main() {
  group('WorkspaceTool (Base Class)', () {
    const tool = _TestTool();
    const size = Size(100, 100);

    test('normalizePosition correctly normalizes within bounds', () {
      final point = tool.normalizePosition(const Offset(50, 50), size);
      expect(point, const Offset(0.5, 0.5));
    });

    test('normalizePosition allows negative values', () {
      final point = tool.normalizePosition(const Offset(-10, -50), size);
      expect(point, const Offset(-0.1, -0.5));
    });

    test('normalizePosition allows values greater than 1.0', () {
      final point = tool.normalizePosition(const Offset(110, 250), size);
      expect(point, const Offset(1.1, 2.5));
    });

    test('normalizePosition handles zero size without crashing', () {
      final point = tool.normalizePosition(const Offset(50, 50), Size.zero);
      expect(point, Offset.zero);
    });
  });
}
