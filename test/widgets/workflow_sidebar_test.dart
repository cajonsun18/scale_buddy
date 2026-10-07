import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/workflow_sidebar.dart';

void main() {
  testWidgets('WorkflowSidebar renders steps and handles interactions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    WorkflowStepType? selectedStep;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: WorkflowSidebar(
            activeStep: WorkflowStepType.file,
            stepStatuses: const {WorkflowStepType.file: StepStatus.completed},
            onStepSelected: (step) => selectedStep = step,
            isStepEnabled: (step) => true,
          ),
        ),
      ),
    );

    // Sidebar renders correctly
    expect(find.text('ARBEITSABLAUF'), findsOneWidget);
    expect(find.text('Schritt 1 von 5'), findsOneWidget);

    // Renders all steps titles
    for (final stepData in WorkflowStepData.allSteps) {
      expect(find.text(stepData.title), findsOneWidget);
    }

    // Bottom navigation
    expect(find.text('Weiter zu Schritt 2'), findsOneWidget);

    // Tap "Weiter zu Schritt 2"
    await tester.tap(find.text('Weiter zu Schritt 2'));
    expect(selectedStep, WorkflowStepType.perspective);
  });
}
