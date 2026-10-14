import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/l10n/app_localizations.dart';
import 'package:scale_buddy/widgets/mobile_step_header.dart';

void main() {
  group('MobileStepHeader', () {
    testWidgets('renders app title, subtitle and child status pill correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('de'),
          home: Scaffold(
            body: MobileStepHeader(
              subtitle: 'Schritt X: Test',
              semanticsLabel: 'Kopfbereich Test',
              statusPill: Text('Status Pill Content'),
            ),
          ),
        ),
      );

      expect(find.text('Scale Buddy'), findsOneWidget);
      expect(find.text('Schritt X: Test'), findsOneWidget);
      expect(find.text('Status Pill Content'), findsOneWidget);

      final semantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Kopfbereich Test',
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets(
      'returns SizedBox.shrink when checkDesktopBreakpoint is true on desktop',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('de'),
            home: Scaffold(
              body: MobileStepHeader(
                subtitle: 'Schritt X: Test',
                semanticsLabel: 'Kopfbereich Test',
                checkDesktopBreakpoint: true,
                statusPill: Text('Status Pill Content'),
              ),
            ),
          ),
        );

        expect(find.text('Scale Buddy'), findsNothing);
        expect(find.text('Schritt X: Test'), findsNothing);
        expect(find.text('Status Pill Content'), findsNothing);
      },
    );
  });

  group('MobileStatusPillContainer', () {
    testWidgets('renders child and semantics correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MobileStatusPillContainer(
              semanticsLabel: 'Status: Test',
              backgroundColor: Colors.blue,
              borderColor: Colors.lightBlue,
              child: Text('Test Pill'),
            ),
          ),
        ),
      );

      expect(find.text('Test Pill'), findsOneWidget);
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.liveRegion == true &&
            w.properties.label == 'Status: Test',
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });

  group('StatusDotIndicator', () {
    testWidgets('renders active and inactive indicators', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                StatusDotIndicator(isActive: true),
                StatusDotIndicator(isActive: false),
                StatusDotIndicator(
                  isActive: false,
                  useBorderWhenInactive: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatusDotIndicator), findsNWidgets(3));
    });
  });
}
