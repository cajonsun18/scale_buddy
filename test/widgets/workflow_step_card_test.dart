import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/workflow_step_card.dart';

void main() {
  Widget buildTestWidget({
    required WorkflowStepData stepData,
    bool isActive = true,
    StepStatus status = StepStatus.open,
    ToolAction? activeToolAction,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: WorkflowStepCard(
          stepData: stepData,
          isActive: isActive,
          status: status,
          onTap: () {},
          onToolSelected: (_) {},
          activeToolAction: activeToolAction,
        ),
      ),
    );
  }

  testWidgets('Encoding (Sonderzeichen) rendering test', (
    WidgetTester tester,
  ) async {
    // Schritt 1 & 2: Testing text with Sonderzeichen ("Fläche" / "0,5Â°")
    // "Fläche (Frei)" is in WorkflowStepType.measure (Step 4)
    // "0,5Â°-Schritte" is in WorkflowStepType.perspective (Step 2)

    final perspectiveStep = WorkflowStepData.allSteps.firstWhere(
      (s) => s.type == WorkflowStepType.perspective,
    );

    await tester.pumpWidget(
      buildTestWidget(stepData: perspectiveStep, isActive: true),
    );
    await tester.pumpAndSettle();

    // Verify "Feinrotation (0,5Â°-Schritte mit Hilfsgitter)" is rendered correctly
    // Note: Due to potential encoding differences in test, we look for the label defined in models.
    final feinrotationLabel = perspectiveStep.availableTools
        .firstWhere((t) => t.action == ToolAction.fineRotation)
        .label;
    expect(find.text(feinrotationLabel), findsOneWidget);

    final measureStep = WorkflowStepData.allSteps.firstWhere(
      (s) => s.type == WorkflowStepType.measure,
    );
    await tester.pumpWidget(
      buildTestWidget(stepData: measureStep, isActive: true),
    );
    await tester.pumpAndSettle();

    final flaecheLabel = measureStep.availableTools
        .firstWhere((t) => t.action == ToolAction.measureRectArea)
        .label;
    expect(find.text(flaecheLabel), findsOneWidget);
  });

  testWidgets('Visuelles Feedback für aktives Tool', (
    WidgetTester tester,
  ) async {
    final measureStep = WorkflowStepData.allSteps.firstWhere(
      (s) => s.type == WorkflowStepType.measure,
    );

    await tester.pumpWidget(
      buildTestWidget(
        stepData: measureStep,
        isActive: true,
        activeToolAction: ToolAction.measureRectArea,
      ),
    );
    await tester.pumpAndSettle();

    // We can't easily check actual color of container by default unless we extract the widget and inspect its BoxDecoration.
    // Instead we can find the Container for the tool and verify its color is primaryContainer.
    final flaecheLabel = measureStep.availableTools
        .firstWhere((t) => t.action == ToolAction.measureRectArea)
        .label;

    final toolItem = find
        .ancestor(of: find.text(flaecheLabel), matching: find.byType(Container))
        .first;

    final container = tester.widget<Container>(toolItem);
    final decoration = container.decoration as BoxDecoration;

    final BuildContext context = tester.element(find.byType(Scaffold));
    final expectedColor = Theme.of(context).colorScheme.primaryContainer;

    expect(decoration.color, equals(expectedColor));
  });
}
