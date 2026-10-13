import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_perspective_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/mobile_perspective_header.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';

void main() {
  LoadedImageInfo createMockImage({String fileName = 'test.png'}) {
    return LoadedImageInfo(
      fileName: fileName,
      fileSizeBytes: 58,
      bytes: Uint8List.fromList([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        11,
        73,
        68,
        65,
        84,
        8,
        215,
        99,
        74,
        150,
        0,
        0,
        1,
        1,
        1,
        0,
        24,
        221,
        141,
        178,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ]),
      width: 100,
      height: 100,
    );
  }

  Widget buildTestWidget({
    required ProviderContainer container,
    required WorkflowStepType activeStep,
    required bool isMobile,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StepDetailView(
            activeStep: activeStep,
            currentStatus: StepStatus.active,
            onStatusChanged: (_) {},
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }

  group('MobilePerspectiveHeader & MobilePerspectiveStatusPill', () {
    testWidgets(
      'Mobile perspective header renders typography correctly (< 800 dp)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Set loaded image
        final mockImage = createMockImage();
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Header titles
        expect(find.text('Scale Buddy'), findsOneWidget);
        expect(find.text('Schritt 2: Perspektive korrigieren'), findsOneWidget);

        // Verify typography styling of title and subtitle
        final titleText = tester.widget<Text>(find.text('Scale Buddy'));
        expect(titleText.style?.color, Colors.white);
        expect(titleText.style?.fontWeight, FontWeight.bold);

        final subtitleText = tester.widget<Text>(
          find.text('Schritt 2: Perspektive korrigieren'),
        );
        expect(subtitleText.style?.color, const Color(0xFF94A3B8));
      },
    );

    testWidgets('Status-Pille Zustand 1: Vor Auswahl (Initial)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage);

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.perspective,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wähle eine Methode zur Entzerrung'), findsOneWidget);

      // Check Semantics
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Status: Wähle eine Methode zur Entzerrung',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Status-Pille Zustand 2: Manuelle Erfassung (< 4 Ecken)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      final entity = DrawingEntity.perspective(
        id: 'p1',
        points: [const Offset(0.2, 0.2), const Offset(0.8, 0.2)],
        color: Colors.orange,
      );

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage, entities: [entity]);
      container
          .read(mobilePerspectiveStateProvider.notifier)
          .setManualInProgress();

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.perspective,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      // 2 points set -> Helper text for 3rd corner
      expect(find.text('Ecke 3 von 4 antippen (unten rechts)'), findsOneWidget);

      // Check Semantics label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Status: 2 von 4 Ecken gesetzt. Ecke 3 von 4 antippen (unten rechts)',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
      'Status-Pille Zustand 2: Durchlauf aller 4 Einzelschritte 0 bis 3 Ecken',
      (WidgetTester tester) async {
        final helperTexts = [
          'Ecke 1 von 4 antippen (oben links)',
          'Ecke 2 von 4 antippen (oben rechts)',
          'Ecke 3 von 4 antippen (unten rechts)',
          'Ecke 4 von 4 antippen (unten links)',
        ];

        for (int i = 0; i < 4; i++) {
          final points = List.generate(
            i,
            (idx) => Offset(0.1 * idx, 0.1 * idx),
          );
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final mockImage = createMockImage();
          final entity = DrawingEntity.perspective(
            id: 'p_test',
            points: points,
            color: Colors.orange,
          );

          container
              .read(workspaceControllerProvider.notifier)
              .state = WorkspaceState(
            loadedImage: mockImage,
            entities: i > 0 ? [entity] : [],
          );
          container
              .read(mobilePerspectiveStateProvider.notifier)
              .setManualInProgress();

          await tester.pumpWidget(
            buildTestWidget(
              container: container,
              activeStep: WorkflowStepType.perspective,
              isMobile: true,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(helperTexts[i]), findsOneWidget);
        }
      },
    );

    testWidgets('Status-Pille Zustand 3: Bereit mit 4 Ecken manuell gesetzt', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      final entity = DrawingEntity.perspective(
        id: 'p1',
        points: const [
          Offset(0.1, 0.1),
          Offset(0.9, 0.1),
          Offset(0.9, 0.9),
          Offset(0.1, 0.9),
        ],
        color: Colors.orange,
      );

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage, entities: [entity]);
      container
          .read(mobilePerspectiveStateProvider.notifier)
          .setReady(isAuto: false);

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.perspective,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✓ 4 von 4 Ecken gesetzt – Bereit'), findsOneWidget);

      // Check Semantics label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Status: ✓ 4 von 4 Ecken gesetzt – Bereit',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
      'Status-Pille Zustand 3: Bereit mit Auto-Entzerrung (isAuto: true)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        final entity = DrawingEntity.perspective(
          id: 'p1',
          points: const [
            Offset(0.1, 0.1),
            Offset(0.9, 0.1),
            Offset(0.9, 0.9),
            Offset(0.1, 0.9),
          ],
          color: Colors.orange,
        );

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [entity]);
        container
            .read(mobilePerspectiveStateProvider.notifier)
            .setReady(isAuto: true);

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.perspective,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('✨ Automatisch erkannt'), findsOneWidget);

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Status: ✨ Automatisch erkannt',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets('Status-Pille Zustand 4: Nach Entzerrung (Rectified)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage(fileName: 'warped.png');
      final originalImage = createMockImage(fileName: 'orig.png');

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage, originalImage: originalImage);
      container.read(mobilePerspectiveStateProvider.notifier).setRectified();

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.perspective,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✓ Perspektive entzerrt'), findsOneWidget);

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Status: ✓ Perspektive entzerrt',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Desktop-Modus (>= 800 dp) rendert den mobilen Header NICHT', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage);

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.perspective,
          isMobile: false,
        ),
      );
      await tester.pumpAndSettle();

      // Mobile header must NOT exist
      expect(find.byType(MobilePerspectiveHeader), findsNothing);
      expect(find.byType(MobilePerspectiveStatusPill), findsNothing);
    });
  });
}
