import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/widgets/mobile_dock_components.dart';

void main() {
  group('MobileDockContainer Tests', () {
    testWidgets('renders child and respects wrapSafeAreaAndMargin', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MobileDockContainer(
              wrapSafeAreaAndMargin: true,
              child: Text('Wrapped Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Wrapped Content'), findsOneWidget);
    });
  });

  group('MobileDockButton Tests', () {
    testWidgets(
      'renders button, fulfills >= 44dp touch target, handles tap and respects disabled semantics',
      (WidgetTester tester) async {
        bool tapped = false;

        // 1. Enabled button
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  MobileDockButton.primary(
                    label: 'Primary Action',
                    icon: Icons.check,
                    onPressed: () => tapped = true,
                  ),
                  MobileDockButton.secondary(
                    label: 'Secondary Action',
                    icon: Icons.refresh,
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Primary Action'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);

        final inkWellFinder = find.byType(InkWell).first;
        final inkWellSize = tester.getSize(inkWellFinder);
        expect(inkWellSize.height, greaterThanOrEqualTo(44.0));

        await tester.tap(find.text('Primary Action'));
        expect(tapped, isTrue);

        // 2. Disabled semantics on secondary
        final disabledSemanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.enabled == false &&
              w.properties.label == 'Secondary Action',
        );
        expect(disabledSemanticsFinder, findsOneWidget);
      },
    );
  });

  group('MobileDockTextButton Tests', () {
    testWidgets('fulfills min 44x44 touch target and triggers tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileDockTextButton(
              label: 'Überspringen',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Überspringen'), findsOneWidget);

      final boxSize = tester.getSize(find.byType(MobileDockTextButton));
      expect(boxSize.width, greaterThanOrEqualTo(44.0));
      expect(boxSize.height, greaterThanOrEqualTo(44.0));

      await tester.tap(find.text('Überspringen'));
      expect(tapped, isTrue);
    });
  });
}
