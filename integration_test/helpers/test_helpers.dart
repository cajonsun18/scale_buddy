import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scale_buddy/main.dart';
import 'package:scale_buddy/services/image_loader_service.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';

/// Mock-Klasse um den FilePicker zu umgehen und das Testbild zu laden
class MockImageLoaderService extends ImageLoaderService {
  @override
  Future<LoadedImageInfo?> pickImageFromFile() async {
    try {
      final ByteData data = await rootBundle.load(
        'test_assets/verzerrtes_bild.jpg',
      );
      final bytes = data.buffer.asUint8List();
      return await loadFromBytes(bytes, fileName: 'verzerrtes_bild.jpg');
    } catch (e) {
      debugPrint('Fehler beim Laden des Test-Bildes: $e');
      return null;
    }
  }
}

/// Hilfsfunktion: Startet die App, ladt das verzerrte Bild und geht zu Schritt 2
Future<void> startAppAndLoadImage(WidgetTester tester) async {
  // Baue die App mit dem gemockten ImageLoaderService
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        imageLoaderServiceProvider.overrideWithValue(MockImageLoaderService()),
      ],
      child: const ScaleBuddyApp(),
    ),
  );

  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));

  // 1. Pruefe, ob der WorkspacePlaceholder angezeigt wird
  expect(find.text('Bild in den Workspace laden'), findsOneWidget);

  // 2. Finde den "Datei laden..." Button in der Toolbar
  final loadButtonFinder = find.widgetWithText(FilledButton, 'Datei laden…');
  expect(loadButtonFinder, findsOneWidget);

  // 3. Klicke auf "Datei laden..."
  await tester.tap(loadButtonFinder);
  await tester.pumpAndSettle();

  // 4. Pruefe, ob der Placeholder verschwunden ist
  expect(find.text('Bild in den Workspace laden'), findsNothing);

  // 5. Pruefe, ob wir uns nun im Perspektive-Schritt befinden
  expect(find.text('Perspektive korrigieren'), findsWidgets);
  expect(find.byType(InteractiveViewer), findsOneWidget);

  await Future.delayed(const Duration(seconds: 1));
}

/// Hilfsfunktion: Fuehrt im Schritt 2 die automatische Entzerrung durch und geht zu Schritt 3
Future<void> performAutoPerspectiveAndContinue(WidgetTester tester) async {
  // 1. Finde den "Automatische Entzerrung" Button (hat das Icon auto_fix_high)
  final autoPerspectiveFinder = find.byIcon(Icons.auto_fix_high);
  expect(autoPerspectiveFinder, findsWidgets);

  // Klicke auf Automatische Entzerrung
  await tester.tap(autoPerspectiveFinder.first);

  // Warte auf die OpenCV-Berechnung
  await tester.pumpAndSettle(const Duration(seconds: 3));
  await Future.delayed(const Duration(seconds: 1));

  // 2. Finde und klicke auf "Entzerren"
  final transformFinder = find.widgetWithText(FilledButton, 'Entzerren');
  expect(transformFinder, findsOneWidget);
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();
  await tester.tap(transformFinder, warnIfMissed: false);

  await tester.pumpAndSettle(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 1));

  // 3. Klicke auf "Weiter zu Schritt 3" in der Sidebar
  final nextStepFinder = find.widgetWithText(
    OutlinedButton,
    'Weiter zu Schritt 3',
  );
  expect(nextStepFinder, findsOneWidget);
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();
  await tester.tap(nextStepFinder, warnIfMissed: false);
  await tester.pumpAndSettle();

  // 4. Pruefe, ob wir wirklich im Schritt 3 sind, indem wir den großen Ueberschrift-Text pruefen
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Kalibrieren' &&
          widget.style?.fontSize == 24,
    ),
    findsOneWidget,
  );
}

