import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/l10n/app_localizations.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/tools/angle_tool.dart';
import 'package:scale_buddy/tools/distance_tool.dart';
import 'package:scale_buddy/tools/polygon_tool.dart';
import 'package:scale_buddy/tools/rectangle_tool.dart';
import 'package:scale_buddy/tools/select_tool.dart';
import 'package:scale_buddy/widgets/mobile_dock_components.dart';
import 'package:scale_buddy/widgets/mobile_measure_dock.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';

void main() {
  LoadedImageInfo createMockImage({int width = 800, int height = 600}) {
    return LoadedImageInfo(
      fileName: 'test.png',
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
        98,
        174,
        66,
        96,
        130,
      ]),
      width: width,
      height: height,
    );
  }

  Widget buildTestWidget({
    required ProviderContainer container,
    VoidCallback? onNextStep,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: Scaffold(
          body: StepDetailView(
            activeStep: WorkflowStepType.measure,
            currentStatus: StepStatus.active,
            onStatusChanged: (_) {},
            isMobile: true,
          ),
        ),
      ),
    );
  }

  group('MobileMeasureDock Tests', () {
    testWidgets(
      'renders all 5 tools with vertical layout, default selection, and allows tool switching',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage());

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(MobileMeasureDock), findsOneWidget);
        expect(find.byType(MobileDockContainer), findsOneWidget);

        // All 5 tools rendered with vertical Column layout
        for (final label in [
          'Strecke',
          'Rechteck',
          'Polygon',
          'Winkel',
          'Edit',
        ]) {
          final textFinder = find.text(label);
          expect(textFinder, findsOneWidget);
          final columnFinder = find.ancestor(
            of: textFinder,
            matching: find.byType(Column),
          );
          expect(columnFinder, findsWidgets);
        }

        // Strecke container is highlighted in tool color (tinted background + border)
        final streckeContainerFinder = find.ancestor(
          of: find.text('Strecke'),
          matching: find.byType(Container),
        );
        final streckeContainer = tester.widget<Container>(
          streckeContainerFinder.first,
        );
        final decoration = streckeContainer.decoration as BoxDecoration?;
        expect(
          decoration?.color,
          const Color(0xFF38BDF8).withValues(alpha: 0.20),
        );
        expect(
          (decoration?.border as Border?)?.top.color,
          const Color(0xFF38BDF8),
        );
        expect(container.read(activeToolProvider), isA<DistanceTool>());

        // Switch to each tool sequentially
        await tester.tap(find.text('Rechteck'));
        await tester.pumpAndSettle();
        expect(container.read(activeToolProvider), isA<RectangleTool>());

        await tester.tap(find.text('Polygon'));
        await tester.pumpAndSettle();
        expect(container.read(activeToolProvider), isA<PolygonTool>());

        await tester.tap(find.text('Winkel'));
        await tester.pumpAndSettle();
        expect(container.read(activeToolProvider), isA<AngleTool>());

        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        expect(container.read(activeToolProvider), isA<SelectTool>());

        await tester.tap(find.text('Strecke'));
        await tester.pumpAndSettle();
        expect(container.read(activeToolProvider), isA<DistanceTool>());
      },
    );

    testWidgets(
      'Zustand 1 and 3: Rückgängig and Export button states, actions, and callbacks',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        bool nextStepCalled = false;

        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: createMockImage(), entities: []);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('de'),
              home: Scaffold(
                body: MobileMeasureDock(
                  onNextStep: () {
                    nextStepCalled = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 0 measurements: Undo and Export disabled
        expect(find.text('Rückgängig'), findsOneWidget);
        expect(find.text('Weiter zu Schritt 5 (Export)'), findsOneWidget);

        var buttons = tester
            .widgetList<MobileDockButton>(find.byType(MobileDockButton))
            .toList();
        var undoButton = buttons.firstWhere((b) => b.label == 'Rückgängig');
        var exportButton = buttons.firstWhere(
          (b) => b.label == 'Weiter zu Schritt 5 (Export)',
        );
        expect(undoButton.onPressed, isNull);
        expect(exportButton.onPressed, isNull);

        // Verify semantics disabled
        final exportSemantics = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Weiter zu Schritt 5 (Export)' &&
              w.properties.enabled == false,
        );
        expect(exportSemantics, findsOneWidget);

        // Add 1 measurement -> both enabled
        const lineEntity = DrawingEntity.line(
          id: 'line_1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.5, 0.5),
          color: Colors.cyan,
        );
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [lineEntity],
        );
        await tester.pumpAndSettle();

        buttons = tester
            .widgetList<MobileDockButton>(find.byType(MobileDockButton))
            .toList();
        undoButton = buttons.firstWhere((b) => b.label == 'Rückgängig');
        exportButton = buttons.firstWhere(
          (b) => b.label == 'Weiter zu Schritt 5 (Export)',
        );
        expect(undoButton.onPressed, isNotNull);
        expect(exportButton.onPressed, isNotNull);
        expect(exportButton.backgroundColor, const Color(0xFF10B981));
        expect(exportButton.isPrimary, isTrue);

        // Tap Export -> triggers onNextStep
        await tester.tap(find.text('Weiter zu Schritt 5 (Export)'));
        await tester.pumpAndSettle();
        expect(nextStepCalled, isTrue);

        // Tap Undo -> removes measurement and clears
        await tester.tap(find.text('Rückgängig'));
        await tester.pumpAndSettle();
        expect(container.read(workspaceControllerProvider).entities, isEmpty);
      },
    );

    testWidgets('all touch targets fulfill minimum 44x44 pt', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: createMockImage());

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // Check all InkWell touch target sizes
      final inkWells = find.descendant(
        of: find.byType(MobileMeasureDock),
        matching: find.byType(InkWell),
      );
      expect(inkWells, findsWidgets);

      for (final inkWell in tester.widgetList<InkWell>(inkWells)) {
        final renderBox = tester.renderObject(find.byWidget(inkWell));
        final size = (renderBox as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(44.0));
        expect(size.width, greaterThanOrEqualTo(44.0));
      }
    });

    testWidgets('hides dock on desktop screens (>= 800 pt)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: createMockImage());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: MobileMeasureDock())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Strecke'), findsNothing);
      expect(find.text('Rechteck'), findsNothing);
      expect(find.text('Weiter zu Schritt 5 (Export)'), findsNothing);
    });

    testWidgets(
      'Zustand 2: shows "Punkt 1 verwerfen" and tapping it cancels open measurement',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const openLine = DrawingEntity.line(
          id: 'L1',
          p1: Offset(0.3, 0.4),
          p2: null,
          color: Color(0xFF38BDF8),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [openLine],
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // "Punkt 1 verwerfen" is displayed instead of "Rückgängig"
        expect(find.text('Punkt 1 verwerfen'), findsOneWidget);
        expect(find.text('Rückgängig'), findsNothing);

        // Export is disabled
        final exportSemantics = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Weiter zu Schritt 5 (Export)' &&
              w.properties.enabled == false,
        );
        expect(exportSemantics, findsOneWidget);

        // Tool switching is locked while point 1 is set
        await tester.tap(find.text('Rechteck'));
        await tester.pumpAndSettle();
        expect(container.read(activeToolProvider), isA<DistanceTool>());

        // Tap "Punkt 1 verwerfen" -> cancels measurement and returns to Zustand 1
        await tester.tap(find.text('Punkt 1 verwerfen'));
        await tester.pumpAndSettle();

        expect(container.read(workspaceControllerProvider).entities, isEmpty);
        expect(find.text('Punkt 1 verwerfen'), findsNothing);
        expect(find.text('Rückgängig'), findsOneWidget);
      },
    );

    testWidgets(
      'Zustand 4: inspector card renders entity details and handles Fertig and Löschen actions',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const calib = CalibrationEntity(
          id: 'calib_1',
          p1: Offset(0.1, 0.1),
          p2: Offset(0.2, 0.1),
          enteredDistance: 1.0,
          isConfirmed: true,
        );

        // 1000x1000 image, 100 px = 1 m
        // 1.74 m width = 174 px = 0.174
        // 2.30 m height = 230 px = 0.230
        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.374, 0.430),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(width: 1000, height: 1000),
          entities: [calib, rect],
          selectedEntityId: 'R1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Werkzeugleiste ist nicht mehr sichtbar, stattdessen Inspektorkarte
        expect(find.text('Strecke'), findsNothing);
        expect(find.text('F1 · Rechteckfläche'), findsOneWidget);
        expect(
          find.text('Fläche: 4,00 m² · Umfang: 8,08 m · 1,74 × 2,30 m'),
          findsOneWidget,
        );
        expect(find.text('Rechteck'), findsOneWidget); // Typ-Badge
        expect(find.text('Löschen'), findsOneWidget);
        expect(find.text('Fertig'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);

        // 1. Tap Fertig -> deselects entity, returns to tool view in Zustand 3
        await tester.tap(find.text('Fertig'));
        await tester.pumpAndSettle();
        expect(
          container.read(workspaceControllerProvider).selectedEntityId,
          isNull,
        );
        expect(find.text('Strecke'), findsOneWidget);
        expect(find.text('Fertig'), findsNothing);

        // Reselect R1
        container.read(workspaceControllerProvider.notifier).state = container
            .read(workspaceControllerProvider)
            .copyWith(selectedEntityId: 'R1');
        await tester.pumpAndSettle();
        expect(find.text('Löschen'), findsOneWidget);

        // 2. Tap Löschen -> removes entity, clears selection and returns to tool view
        await tester.tap(find.text('Löschen'));
        await tester.pumpAndSettle();
        final finalState = container.read(workspaceControllerProvider);
        expect(finalState.entities.where((e) => e.id == 'R1'), isEmpty);
        expect(finalState.selectedEntityId, isNull);
        expect(find.text('Strecke'), findsOneWidget);
        expect(find.text('Löschen'), findsNothing);
      },
    );

    testWidgets(
      'Tapping Edit in dock selects last measurement if none selected',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        const rect = DrawingEntity.rectangle(
          id: 'R1',
          p1: Offset(0.2, 0.2),
          p2: Offset(0.5, 0.5),
          color: Color(0xFF10B981),
        );

        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: createMockImage(),
          entities: [rect],
          selectedEntityId: null,
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        final updatedState = container.read(workspaceControllerProvider);
        expect(updatedState.selectedEntityId, 'R1');
        // Transforms into inspector
        expect(find.text('F1 · Rechteckfläche'), findsOneWidget);
      },
    );
  });
}
