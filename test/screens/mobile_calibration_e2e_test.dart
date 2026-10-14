import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/models/mobile_calibration_state.dart';
import 'package:scale_buddy/models/workflow_step.dart';
import 'package:scale_buddy/models/workspace_state.dart';
import 'package:scale_buddy/services/image_loader_service.dart';
import 'package:scale_buddy/tools/calibration_tool.dart';
import 'package:scale_buddy/utils/geometry_utils.dart';
import 'package:scale_buddy/widgets/calibration_input_widget.dart';
import 'package:scale_buddy/widgets/mobile_calibration_dock.dart';
import 'package:scale_buddy/widgets/mobile_calibration_header.dart';
import 'package:scale_buddy/widgets/mobile_perspective_dock.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/step_detail_view.dart';
import 'package:scale_buddy/widgets/workspace_image_view.dart';

class MockImageLoaderService extends Mock implements ImageLoaderService {}

final Uint8List kTouchMockPngBytes = Uint8List.fromList([
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
  67,
  74,
  150,
  0,
  0,
  1,
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
  84,
  69,
  85,
  174,
  66,
  96,
  130,
  91,
  95,
]);

LoadedImageInfo createMockImage({
  String fileName = 'test_building.png',
  int width = 200,
  int height = 200,
}) {
  return LoadedImageInfo(
    fileName: fileName,
    fileSizeBytes: kTouchMockPngBytes.length,
    bytes: kTouchMockPngBytes,
    width: width,
    height: height,
  );
}

