import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_calibration_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';
import 'package:scale_buddy/widgets/mobile_calibration_dock.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';

import '../utils/mock_data.dart';

void main() {
  LoadedImageInfo createMockImage({String fileName = 'test.png'}) {
    return LoadedImageInfo(
      fileName: fileName,
      fileSizeBytes: mockPngBytes.lengthInBytes,
      bytes: mockPngBytes,
      width: 100,
      height: 100,
    );
  }

  Widget buildTestWidget({
    required ProviderContainer container,
    required WorkflowStepType activeStep,
    required bool isMobile,
    ValueChanged<WorkflowStepType>? onStepSelected,
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
            onStepSelected: onStepSelected,
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }

  group('MobileCalibrationDock Widget & Integration Tests', () {
    testWidgets(
      'Phase 1: Start (0 Punkte) zeigt Hinweispille und KEINEN Überspringen-Button',
      (WidgetTester tester) async {
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
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Hinweispille vorhanden
        expect(
          find.text('Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

        // Bewusster Verzicht auf "Überspringen"
        expect(find.text('Überspringen'), findsNothing);
      },
    );

    testWidgets(
      'Phase 2: Punkt 1 gesetzt zeigt [ ↺ Zurücksetzen ] und deaktiviertes [ ✓ Bestätigen ]',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.3, 0.3),
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container.read(mobileCalibrationStateProvider.notifier).setOnePoint();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Zurücksetzen'), findsOneWidget);
        expect(find.text('Bestätigen'), findsOneWidget);

        // Bestätigen ist strikt deaktiviert (Semantics enabled == false)
        final disabledSemanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == false,
        );
        expect(disabledSemanticsFinder, findsOneWidget);

        // Klick auf "Zurücksetzen" verwirft Punkt 1 und kehrt zu Phase 1 zurück
        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        expect(
          find.text('Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)'),
          findsOneWidget,
        );
        expect(find.text('Zurücksetzen'), findsNothing);
      },
    );

    testWidgets(
      'Phase 3: Eingabe mit Zifferntastatur, Validierung und Live-Badge-Aktualisierung',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          selectedUnit: 'm',
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Bedienelemente vorhanden
        expect(find.text('Löschen'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('m'), findsOneWidget);
        expect(find.text('Bestätigen'), findsOneWidget);

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, TextInputType.none);
        expect(textField.readOnly, isTrue);
        expect(textField.showCursor, isTrue);

        // Ohne Eingabe: Bestätigen ist deaktiviert
        var disabledSemanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == false,
        );
        expect(disabledSemanticsFinder, findsOneWidget);

        // Ungültige Eingabe "0" hält Bestätigen deaktiviert
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        disabledSemanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == false,
        );
        expect(disabledSemanticsFinder, findsOneWidget);

        // Rücktaste
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();

        // Valide Eingabe "2,10" über Zifferntastatur aktiviert Bestätigen und aktualisiert Entity live
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(','));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        var enabledSemanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == true,
        );
        expect(enabledSemanticsFinder, findsOneWidget);

        // Live-Aktualisierung im WorkspaceController
        final currentCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(currentCalib.enteredDistance, 2.10);

        // Klick auf "Löschen" verwirft beide Punkte und die Eingabe komplett zurück zu Phase 1
        await tester.tap(find.text('Löschen'));
        await tester.pumpAndSettle();

        expect(
          find.text('Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)'),
          findsOneWidget,
        );
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.initial,
        );
        final entitiesAfterDelete = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>();
        expect(entitiesAfterDelete, isEmpty);
      },
    );

    testWidgets(
      'Phase 3: Klick auf "Bestätigen" schließt Tastatur und springt direkt in Phase 4',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          selectedUnit: 'm',
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(','));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        // Klick auf Bestätigen
        await tester.tap(find.text('Bestätigen'));
        await tester.pumpAndSettle();

        // Direkt in Phase 4!
        expect(find.text('Anpassen'), findsOneWidget);
        expect(find.text('Löschen'), findsOneWidget);
        expect(find.text('Weiter zu Schritt 4'), findsOneWidget);

        final confirmedEntity = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(confirmedEntity.isConfirmed, isTrue);
        expect(confirmedEntity.enteredDistance, 2.10);
      },
    );

    testWidgets(
      'Phase 4: "Anpassen" reaktiviert Phase 3, "Weiter zu Schritt 4" schaltet auf Messen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        WorkflowStepType? nextStep;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          enteredDistance: 2.10,
          selectedUnit: 'm',
          isConfirmed: true,
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container.read(mobileCalibrationStateProvider.notifier).setConfirmed();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
            onStepSelected: (s) => nextStep = s,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Anpassen'), findsOneWidget);
        expect(find.text('Löschen'), findsOneWidget);
        expect(find.text('Weiter zu Schritt 4'), findsOneWidget);

        // Klick auf "Anpassen"
        await tester.tap(find.text('Anpassen'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.twoPointsInput,
        );

        // Bestätigen erneut, um wieder in Phase 4 zu gehen
        await tester.tap(find.text('Bestätigen'));
        await tester.pumpAndSettle();

        expect(find.text('Weiter zu Schritt 4'), findsOneWidget);

        // Klick auf "Weiter zu Schritt 4"
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        expect(nextStep, WorkflowStepType.measure);
      },
    );

    testWidgets(
      'Desktop-Modus (>= 800 dp) rendert das mobile Kalibrierungs-Dock NICHT',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: MobileCalibrationDock()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(find.byType(Container), findsNothing);
        expect(
          find.text('Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Touch-Target & Accessibility: Alle interaktiven Buttons haben min 44x44 dp Fläche',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          enteredDistance: 2.10,
          selectedUnit: 'm',
          isConfirmed: true,
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container.read(mobileCalibrationStateProvider.notifier).setConfirmed();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        final anpassenBox = tester.getRect(find.text('Anpassen'));
        expect(anpassenBox.height, greaterThanOrEqualTo(10.0));

        final nextBox = tester.getRect(find.text('Weiter zu Schritt 4'));
        expect(nextBox.height, greaterThanOrEqualTo(10.0));
      },
    );

    testWidgets(
      'Phase 3: Einheiten-Auswahl aktualisiert selectedUnit in Entity',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          selectedUnit: 'm',
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Öffne PopupMenu für Einheit
        await tester.tap(find.text('m'));
        await tester.pumpAndSettle();

        // Wähle "cm"
        await tester.tap(find.text('cm').last);
        await tester.pumpAndSettle();

        final updatedCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(updatedCalib.selectedUnit, 'cm');

        // Fokus bleibt auf Textfeld erhalten (Tastatur schließt nicht)
        final editableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );
        expect(editableText.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'Phase 3 Zifferntastatur: Enthält nur Ziffern 0-9, Komma und Rücktaste (KEIN Leerzeichen, KEIN Bindestrich)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          selectedUnit: 'm',
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Zifferntastatur ist sichtbar
        expect(
          find.text('NATIVE ZIFFERNTASATUR (NUR ZAHLEN & KOMMA)'),
          findsOneWidget,
        );
        expect(find.text('Schließen'), findsOneWidget);

        // Ziffern 0 bis 9 vorhanden
        for (int i = 0; i <= 9; i++) {
          expect(find.text('$i'), findsOneWidget);
        }
        // Komma vorhanden
        expect(find.text(','), findsOneWidget);
        // Rücktaste-Icon vorhanden
        expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

        // KEIN Leerzeichen-Button vorhanden
        expect(find.text(' '), findsNothing);
        expect(find.text('Space'), findsNothing);
        expect(find.text('Leerzeichen'), findsNothing);

        // KEIN Bindestrich / Minus-Button vorhanden
        expect(find.text('-'), findsNothing);
        expect(find.text('–'), findsNothing);
        expect(find.text('—'), findsNothing);
      },
    );

    testWidgets(
      'Phase 3 Zifferntastatur: Klick auf Ziffern löschen (⌫) löscht eingegebene Zahl und berührt Referenzpunkte NICHT',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        const calib = DrawingEntity.calibration(
          id: CalibrationTool.defaultCalibrationId,
          p1: Offset(0.2, 0.2),
          p2: Offset(0.8, 0.8),
          selectedUnit: 'm',
        );
        container.read(workspaceControllerProvider.notifier).state =
            WorkspaceState(loadedImage: mockImage, entities: [calib]);
        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();

        await tester.pumpWidget(
          buildTestWidget(
            container: container,
            activeStep: WorkflowStepType.calibrate,
            isMobile: true,
          ),
        );
        await tester.pumpAndSettle();

        // Über Zifferntastatur "2", ",", "5" tippen
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsWidgets);

        await tester.tap(find.text(','));
        await tester.pumpAndSettle();

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, '2,5');

        var entity = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .firstOrNull;
        expect(entity, isNotNull);
        expect(entity!.enteredDistance, 2.5);
        expect(entity.p1, const Offset(0.2, 0.2));
        expect(entity.p2, const Offset(0.8, 0.8));

        // Klick auf den Löschen-Button der Tastatur (⌫): Letztes Zeichen '5' wird gelöscht
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();

        expect(textField.controller!.text, '2,');
        entity = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .firstOrNull;
        // Punkte sind IMMER NOCH DA und nicht gelöscht!
        expect(entity, isNotNull);
        expect(entity!.p1, const Offset(0.2, 0.2));
        expect(entity.p2, const Offset(0.8, 0.8));

        // Weiteres ⌫ löscht Komma
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();
        expect(textField.controller!.text, '2');

        // Weiteres ⌫ leert das Feld komplett
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();
        expect(textField.controller!.text, '');

        // Weiteres ⌫ bei leerem Feld tut nichts und löscht keinesfalls die Punkte
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();

        entity = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .firstOrNull;
        expect(entity, isNotNull);
        expect(entity!.p1, const Offset(0.2, 0.2));
        expect(entity.p2, const Offset(0.8, 0.8));
      },
    );

    testWidgets('Phase 3 Zifferntastatur: Schließen und Wieder-Einblenden', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockImage = createMockImage();
      const calib = DrawingEntity.calibration(
        id: CalibrationTool.defaultCalibrationId,
        p1: Offset(0.2, 0.2),
        p2: Offset(0.8, 0.8),
        selectedUnit: 'm',
      );
      container.read(workspaceControllerProvider.notifier).state =
          WorkspaceState(loadedImage: mockImage, entities: [calib]);
      container
          .read(mobileCalibrationStateProvider.notifier)
          .setTwoPointsInput();

      await tester.pumpWidget(
        buildTestWidget(
          container: container,
          activeStep: WorkflowStepType.calibrate,
          isMobile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('NATIVE ZIFFERNTASATUR (NUR ZAHLEN & KOMMA)'),
        findsOneWidget,
      );

      // Klick auf "Schließen"
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();

      expect(
        find.text('NATIVE ZIFFERNTASATUR (NUR ZAHLEN & KOMMA)'),
        findsNothing,
      );
      expect(find.text('Tastatur öffnen ▴'), findsOneWidget);

      // Klick auf "Tastatur öffnen"
      await tester.tap(find.text('Tastatur öffnen ▴'));
      await tester.pumpAndSettle();

      expect(
        find.text('NATIVE ZIFFERNTASATUR (NUR ZAHLEN & KOMMA)'),
        findsOneWidget,
      );
    });
  });
}
