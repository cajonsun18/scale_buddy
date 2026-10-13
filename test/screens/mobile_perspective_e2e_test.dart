import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_perspective_state.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/services/image_loader_service.dart';
import 'package:scale_buddy/widgets/mobile_perspective_dock.dart';
import 'package:scale_buddy/widgets/mobile_perspective_header.dart';
import 'package:scale_buddy/widgets/scale_buddy_app_bar.dart';
import 'package:scale_buddy/widgets/workflow_sidebar.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';
import 'package:scale_buddy/widgets/workspace_status_bar.dart';
import 'package:scale_buddy/widgets/workspace_toolbar.dart';

import '../utils/mock_data.dart';

class MockImageLoaderService extends Mock implements ImageLoaderService {}

LoadedImageInfo createMockImage({
  String fileName = 'test.png',
  int width = 200,
  int height = 200,
}) {
  return LoadedImageInfo(
    fileName: fileName,
    fileSizeBytes: mockPngBytes.length,
    bytes: mockPngBytes,
    width: width,
    height: height,
  );
}

void main() {
  group('Mobile Step 2 E2E & Regressionsabsicherung (< 800 dp)', () {
    testWidgets(
      'Flow: Automatische Entzerrung -> Auto-Entzerrung -> Entzerren -> Weiter zu Kalibrieren',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockService = MockImageLoaderService();
        final testImage = createMockImage();
        final completer = Completer<LoadedImageInfo?>();
        when(() => mockService.pickImageFromGalleryMobile())
            .thenAnswer((_) => completer.future);

        final container = ProviderContainer(
          overrides: [
            imageLoaderServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Start: Bild ueber mobilen Plus-Button laden
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Galerie'));
        await tester.pump(const Duration(milliseconds: 60));

        completer.complete(testImage);
        await tester.pumpAndSettle();

        // Schritt 2 ist aktiv, Zustand 1 (Start-Auswahl)
        expect(find.byType(MobilePerspectiveHeader), findsOneWidget);
        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        expect(find.text('Wähle eine Methode zur Entzerrung'), findsOneWidget);
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
        expect(find.text('Manuell'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);

        // 2. Klick auf "Auto-Entzerrung" (Zustand 3: 4 Ecken automatisch erkannt)
        // Setze erkannte Punkte und Auto-Status im Controller & Flow-Notifier
        container
            .read(workspaceControllerProvider.notifier)
            .addOrUpdateEntity(
              DrawingEntity.perspective(
                id: 'auto_persp_1',
                points: const [
                  Offset(0.15, 0.15),
                  Offset(0.85, 0.15),
                  Offset(0.85, 0.85),
                  Offset(0.15, 0.85),
                ],
                color: Colors.orange,
              ),
            );
        container
            .read(mobilePerspectiveStateProvider.notifier)
            .setReady(isAuto: true);
        await tester.pumpAndSettle();

        // Status-Pille wechselt zu Zustand 3 ("✨ Automatisch erkannt"), 4 Ecken gesetzt, Entzerren aktiv
        expect(find.text('✨ Automatisch erkannt'), findsOneWidget);
        final stateAfterAuto = container.read(workspaceControllerProvider);
        final perspEntity = stateAfterAuto.entities
            .whereType<PerspectiveEntity>()
            .firstOrNull;
        expect(perspEntity, isNotNull);
        expect(perspEntity!.points.length, 4);

        // "Entzerren" Button ist blau/aktiviert
        final entzerrenFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Entzerren' &&
              w.properties.enabled == true,
        );
        expect(entzerrenFinder, findsOneWidget);

        // 3. Klick auf "Entzerren"
        // In Headless-Widget-Tests wird der transformierte Zustand gesetzt
        final orig = container.read(workspaceControllerProvider).loadedImage;
        final warped = createMockImage(fileName: 'warped.png');
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: warped,
          originalImage: orig,
          preWarpEntities: [perspEntity],
          entities: [],
        );
        container.read(mobilePerspectiveStateProvider.notifier).setRectified();
        await tester.pumpAndSettle();

        // Bild ist entzerrt (Zustand 4), Dock zeigt "Punkte anpassen", "Zurücksetzen", "Weiter"
        expect(find.text('✓ Perspektive entzerrt'), findsOneWidget);
        expect(find.text('Punkte anpassen'), findsOneWidget);
        expect(find.text('Zurücksetzen'), findsOneWidget);
        expect(find.text('Weiter'), findsOneWidget);

        // 4. Klick auf "Weiter" -> Uebergang zu Schritt 3 (Kalibrieren)
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();

        // Mobiler Header und Dock von Schritt 2 sind nicht mehr vorhanden
        expect(find.byType(MobilePerspectiveHeader), findsNothing);
        expect(find.byType(MobilePerspectiveDock), findsNothing);

        // Entzerrtes Bild bleibt erhalten
        final stateStep3 = container.read(workspaceControllerProvider);
        expect(stateStep3.loadedImage, isNotNull);
        expect(
          stateStep3.originalImage,
          isNotNull,
        ); // Original bleibt als Backup gesichert
      },
    );

    testWidgets(
      'Flow: Manuelle Entzerrung mit 4 Taps, Drag-Geste (Lupe), Entzerren & Punkte anpassen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockService = MockImageLoaderService();
        final testImage = createMockImage();
        final container = ProviderContainer(
          overrides: [
            imageLoaderServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Bild direkt via controller setzen
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: testImage);
        await tester.pumpAndSettle();

        // 1. Klick auf "Manuell"
        await tester.tap(find.text('Manuell'));
        await tester.pumpAndSettle();

        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.manualInProgress,
        );
        expect(find.text('Ecke 1 von 4 antippen (oben links)'), findsOneWidget);

        // "Entzerren" ist deaktiviert
        final entzerrenDisabledFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Entzerren' &&
              w.properties.enabled == false,
        );
        expect(entzerrenDisabledFinder, findsOneWidget);

        final imageCenter = tester.getCenter(find.byType(WorkspaceImageView));

        // 2. Nacheinander 4 Punkte per Tap setzen & Status-Pille pruefen
        // Punkt 1: oben links
        await tester.tapAt(imageCenter + const Offset(-50, -50));
        await tester.pumpAndSettle();
        expect(
          find.text('Ecke 2 von 4 antippen (oben rechts)'),
          findsOneWidget,
        );

        // Punkt 2: oben rechts
        await tester.tapAt(imageCenter + const Offset(50, -50));
        await tester.pumpAndSettle();
        expect(
          find.text('Ecke 3 von 4 antippen (unten rechts)'),
          findsOneWidget,
        );

        // Punkt 3: unten rechts
        await tester.tapAt(imageCenter + const Offset(50, 50));
        await tester.pumpAndSettle();
        expect(
          find.text('Ecke 4 von 4 antippen (unten links)'),
          findsOneWidget,
        );

        // Punkt 4: unten links
        await tester.tapAt(imageCenter + const Offset(-50, 50));
        await tester.pumpAndSettle();

        // 4 Ecken bereit!
        expect(find.text('✓ 4 von 4 Ecken gesetzt – Bereit'), findsOneWidget);
        final entzerrenEnabledFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Entzerren' &&
              w.properties.enabled == true,
        );
        expect(entzerrenEnabledFinder, findsOneWidget);

        // 3. Verschieben eines Punktes mit Drag-Geste: Lupe wird sichtbar
        final pEntity = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<PerspectiveEntity>()
            .first;
        final handleFinder = find.byKey(
          ValueKey('point_handle_${pEntity.id}_0'),
        );
        expect(handleFinder, findsOneWidget);

        final handlePos = tester.getCenter(handleFinder);
        final gesture = await tester.startGesture(handlePos);
        await tester.pump();
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();

        // Lupe sichtbar!
        expect(find.byType(RawMagnifier), findsOneWidget);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);

        // 4. Klick auf "Entzerren"
        final orig2 = container.read(workspaceControllerProvider).loadedImage;
        final warped2 = createMockImage(fileName: 'warped.png');
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: warped2,
          originalImage: orig2,
          preWarpEntities: [pEntity],
          entities: [],
        );
        container.read(mobilePerspectiveStateProvider.notifier).setRectified();
        await tester.pumpAndSettle();

        expect(find.text('✓ Perspektive entzerrt'), findsOneWidget);
        expect(find.text('Punkte anpassen'), findsOneWidget);

        // 5. Klick auf "Punkte anpassen" -> Originalbild und Punkte werden wiederhergestellt
        await tester.tap(find.text('Punkte anpassen'));
        await tester.pumpAndSettle();

        final stateRestored = container.read(workspaceControllerProvider);
        expect(stateRestored.originalImage, isNull);
        expect(
          stateRestored.entities
              .whereType<PerspectiveEntity>()
              .first
              .points
              .length,
          4,
        );
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.ready4Points,
        );
        expect(find.text('✓ 4 von 4 Ecken gesetzt – Bereit'), findsOneWidget);
      },
    );

    testWidgets(
      'Robustheit der Rücksetz-Logik: Aus Zustand 2 (manuell in Progress) -> Zustand 1',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        final testImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: testImage);
        await tester.pumpAndSettle();

        // In manuellen Modus wechseln
        await tester.tap(find.text('Manuell'));
        await tester.pumpAndSettle();

        // 2 Punkte setzen
        final imageCenter = tester.getCenter(find.byType(WorkspaceImageView));
        await tester.tapAt(imageCenter + const Offset(-40, -40));
        await tester.pumpAndSettle();
        await tester.tapAt(imageCenter + const Offset(40, -40));
        await tester.pumpAndSettle();

        expect(
          find.text('Ecke 3 von 4 antippen (unten rechts)'),
          findsOneWidget,
        );

        // Klick auf "Zurücksetzen"
        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        // Exakt wieder die 3 Start-Buttons aus Zustand 1
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
        expect(find.text('Manuell'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);
        expect(find.text('Zurücksetzen'), findsNothing);
        expect(find.text('Entzerren'), findsNothing);

        // Punkte wurden gelöscht
        final entities = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<PerspectiveEntity>();
        expect(entities, isEmpty);
      },
    );

    testWidgets(
      'Robustheit der Rücksetz-Logik: Aus Zustand 3 (nach Auto-Entzerrung) -> Zustand 1',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        final testImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: testImage);
        await tester.pumpAndSettle();

        // Zustand 3: 4 Ecken nach Auto-Entzerrung vorbereiten
        container
            .read(workspaceControllerProvider.notifier)
            .addOrUpdateEntity(
              DrawingEntity.perspective(
                id: 'auto_persp_1',
                points: const [
                  Offset(0.15, 0.15),
                  Offset(0.85, 0.15),
                  Offset(0.85, 0.85),
                  Offset(0.15, 0.85),
                ],
                color: Colors.orange,
              ),
            );
        container
            .read(mobilePerspectiveStateProvider.notifier)
            .setReady(isAuto: true);
        await tester.pumpAndSettle();

        expect(find.text('✨ Automatisch erkannt'), findsOneWidget);
        expect(find.text('Entzerren'), findsOneWidget);

        // Klick auf "Zurücksetzen"
        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        // Kehrt ausnahmslos zu Zustand 1 zurück (kein automatischer Wechsel in manuellen Modus)
        expect(find.text('Wähle eine Methode zur Entzerrung'), findsOneWidget);
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
        expect(find.text('Manuell'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);

        final entities = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<PerspectiveEntity>();
        expect(entities, isEmpty);
        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.initial,
        );
      },
    );

    testWidgets(
      'Robustheit der Rücksetz-Logik: Aus Zustand 4 (nach erfolgter Entzerrung) -> Zustand 1',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        final originalImage = createMockImage(fileName: 'orig.png');
        final warpedImage = createMockImage(fileName: 'warped.png');

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: warpedImage,
          originalImage: originalImage,
          preWarpEntities: [
            DrawingEntity.perspective(
              id: 'p1',
              points: const [
                Offset(0.1, 0.1),
                Offset(0.9, 0.1),
                Offset(0.9, 0.9),
                Offset(0.1, 0.9),
              ],
              color: Colors.orange,
            ),
          ],
        );
        container.read(mobilePerspectiveStateProvider.notifier).setRectified();
        await tester.pumpAndSettle();

        expect(find.text('✓ Perspektive entzerrt'), findsOneWidget);

        // Klick auf "Zurücksetzen"
        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        // Stellt Originalbild wieder her und kehrt zu Zustand 1 zurück
        final state = container.read(workspaceControllerProvider);
        expect(state.originalImage, isNull);
        expect(state.loadedImage?.fileName, 'orig.png');
        expect(state.entities.whereType<PerspectiveEntity>(), isEmpty);

        expect(
          container.read(mobilePerspectiveStateProvider).stepState,
          MobilePerspectiveStepState.initial,
        );
        expect(find.text('Wähle eine Methode zur Entzerrung'), findsOneWidget);
        expect(find.text('Auto-Entzerrung'), findsOneWidget);
        expect(find.text('Manuell'), findsOneWidget);
        expect(find.text('Überspringen'), findsOneWidget);
      },
    );

    testWidgets(
      'Flow: Überspringen aus Zustand 1, 2 und 3 schaltet direkt zu Schritt 3 ohne Entzerrung',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Testfall A: Überspringen aus Zustand 1
        {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const ScaleBuddyApp(),
            ),
          );
          await tester.pumpAndSettle();

          final testImage = createMockImage();
          container.read(workspaceControllerProvider.notifier).state =
              WorkspaceState(loadedImage: testImage);
          await tester.pumpAndSettle();

          expect(find.text('Überspringen'), findsOneWidget);
          await tester.tap(find.text('Überspringen'));
          await tester.pumpAndSettle();

          // Header und Dock weg -> In Schritt 3
          expect(find.byType(MobilePerspectiveHeader), findsNothing);
          expect(find.byType(MobilePerspectiveDock), findsNothing);
          expect(
            container.read(workspaceControllerProvider).originalImage,
            isNull,
          );
        }

        // Testfall B: Überspringen aus Zustand 2
        {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const ScaleBuddyApp(),
            ),
          );
          await tester.pumpAndSettle();

          final testImage = createMockImage();
          container.read(workspaceControllerProvider.notifier).state =
              WorkspaceState(loadedImage: testImage);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Manuell'));
          await tester.pumpAndSettle();

          expect(find.text('Überspringen'), findsOneWidget);
          await tester.tap(find.text('Überspringen'));
          await tester.pumpAndSettle();

          expect(find.byType(MobilePerspectiveHeader), findsNothing);
          expect(find.byType(MobilePerspectiveDock), findsNothing);
          expect(
            container.read(workspaceControllerProvider).originalImage,
            isNull,
          );
        }

        // Testfall C: Überspringen aus Zustand 3
        {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const ScaleBuddyApp(),
            ),
          );
          await tester.pumpAndSettle();

          final testImage = createMockImage();
          container.read(workspaceControllerProvider.notifier).state =
              WorkspaceState(loadedImage: testImage);
          await tester.pumpAndSettle();

          // Zustand 3: 4 Ecken nach Auto-Entzerrung vorbereiten
          container
              .read(workspaceControllerProvider.notifier)
              .addOrUpdateEntity(
                DrawingEntity.perspective(
                  id: 'auto_persp_1',
                  points: const [
                    Offset(0.15, 0.15),
                    Offset(0.85, 0.15),
                    Offset(0.85, 0.85),
                    Offset(0.15, 0.85),
                  ],
                  color: Colors.orange,
                ),
              );
          container
              .read(mobilePerspectiveStateProvider.notifier)
              .setReady(isAuto: true);
          await tester.pumpAndSettle();

          expect(find.text('Überspringen'), findsOneWidget);
          await tester.tap(find.text('Überspringen'));
          await tester.pumpAndSettle();

          expect(find.byType(MobilePerspectiveHeader), findsNothing);
          expect(find.byType(MobilePerspectiveDock), findsNothing);
          expect(
            container.read(workspaceControllerProvider).originalImage,
            isNull,
          );
        }
      },
    );

    testWidgets(
      'Desktop-Regressionssicherheit (>= 800 dp): Weder Header noch Dock sichtbar, Desktop-Tools aktiv',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ScaleBuddyApp(),
          ),
        );
        await tester.pumpAndSettle();

        final testImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: testImage);
        await tester.pumpAndSettle();

        // 1. Mobile Header & Dock dürfen auf Desktop NICHT gerendert werden
        expect(find.byType(MobilePerspectiveHeader), findsNothing);
        expect(find.byType(MobilePerspectiveDock), findsNothing);

        // 2. Desktop Chrome MUSS gerendert werden
        expect(find.byType(ScaleBuddyAppBar), findsOneWidget);
        expect(find.byType(WorkflowSidebar), findsOneWidget);
        expect(find.byType(WorkspaceToolbar), findsOneWidget);
        expect(find.byType(WorkspaceStatusBar), findsOneWidget);

        // 3. Desktop Step 2 Seitenleisten-Tools & Slider überprüfen
        expect(
          find.text('Automatische Entzerrung (KI/OpenCV)'),
          findsOneWidget,
        );
        expect(find.text('Manuelle 4-Punkt-Entzerrung'), findsOneWidget);
        expect(find.text('Ohne Korrektur fortfahren'), findsOneWidget);
        expect(find.text('Seitenverhältnis anpassen'), findsOneWidget);
        expect(find.text('X-Skalierung'), findsOneWidget);
        expect(find.text('Y-Skalierung'), findsOneWidget);
        expect(find.byType(Slider), findsNWidgets(2));
      },
    );
  });
}
