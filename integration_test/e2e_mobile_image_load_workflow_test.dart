import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/services/image_loader_service.dart';
import 'package:scale_buddy/widgets/image_source_bottom_sheet.dart';
import 'package:scale_buddy/widgets/scale_buddy_app_bar.dart';
import 'package:scale_buddy/widgets/workflow_sidebar.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';
import 'package:scale_buddy/widgets/workspace_placeholder.dart';
import 'package:scale_buddy/widgets/workspace_status_bar.dart';
import 'package:scale_buddy/widgets/workspace_toolbar.dart';

import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';

import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile End-to-End Test: Bild-Lade-Workflow & Visual Reduction', () {
    testWidgets(
      'Startet im Handy-Format (< 800 dp), verifiziert visuelle Reduktion, laedt Testbild via Galerie und wechselt in Schritt 2 mit Vollbildansicht',
      (tester) async {
        // 1. Handy-Bildschirmgröße einstellen (z.B. 390 x 844 dp)
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // 2. App mit gemocktem ImageLoaderService starten
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageLoaderServiceProvider.overrideWithValue(
                MockImageLoaderService(),
              ),
            ],
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 3. Prüfen: Visuelle Reduktion im leeren Handy-Workspace
        // Nur Plus-Button ("Bild hinzufügen") und Hinweistext sichtbar
        expect(find.byType(WorkspacePlaceholder), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.text('Bild hinzufügen'), findsOneWidget);
        expect(find.text('Referenzobjekt mit ins Bild nehmen'), findsOneWidget);

        // Desktop-Chrome ist vollständig ausgeblendet:
        // Weder Kopfzeile (ScaleBuddyAppBar), Werkzeugleiste (WorkspaceToolbar),
        // Statusleiste (WorkspaceStatusBar), Sidebar/Drawer noch FAB
        expect(find.byType(ScaleBuddyAppBar), findsNothing);
        expect(find.byType(WorkspaceToolbar), findsNothing);
        expect(find.byType(WorkspaceStatusBar), findsNothing);
        expect(find.byType(WorkflowSidebar), findsNothing);
        expect(find.byType(Drawer), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.text('Bild in den Workspace laden'), findsNothing);
        expect(find.text('Datei laden…'), findsNothing);
        expect(find.text('Schritt abschließen'), findsNothing);

        // 4. Antippen des Plus-Buttons öffnet das Auswahlfenster (Bottom Sheet)
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(ImageSourceBottomSheet), findsOneWidget);
        expect(find.text('Kamera'), findsOneWidget);
        expect(find.text('Galerie'), findsOneWidget);
        expect(find.text('Abbrechen'), findsOneWidget);

        // 5. Antippen von "Galerie" lädt das Testbild über den Service
        await tester.tap(find.text('Galerie'));
        await tester.pumpAndSettle();

        // 6. Verifizieren: Bottom Sheet ist geschlossen und WorkspacePlaceholder ist verschwunden
        expect(find.byType(ImageSourceBottomSheet), findsNothing);
        expect(find.byType(WorkspacePlaceholder), findsNothing);

        // 7. Verifizieren: Nahtloser Übergang in Schritt 2 ("Perspektive korrigieren")
        // und bildschirmfüllende Bildansicht (WorkspaceImageView)
        final stepDetailView = tester.widget<StepDetailView>(
          find.byType(StepDetailView),
        );
        expect(stepDetailView.activeStep, WorkflowStepType.perspective);
        final workspaceImageView = tester.widget<WorkspaceImageView>(
          find.byType(WorkspaceImageView),
        );
        expect(workspaceImageView.activeStep, WorkflowStepType.perspective);
        expect(find.byType(InteractiveViewer), findsOneWidget);

        // 8. Verifizieren: Auch in Schritt 2 bleibt Desktop-Chrome am Handy ausgeblendet
        expect(find.byType(ScaleBuddyAppBar), findsNothing);
        expect(find.byType(WorkspaceToolbar), findsNothing);
        expect(find.byType(WorkspaceStatusBar), findsNothing);
        expect(find.byType(WorkflowSidebar), findsNothing);
        expect(find.byType(Drawer), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.text('Schritt abschließen'), findsNothing);
      },
    );
  });
}
