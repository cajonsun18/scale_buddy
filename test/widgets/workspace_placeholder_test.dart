import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/workspace_placeholder.dart';

void main() {
  testWidgets('WorkspacePlaceholder renders correctly', (
    WidgetTester tester,
  ) async {
    final step = WorkflowStepData.allSteps.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: WorkspacePlaceholder(stepData: step)),
      ),
    );

    expect(find.text('Bild in den Workspace laden'), findsOneWidget);
    expect(find.byIcon(step.icon), findsOneWidget);
  });
}
