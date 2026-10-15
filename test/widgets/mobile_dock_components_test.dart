import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/widgets/mobile_dock_components.dart';

void main() {
  group('MobileDockContainer Tests', () {
    testWidgets('renders child and default capsule decoration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MobileDockContainer(child: Text('Dock Content')),
          ),
        ),
      );

      expect(find.text('Dock Content'), findsOneWidget);

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final containerWidget = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Dock Content'),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration?.borderRadius, BorderRadius.circular(30.0));
      expect(decoration?.border, isNotNull);
      expect(decoration?.boxShadow, isNotEmpty);
    });

    testWidgets(
      'wraps SafeArea and standard margin when wrapSafeAreaAndMargin is true',
      (WidgetTester tester) async {
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
      },
    );
  });

  group('MobileDockButton Tests', () {
    testWidgets(
      'renders icon, label and fulfills min 44dp height touch target',
      (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  MobileDockButton(
                    label: 'Test Button',
                    icon: Icons.check,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    onPressed: () => tapped = true,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);

        final inkWellFinder = find.byType(InkWell);
        final inkWellSize = tester.getSize(inkWellFinder);
        expect(inkWellSize.height, greaterThanOrEqualTo(44.0));

        await tester.tap(find.text('Test Button'));
        expect(tapped, isTrue);
      },
    );

    testWidgets('correct semantics when enabled vs disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                MobileDockButton(
                  label: 'Enabled Btn',
                  icon: Icons.add,
                  iconColor: Colors.white,
                  textColor: Colors.white,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );

      final disabledSemanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.enabled == false &&
            w.properties.label == 'Enabled Btn',
      );
      expect(disabledSemanticsFinder, findsOneWidget);
    });

    testWidgets(
      'primary factory creates primary styling with blue background',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  MobileDockButton.primary(
                    label: 'Primary Action',
                    icon: Icons.arrow_forward,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        final button = tester.widget<MobileDockButton>(
          find.byType(MobileDockButton),
        );
        expect(button.isPrimary, isTrue);
        expect(button.backgroundColor, const Color(0xFF2563EB));
      },
    );

    testWidgets(
      'secondary factory creates secondary styling with slate border',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  MobileDockButton.secondary(
                    label: 'Secondary Action',
                    icon: Icons.refresh,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        final button = tester.widget<MobileDockButton>(
          find.byType(MobileDockButton),
        );
        expect(button.isPrimary, isFalse);
        expect(button.borderColor, const Color(0xFF334155));
      },
    );

    testWidgets(
      'expanded false renders standalone button without Expanded widget',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileDockButton(
                expanded: false,
                label: 'Standalone',
                icon: Icons.star,
                iconColor: Colors.yellow,
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Standalone'), findsOneWidget);
        expect(find.byType(Expanded), findsNothing);
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

  group('MobileDockDivider Tests', () {
    testWidgets('renders divider with default width and height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MobileDockDivider())),
      );

      final dividerSize = tester.getSize(find.byType(MobileDockDivider));
      expect(dividerSize.width, 1.0);
      expect(dividerSize.height, 20.0);
    });
  });
}
