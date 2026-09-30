import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scale_buddy/main.dart';

void main() {
  testWidgets('Workflow menu cards switch and open on click', (
    WidgetTester tester,
  ) async {
    // Desktop-Fenstergröße für den Test simulieren
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. App starten
    await tester.pumpWidget(const ProviderScope(child: ScaleBuddyApp()));
    await tester.pumpAndSettle();

    // 2. Prüfen, ob alle 4 Workflow-Menüpunkte in der Seitenleiste sichtbar sind
    expect(find.text('Datei laden'), findsAtLeastNWidgets(1));
    expect(find.text('Perspektive korrigieren'), findsAtLeastNWidgets(1));
    expect(find.text('Kalibrieren'), findsAtLeastNWidgets(1));
    expect(find.text('Messen'), findsAtLeastNWidgets(1));

    // Standardmäßig ist Schritt 1 aktiv
    expect(find.text('Schritt 1 von 4'), findsOneWidget);

    // 3. Auf Schritt 2 ("Perspektive korrigieren") klicken
    await tester.tap(find.text('Perspektive korrigieren').first);
    await tester.pumpAndSettle();

    // Prüfen, ob Schritt 2 nun aktiv ist und seine Werkzeuge sichtbar sind
    expect(find.text('Schritt 2 von 4'), findsOneWidget);
    expect(find.text('Automatische Entzerrung (KI/OpenCV)'), findsOneWidget);

    // 4. Auf ein Werkzeug in Schritt 2 klicken
    await tester.tap(find.text('Automatische Entzerrung (KI/OpenCV)').first);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Automatische Entzerrung'),
      findsAtLeastNWidgets(1),
    );

    // 5. Auf Schritt 3 ("Kalibrieren") klicken
    final calFinder = find.text('Kalibrieren').first;
    await tester.ensureVisible(calFinder);
    await tester.tap(calFinder);
    await tester.pumpAndSettle();
    expect(find.text('Schritt 3 von 4'), findsOneWidget);

    // 6. Auf Schritt 4 ("Messen") klicken
    final messenFinder = find.text('Messen').first;
    await tester.ensureVisible(messenFinder);
    await tester.tap(messenFinder);
    await tester.pumpAndSettle();
    expect(find.text('Schritt 4 von 4'), findsOneWidget);
  });
}
