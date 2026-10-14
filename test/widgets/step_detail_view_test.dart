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

  testWidgets(
    'StepDetailView performs directional slide & fade on forward and backward navigation while canvas remains static',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Widget buildView(WorkflowStepType step) {
        return ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StepDetailView(
                activeStep: step,
                currentStatus: StepStatus.active,
                onStatusChanged: (_) {},
              ),
            ),
          ),
        );
      }

      // 1. Initial State: Step 1 (file)
      await tester.pumpWidget(buildView(WorkflowStepType.file));
      await tester.pumpAndSettle();

      final initialFilePos = tester.getTopLeft(find.text('Datei laden'));
      final baseDx = initialFilePos.dx;
      final canvasPosInitial = tester.getTopLeft(
        find.byType(WorkspacePlaceholder),
      );

      expect(find.text('Datei laden'), findsOneWidget);
      expect(find.text('Screenshot aufnehmen oder Bild laden'), findsOneWidget);

      // 2. Forward Navigation: Switch to Step 2 (perspective)
      await tester.pumpWidget(buildView(WorkflowStepType.perspective));
      // Pump initial frame of transition
      await tester.pump(const Duration(milliseconds: 50));

      // Both outgoing ('Datei laden') and incoming ('Perspektive korrigieren') texts exist
      expect(find.text('Datei laden'), findsOneWidget);
      expect(find.text('Perspektive korrigieren'), findsOneWidget);

      final outgoingFilePos = tester.getTopLeft(find.text('Datei laden'));
      final incomingPerspectivePos = tester.getTopLeft(
        find.text('Perspektive korrigieren'),
      );
      final canvasPosMidTransition = tester.getTopLeft(
        find.byType(WorkspacePlaceholder),
      );

      // Forward: Incoming text slides in from the right (dx > baseDx)
      expect(
        incomingPerspectivePos.dx,
        greaterThan(baseDx),
        reason: 'New text should enter from the right in forward navigation',
      );
      // Forward: Outgoing text slides out to the left (dx < baseDx)
      expect(
        outgoingFilePos.dx,
        lessThan(baseDx),
        reason: 'Old text should slide out to the left in forward navigation',
      );
      // Canvas remains completely static
      expect(
        canvasPosMidTransition,
        equals(canvasPosInitial),
        reason: 'Canvas position must remain 100% static during transition',
      );

      // Finish forward animation
      await tester.pumpAndSettle();

      expect(find.text('Datei laden'), findsNothing);
      expect(find.text('Perspektive korrigieren'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Perspektive korrigieren')).dx,
        equals(baseDx),
      );

      // 3. Backward Navigation: Switch back to Step 1 (file)
      await tester.pumpWidget(buildView(WorkflowStepType.file));
      // Pump initial frame of reverse transition
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Datei laden'), findsOneWidget);
      expect(find.text('Perspektive korrigieren'), findsOneWidget);

      final incomingFilePosBackward = tester.getTopLeft(
        find.text('Datei laden'),
      );
      final outgoingPerspectivePosBackward = tester.getTopLeft(
        find.text('Perspektive korrigieren'),
      );
      final canvasPosMidBackward = tester.getTopLeft(
        find.byType(WorkspacePlaceholder),
      );

      // Backward: Incoming text slides in from the left (dx < baseDx)
      expect(
        incomingFilePosBackward.dx,
        lessThan(baseDx),
        reason: 'New text should enter from the left in backward navigation',
      );
      // Backward: Outgoing text slides out to the right (dx > baseDx)
      expect(
        outgoingPerspectivePosBackward.dx,
        greaterThan(baseDx),
        reason: 'Old text should slide out to the right in backward navigation',
      );
      // Canvas still remains static
      expect(
        canvasPosMidBackward,
        equals(canvasPosInitial),
        reason: 'Canvas position must remain 100% static during backward transition',
      );

      // Finish backward animation
      await tester.pumpAndSettle();

      expect(find.text('Perspektive korrigieren'), findsNothing);
      expect(find.text('Datei laden'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Datei laden')).dx, equals(baseDx));
      expect(
        tester.getTopLeft(find.byType(WorkspacePlaceholder)),
        equals(canvasPosInitial),
      );
    },
  );
}