void main() {
  group('Mobile Step 3 E2E- & Regressionsabsicherung (< 800 dp)', () {
    testWidgets(
      'End-to-End-Flow: Vollständiger Happy Path von Schritt 2 bis Schritt 4',
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

        // 1. Bild über Plus-Button laden -> Schritt 2 ist aktiv
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Galerie'));
        await tester.pump(const Duration(milliseconds: 60));

        completer.complete(testImage);
        await tester.pumpAndSettle();

        // Schritt 2 aktiv: Überspringen klicken, um zu Schritt 3 (Kalibrieren) zu gelangen
        expect(find.byType(MobilePerspectiveDock), findsOneWidget);
        await tester.tap(find.text('Überspringen'));
        await tester.pumpAndSettle();

        // 2. Start in Schritt 3 (Phase 1: 0 Punkte)
        expect(find.byType(MobileCalibrationHeader), findsOneWidget);
        expect(find.byType(MobileCalibrationDock), findsOneWidget);
        expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);
        expect(
          find.text('Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)'),
          findsOneWidget,
        );
        // Kein Überspringen-Button im Kalibrierungs-Dock
        expect(find.text('Überspringen'), findsNothing);

        final imageCenter = tester.getCenter(find.byType(WorkspaceImageView));

        // 3. Tap 1: Punkt 1 setzen
        await tester.tapAt(imageCenter + const Offset(-40, -40));
        await tester.pumpAndSettle();

        // Phase 2 aktiv
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.onePoint,
        );
        expect(
          find.text('Punkt 1 gesetzt – Tippe auf den 2. Punkt'),
          findsOneWidget,
        );
        expect(find.text('Zurücksetzen'), findsOneWidget);
        final disabledConfirmPhase2 = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == false,
        );
        expect(disabledConfirmPhase2, findsOneWidget);

        // 4. Tap 2: Punkt 2 setzen
        await tester.tapAt(imageCenter + const Offset(40, 40));
        await tester.pumpAndSettle();

        // Phase 3 aktiv: Tastatur fokussiert automatisch
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.twoPointsInput,
        );
        expect(
          find.text('2 Punkte gesetzt – Reale Länge eingeben'),
          findsOneWidget,
        );
        expect(find.text('Löschen'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, TextInputType.none);
        expect(textField.readOnly, isTrue);
        expect(textField.showCursor, isTrue);

        final editableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );
        expect(editableText.focusNode.hasFocus, isTrue);

        // Deaktiviertes Bestätigen vor Werteingabe
        final disabledConfirmPhase3 = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == false,
        );
        expect(disabledConfirmPhase3, findsOneWidget);

        // 5. Eingabe: "2,10" über In-App-Zifferntastatur eingeben
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(','));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        // Bestätigen-Button ist nun blau (#2563EB) und aktiviert
        final enabledConfirm = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == true,
        );
        expect(enabledConfirm, findsOneWidget);

        // Wert ist live in der Entity gespiegelt (2.10)
        final liveCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(liveCalib.enteredDistance, 2.10);

        // 6. Klick auf „Bestätigen“: Springt sofort direkt in Phase 4
        await tester.tap(find.text('Bestätigen'));
        await tester.pumpAndSettle();

        // Tastatur ist geschlossen (unfocused)
        expect(
          FocusScope.of(tester.element(find.byType(MobileCalibrationDock)))
              .hasFocus,
          isFalse,
        );

        // Phase 4: Maßstab erfolgreich kalibriert
        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.confirmed,
        );
        expect(
          find.textContaining('✓ Maßstab kalibriert: 1 m ='),
          findsOneWidget,
        );
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

        // 7. Klick auf „Weiter zu Schritt 4“: Schaltet den Workflow auf WorkflowStepType.measure
        await tester.tap(find.text('Weiter zu Schritt 4'));
        await tester.pumpAndSettle();

        // Kalibrierungs-Dock ist nun nicht mehr aktiv, da Schritt 4 aktiv ist
        expect(find.byType(MobileCalibrationDock), findsNothing);
      },
    );

    testWidgets(
      'Edge Cases & Eingabe-Validierung: Leereingabe, 0, Formatierung, Komma & Einheitenwechsel',
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
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MobileCalibrationDock(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Leereingabe hält Bestätigen deaktiviert
        final emptyConfirm = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bestätigen' &&
              w.properties.enabled == false,
        );
        expect(emptyConfirm, findsOneWidget);

        // 2. Eingabe von "0" hält Bestätigen deaktiviert
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        expect(emptyConfirm, findsOneWidget);

        // 3. Eingabe von "0,00" hält Bestätigen deaktiviert
        await tester.tap(find.text(','));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();
        expect(emptyConfirm, findsOneWidget);

        // 4. Zurücksetzen über Rücktaste
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();

        // Keine ungültigen Zeichen oder Tasten auf Zifferntastatur vorhanden
        expect(find.text('abc!@#'), findsNothing);
        expect(find.text(' '), findsNothing);
        expect(find.text('-'), findsNothing);

        // 5. Komma-Eingabe wird zuverlässig verarbeitet (2,50)
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(','));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('0'));
        await tester.pumpAndSettle();

        var currentCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(currentCalib.enteredDistance, 2.50);

        // Löschen und "3,75" eingeben
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.byIcon(Icons.backspace_outlined));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(','));
        await tester.pumpAndSettle();
        await tester.tap(find.text('7'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();

        currentCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(currentCalib.enteredDistance, 3.75);

        // 6. Einheitenwechsel (m -> cm -> mm)
        // Öffne Einheiten-Menü
        await tester.tap(find.text('m'));
        await tester.pumpAndSettle();

        // Wähle cm
        await tester.tap(find.text('cm').last);
        await tester.pumpAndSettle();

        currentCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(currentCalib.selectedUnit, 'cm');

        // Geometrie-Konvertierung prüft korrekte Skalierung für cm
        final ppmCm = GeometryUtils.getPixelsPerMeter(
          const Size(400, 400),
          calibP1: const Offset(0.2, 0.2),
          calibP2: const Offset(0.8, 0.8),
          calibDistance: 3.75,
          unit: 'cm',
        );
        final ppmM = GeometryUtils.getPixelsPerMeter(
          const Size(400, 400),
          calibP1: const Offset(0.2, 0.2),
          calibP2: const Offset(0.8, 0.8),
          calibDistance: 3.75,
          unit: 'm',
        );
        expect(ppmCm, isNotNull);
        expect(ppmM, isNotNull);
        expect(ppmCm!, closeTo(ppmM! * 100, 0.001));

        // Wechsel zu mm
        await tester.tap(find.text('cm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('mm').last);
        await tester.pumpAndSettle();

        currentCalib = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(currentCalib.selectedUnit, 'mm');

        final ppmMm = GeometryUtils.getPixelsPerMeter(
          const Size(400, 400),
          calibP1: const Offset(0.2, 0.2),
          calibP2: const Offset(0.8, 0.8),
          calibDistance: 3.75,
          unit: 'mm',
        );
        expect(ppmMm, closeTo(ppmM * 1000, 0.001));
      },
    );

    testWidgets(
      'Reset- und Re-Edit-Pfade: Zurücksetzen (Phase 2), Löschen (Phase 3 & 4), Anpassen (Phase 4)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        final workspaceController = container.read(
          workspaceControllerProvider.notifier,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    MobileCalibrationHeader(),
                    Expanded(child: SizedBox()),
                    MobileCalibrationDock(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // A) Aus Phase 2: „Zurücksetzen“ löscht Punkt 1 und kehrt zu Phase 1 zurück
        workspaceController.state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            const DrawingEntity.calibration(
              id: CalibrationTool.defaultCalibrationId,
              p1: Offset(0.3, 0.3),
            ),
          ],
        );
        container.read(mobileCalibrationStateProvider.notifier).setOnePoint();
        await tester.pumpAndSettle();

        expect(find.text('Zurücksetzen'), findsOneWidget);
        await tester.tap(find.text('Zurücksetzen'));
        await tester.pumpAndSettle();

        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.initial,
        );
        expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);
        expect(
          find.text('Tippe auf eine bekannte Kante (z. B. Tür oder Fenster)'),
          findsOneWidget,
        );

        // B) Aus Phase 3: „Löschen“ verwirft beide Punkte und die Eingabe komplett zu Phase 1
        workspaceController.state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            const DrawingEntity.calibration(
              id: CalibrationTool.defaultCalibrationId,
              p1: Offset(0.3, 0.3),
              p2: Offset(0.7, 0.7),
              enteredDistance: 2.10,
            ),
          ],
        );
        container
            .read(mobileCalibrationStateProvider.notifier)
            .setTwoPointsInput();
        await tester.pumpAndSettle();

        expect(find.text('Löschen'), findsOneWidget);
        await tester.tap(find.text('Löschen'));
        await tester.pumpAndSettle();

        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.initial,
        );
        expect(
          container
              .read(workspaceControllerProvider)
              .entities
              .whereType<CalibrationEntity>(),
          isEmpty,
        );
        expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);

        // C) Aus Phase 4: „Löschen“ entfernt die Kalibrierung vollständig und führt zu Phase 1
        workspaceController.state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            const DrawingEntity.calibration(
              id: CalibrationTool.defaultCalibrationId,
              p1: Offset(0.3, 0.3),
              p2: Offset(0.7, 0.7),
              enteredDistance: 2.10,
              isConfirmed: true,
            ),
          ],
        );
        container.read(mobileCalibrationStateProvider.notifier).setConfirmed();
        await tester.pumpAndSettle();

        expect(find.text('Anpassen'), findsOneWidget);
        expect(find.text('Löschen'), findsOneWidget);
        expect(find.text('Weiter zu Schritt 4'), findsOneWidget);

        await tester.tap(find.text('Löschen'));
        await tester.pumpAndSettle();

        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.initial,
        );
        expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);

        // D) Aus Phase 4: „Anpassen“ stellt Phase 3 mit Punkten und eingegebenem Wert wieder her
        workspaceController.state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            const DrawingEntity.calibration(
              id: CalibrationTool.defaultCalibrationId,
              p1: Offset(0.3, 0.3),
              p2: Offset(0.7, 0.7),
              enteredDistance: 2.10,
              isConfirmed: true,
            ),
          ],
        );
        container.read(mobileCalibrationStateProvider.notifier).setConfirmed();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Anpassen'));
        await tester.pumpAndSettle();

        expect(
          container.read(mobileCalibrationStateProvider).stepState,
          MobileCalibrationStepState.twoPointsInput,
        );
        expect(
          find.text('2 Punkte gesetzt – Reale Länge eingeben'),
          findsOneWidget,
        );
        final calibRestored = container
            .read(workspaceControllerProvider)
            .entities
            .whereType<CalibrationEntity>()
            .first;
        expect(calibRestored.isConfirmed, isFalse);
        expect(calibRestored.p1, const Offset(0.3, 0.3));
        expect(calibRestored.p2, const Offset(0.7, 0.7));
        expect(calibRestored.enteredDistance, 2.10);

        final textFieldWidget = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(textFieldWidget.controller?.text, '2,10');
      },
    );

    testWidgets(
      '2.0x-Lupen-Interaktion: Drag-Geste am Referenzpunkt aktiviert 2.0x Lupe mit vertikalem Offset',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            const DrawingEntity.calibration(
              id: CalibrationTool.defaultCalibrationId,
              p1: Offset(0.3, 0.3),
              p2: Offset(0.7, 0.7),
            ),
          ],
        );
        container
            .read(activeToolProvider.notifier)
            .setTool(const CalibrationTool());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: StepDetailView(
                  activeStep: WorkflowStepType.calibrate,
                  currentStatus: StepStatus.active,
                  onStatusChanged: (_) {},
                  isMobile: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Lupe vor der Geste nicht sichtbar
        expect(find.byType(RawMagnifier), findsNothing);

        // Handle für Punkt 1 finden
        final p1Handle = find.byKey(const ValueKey('point_handle_calib_1_0'));
        expect(p1Handle, findsOneWidget);

        final handlePos = tester.getCenter(p1Handle);
        final gesture = await tester.startGesture(handlePos);
        await tester.pump();
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();

        // 2.0x Lupe erscheint
        expect(find.byType(RawMagnifier), findsOneWidget);
        final magnifier = tester.widget<RawMagnifier>(
          find.byType(RawMagnifier),
        );
        expect(magnifier.magnificationScale, 2.0);

        // Lupe schwebt oberhalb des Touch-Punkts (vertikaler Offset)
        final magnifierRect = tester.getRect(find.byType(RawMagnifier));
        expect(magnifierRect.center.dy, lessThan(handlePos.dy));

        // Finger loslassen: Lupe verschwindet
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byType(RawMagnifier), findsNothing);
      },
    );

    testWidgets(
      'Desktop-Regressionssicherheit (>= 800 dp): Weder Header noch Dock sichtbar, Canvas-Inline-Eingabe aktiv',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mockImage = createMockImage();
        container
            .read(workspaceControllerProvider.notifier)
            .state = WorkspaceState(
          loadedImage: mockImage,
          entities: [
            const DrawingEntity.calibration(
              id: CalibrationTool.defaultCalibrationId,
              p1: Offset(0.3, 0.3),
              p2: Offset(0.7, 0.7),
            ),
          ],
        );
        container
            .read(activeToolProvider.notifier)
            .setTool(const CalibrationTool());

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Stack(
                  children: [
                    StepDetailView(
                      activeStep: WorkflowStepType.calibrate,
                      currentStatus: StepStatus.active,
                      onStatusChanged: (_) {},
                      isMobile: false,
                    ),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: MobileCalibrationHeader(),
                    ),
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: MobileCalibrationDock(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Auf Desktop-Breite (>= 800 dp) werden mobiler Header und mobiles Dock unterdrückt
        expect(
          tester.getSize(find.byType(MobileCalibrationHeader)).height,
          0.0,
        );
        expect(tester.getSize(find.byType(MobileCalibrationDock)).height, 0.0);

        // Desktop-spezifisches Inline-Input-Widget auf dem Canvas ist vorhanden
        expect(find.byType(CalibrationInputWidget), findsOneWidget);
      },
    );
  });
}
