import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/main.dart';

void main() {
  testWidgets('App smoke test builds main layout', (WidgetTester tester) async {
    await tester.pumpWidget(const ScaleBuddyApp());
    expect(find.text('ScaleBuddy'), findsOneWidget);
    expect(find.text('ARBEITSABLAUF'), findsOneWidget);
  });
}
