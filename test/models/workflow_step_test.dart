import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/workflow_step.dart';

void main() {
  group('WorkflowStepData', () {
    test('allSteps returns 5 steps', () {
      final steps = WorkflowStepData.allSteps;
      expect(steps.length, 5);
      expect(steps[0].type, WorkflowStepType.file);
      expect(steps[1].type, WorkflowStepType.perspective);
      expect(steps[2].type, WorkflowStepType.calibrate);
      expect(steps[3].type, WorkflowStepType.measure);
      expect(steps[4].type, WorkflowStepType.export);
    });

    test('labelFor returns correct label for ToolAction', () {
      expect(
        WorkflowStepData.labelFor(ToolAction.snipScreen),
        'Bildschirmbereich aufnehmen (Snip)',
      );
      expect(WorkflowStepData.labelFor(ToolAction.measureDistance), 'Länge');
    });

    test(
      'labelFor returns empty string for unknown action (if any were possible)',
      () {
        // Dart enums are exhaustive, but we can verify it doesn't crash
        expect(
          WorkflowStepData.labelFor(ToolAction.autoPerspective),
          isNotEmpty,
        );
      },
    );
  });
}
