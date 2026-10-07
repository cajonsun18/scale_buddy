import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';
import 'package:scale_buddy/widgets/workspace_placeholder.dart';
import 'package:scale_buddy/widgets/workspace_toolbar.dart';

void main() {
  testWidgets('StepDetailView renders step info and placeholder initially', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StepDetailView(
              activeStep: WorkflowStepType.file,
              currentStatus: StepStatus.active,
              lastSelectedTool: ToolAction.openFile,
              onStatusChanged: (status) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Datei laden'), findsOneWidget);
    expect(find.text('Screenshot aufnehmen oder Bild laden'), findsOneWidget);
    expect(
      find.text('Schritt abschließen'),
      findsOneWidget,
    ); // Status is active

    // Check tool indicator
    expect(
      find.text('Im Menü links gewählt: "Bilddatei vom Computer öffnen"'),
      findsOneWidget,
    );

    // Check workspace
    expect(find.byType(WorkspaceToolbar), findsOneWidget);
    expect(find.byType(WorkspacePlaceholder), findsOneWidget);
  });
}
