import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/l10n/app_localizations.dart';
import 'package:scale_buddy/widgets/mobile_step_header.dart';

void main() {
  group('AppLocalizations & Option B i18n', () {
    testWidgets('renders German strings by default with de locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.appName),
                    Text(l10n.step2HeaderSubtitle),
                    Text(l10n.step3HeaderSubtitle),
                    Text(l10n.perspectiveInitial),
                    Text(l10n.perspectiveManualReady),
                    Text(l10n.calibrationPhase1),
                    Text(
                      l10n.perspectiveManualStatusSemantics(
                        2,
                        l10n.perspectiveCornerBottomRight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Scale Buddy'), findsOneWidget);
      expect(find.text('Schritt 2: Perspektive korrigieren'), findsOneWidget);
      expect(find.text('Schritt 3: Maßstab kalibrieren'), findsOneWidget);
      expect(find.text('Wähle eine Methode zur Entzerrung'), findsOneWidget);
      expect(find.text('✓ 4 von 4 Ecken gesetzt – Bereit'), findsOneWidget);
      expect(find.text('Tippe auf den 1. Referenzpunkt'), findsOneWidget);
      expect(
        find.text(
          'Status: 2 von 4 Ecken gesetzt. Ecke 3 von 4 antippen (unten rechts)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders English strings with en locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.appName),
                    Text(l10n.step2HeaderSubtitle),
                    Text(l10n.step3HeaderSubtitle),
                    Text(l10n.perspectiveInitial),
                    Text(l10n.perspectiveManualReady),
                    Text(l10n.calibrationPhase1),
                    Text(
                      l10n.perspectiveManualStatusSemantics(
                        2,
                        l10n.perspectiveCornerBottomRight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Scale Buddy'), findsOneWidget);
      expect(find.text('Step 2: Correct perspective'), findsOneWidget);
      expect(find.text('Step 3: Calibrate scale'), findsOneWidget);
      expect(find.text('Select a rectification method'), findsOneWidget);
      expect(find.text('✓ 4 of 4 corners set – Ready'), findsOneWidget);
      expect(find.text('Tap on the 1st reference point'), findsOneWidget);
      expect(
        find.text(
          'Status: 2 of 4 corners set. Tap corner 3 of 4 (bottom right)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('MobileStepHeader reacts to current locale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: MobileStepHeader(
              subtitle: 'Step 2: Correct perspective',
              semanticsLabel: 'Header area step 2',
              statusPill: Text('Status Pill'),
            ),
          ),
        ),
      );

      expect(find.text('Scale Buddy'), findsOneWidget);
      expect(find.text('Step 2: Correct perspective'), findsOneWidget);
    });
  });
}
