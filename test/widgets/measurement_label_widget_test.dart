import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/measurement_label_widget.dart';

void main() {
  testWidgets('MeasurementLabelWidget renders text and handles tap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MeasurementLabelWidget(
            text: 'Test Label',
            isSelected: false,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Label'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing); // Not selected

    await tester.tap(find.text('Test Label'));
    expect(tapped, isTrue);
  });

  testWidgets('MeasurementLabelWidget shows delete button when selected', (
    WidgetTester tester,
  ) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MeasurementLabelWidget(
            text: 'Test Label',
            isSelected: true,
            onTap: () {},
            onDelete: () {
              deleted = true;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(deleted, isTrue);
  });
}