/// Hilfsfunktion: Fuehrt im Schritt 2 die manuelle Entzerrung durch und geht zu Schritt 3
Future<void> performManualPerspectiveAndContinue(WidgetTester tester) async {
  // 1. Finde den "Manuelle 4-Punkt-Entzerrung" Button
  final manualPerspectiveFinder = find.byIcon(Icons.filter_center_focus);
  expect(manualPerspectiveFinder, findsWidgets);

  // Klicke auf Manuelle Entzerrung
  await tester.tap(manualPerspectiveFinder.first);
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));

  // Wir brauchen das InteractiveViewer-Fenster, um die Groesse und Position zu finden
  final imageFinder = find
      .descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Stack),
      )
      .first;
  final viewer = tester.getCenter(imageFinder);
  final viewerSize = tester.getSize(imageFinder);
  final dxStep = viewerSize.width * 0.2;
  final dyStep = viewerSize.height * 0.2;

  // 2. Klicke 4 Punkte auf das Bild (wir waehlen einfach ein Rechteck in der Mitte)
  await tester.tapAt(
    Offset(viewer.dx - dxStep, viewer.dy - dyStep),
  ); // Oben links
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(
    Offset(viewer.dx + dxStep, viewer.dy - dyStep),
  ); // Oben rechts
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(
    Offset(viewer.dx + dxStep, viewer.dy + dyStep),
  ); // Unten rechts
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(
    Offset(viewer.dx - dxStep, viewer.dy + dyStep),
  ); // Unten links
  await tester.pumpAndSettle();

  // 3. Finde und klicke auf "Entzerren"
  final transformFinder = find.widgetWithText(FilledButton, 'Entzerren');
  expect(transformFinder, findsOneWidget);
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();
  await tester.tap(transformFinder, warnIfMissed: false);

  await tester.pumpAndSettle(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 1));

  // 4. Klicke auf "Weiter zu Schritt 3" in der Sidebar
  final nextStepFinder = find.widgetWithText(
    OutlinedButton,
    'Weiter zu Schritt 3',
  );
  expect(nextStepFinder, findsOneWidget);
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();
  await tester.tap(nextStepFinder, warnIfMissed: false);
  await tester.pumpAndSettle();

  // 5. Pruefe, ob wir wirklich im Schritt 3 sind
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Kalibrieren' &&
          widget.style?.fontSize == 24,
    ),
    findsOneWidget,
  );
}

/// Hilfsfunktion: Fuehrt Schritt 3 (Kalibrieren) durch und wechselt zu Schritt 4
Future<void> performCalibrationAndContinue(WidgetTester tester) async {
  // 1. Klicke auf "Referenzstrecke im Bild anklicken (2 Punkte)" in der Sidebar
  final referenceToolFinder = find.text(
    'Referenzstrecke im Bild anklicken (2 Punkte)',
  );
  expect(referenceToolFinder, findsWidgets);
  // Wir wischen die Sidebar hoch, falls der Button unten ist
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();
  await tester.tap(referenceToolFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();

  // 2. Klicke zwei Punkte auf das Bild
  final imageFinder = find
      .descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Stack),
      )
      .first;
  final viewer = tester.getCenter(imageFinder);
  final viewerSize = tester.getSize(imageFinder);
  final dxStep = viewerSize.width * 0.15;

  await tester.tapAt(Offset(viewer.dx - dxStep, viewer.dy));
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(Offset(viewer.dx + dxStep, viewer.dy));
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));

  // 3. Finde das Textfeld für die Längeneingabe und gib '10' ein
  // Das Textfeld ist wahrscheinlich das einzige auf dem Bildschirm zu diesem Zeitpunkt
  final textFieldFinder = find.byType(TextField);
  expect(textFieldFinder, findsOneWidget);
  await tester.enterText(textFieldFinder, '10');
  await tester.pumpAndSettle();

  // 4. Klicke auf den Bestätigungs-Haken
  final checkButtonFinder = find.byIcon(Icons.check);
  expect(checkButtonFinder, findsWidgets);
  // Wir nehmen das letzte gefundene Icon, da in der Sidebar abgeschlossene Schritte
  // ebenfalls ein Icons.check haben. Das Overlay wird spaeter in den Tree gerendert.
  await tester.tap(checkButtonFinder.last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));

  // 5. Überprüfen, ob wir im Schritt 4 sind
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Messen' &&
          widget.style?.fontSize == 24,
    ),
    findsOneWidget,
  );
}

