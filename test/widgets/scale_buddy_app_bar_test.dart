import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/theme/app_theme.dart';
import 'package:scale_buddy/widgets/scale_buddy_app_bar.dart';

void main() {
  testWidgets('ScaleBuddyAppBar renders and handles actions', (
    WidgetTester tester,
  ) async {
    bool newMeasurementTapped = false;
    bool zoomInTapped = false;
    bool zoomOutTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: ScaleBuddyAppBar(
            onNewMeasurement: () => newMeasurementTapped = true,
            onZoomIn: () => zoomInTapped = true,
            onZoomOut: () => zoomOutTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('ScaleBuddy'), findsOneWidget);
    expect(find.text('Weitere Messung'), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    expect(find.byIcon(Icons.zoom_out), findsOneWidget);

    await tester.tap(find.text('Weitere Messung'));
    await tester.tap(find.byIcon(Icons.zoom_in));
    await tester.tap(find.byIcon(Icons.zoom_out));

    expect(newMeasurementTapped, isTrue);
    expect(zoomInTapped, isTrue);
    expect(zoomOutTapped, isTrue);
  });
}
