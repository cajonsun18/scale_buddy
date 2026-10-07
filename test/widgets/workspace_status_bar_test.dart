import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/workspace_status_bar.dart';

void main() {
  testWidgets('WorkspaceStatusBar renders correctly without image', (
    WidgetTester tester,
  ) async {
    final state = WorkspaceState();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: WorkspaceStatusBar(
            activeStep: WorkflowStepType.file,
            lastSelectedTool: null,
            workspaceState: state,
            stepTitleFor: (step) => 'Datei laden',
          ),
        ),
      ),
    );

    expect(find.text('Aktives Menü: Datei laden'), findsOneWidget);
    expect(
      find.text('Maßstab: Nicht kalibriert  |  Zoom: 100%'),
      findsOneWidget,
    );
  });
}