/// Hilfsfunktion: Fuehrt Schritt 4 (Messen) durch und wechselt zu Schritt 5
Future<void> performMeasurementsAndContinue(WidgetTester tester) async {
  final imageFinder = find
      .descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Stack),
      )
      .first;
  final viewer = tester.getCenter(imageFinder);
  final viewerSize = tester.getSize(imageFinder);
  final dxStep = viewerSize.width * 0.3;
  final dyStep = viewerSize.height * 0.2;

  // --- Länge (2 Klicks) ---
  final lengthToolFinder = find.text('Länge');
  expect(lengthToolFinder, findsWidgets);
  await tester.tap(lengthToolFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.tapAt(Offset(viewer.dx - dxStep, viewer.dy - dyStep));
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(Offset(viewer.dx + dxStep, viewer.dy - dyStep));
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(milliseconds: 500));

  // --- Dachwinkel (2 Klicks, Endpunkt höher als Startpunkt) ---
  final angleToolFinder = find.text('Dachwinkel');
  expect(angleToolFinder, findsWidgets);
  await tester.tap(angleToolFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.tapAt(Offset(viewer.dx, viewer.dy));
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(Offset(viewer.dx + dxStep, viewer.dy - dyStep));
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(milliseconds: 500));

  // --- Fläche (Polygon) ---
  final polyToolFinder = find.text('Fläche (Frei)');
  expect(polyToolFinder, findsWidgets);
  await tester.tap(polyToolFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();

  // Merken des Startpunkts
  final startPoint = Offset(viewer.dx - dxStep, viewer.dy + dyStep);
  await tester.tapAt(startPoint);
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(Offset(viewer.dx + dxStep, viewer.dy + dyStep));
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(Offset(viewer.dx + dxStep, viewer.dy + dyStep * 2));
  await Future.delayed(const Duration(milliseconds: 300));
  await tester.tapAt(Offset(viewer.dx - dxStep, viewer.dy + dyStep * 2));
  await Future.delayed(const Duration(milliseconds: 300));
  // Zurück zum Startpunkt, um das Polygon zu schließen
  await tester.tapAt(startPoint);
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));

  // 4. Klicke auf "Weiter zu Schritt 5" in der Sidebar
  final nextStepFinder = find.widgetWithText(
    OutlinedButton,
    'Weiter zu Schritt 5',
  );
  expect(nextStepFinder, findsOneWidget);
  await tester.drag(find.byType(ListView).first, const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.tap(nextStepFinder, warnIfMissed: false);
  await tester.pumpAndSettle();

  // 5. Überprüfen, ob wir im Schritt 5 sind
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Export & Bericht' &&
          widget.style?.fontSize == 24,
    ),
    findsOneWidget,
  );
}

/// Hilfsfunktion: Fuehrt Schritt 5 (Export) durch
Future<void> performExport(WidgetTester tester) async {
  final exportButtonFinder = find.text('Als Bild exportieren');
  expect(exportButtonFinder, findsWidgets);
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();

  // Da der Export einen nativen Speicherdialog öffnet, der den Test blockieren könnte
  // (je nachdem wie file_selector auf Windows mockbar ist), tippen wir ihn an
  // und beenden den Test direkt danach, da wir ansonsten in einem blockierten Zustand enden könnten.
  await tester.tap(exportButtonFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Hilfsfunktion: Ueberspringt die Entzerrung in Schritt 2 und geht direkt zu Schritt 3
Future<void> performSkipPerspectiveAndContinue(WidgetTester tester) async {
  // 1. Finde das Tool "Ohne Korrektur fortfahren" in Schritt 2
  final skipFinder = find.text('Ohne Korrektur fortfahren');
  expect(skipFinder, findsWidgets);
  await tester.drag(find.byType(ListView).first, const Offset(0, -250));
  await tester.pumpAndSettle();
  await tester.tap(skipFinder.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));

  // 2. Pruefe, ob wir wirklich im Schritt 3 sind
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Kalibrieren' &&
          widget.style?.fontSize == 24,
    ),
    findsOneWidget,
  );
}
