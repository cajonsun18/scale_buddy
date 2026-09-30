import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scale_buddy/controllers/workspace_controller.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';
import 'package:scale_buddy/services/image_loader_service.dart';
import 'package:scale_buddy/widgets/workspace_toolbar.dart';
import 'package:scale_buddy/theme/app_theme.dart';

class MockImageLoaderService extends Mock implements ImageLoaderService {}

void main() {
  Widget createWidgetUnderTest(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: WorkspaceToolbar()),
      ),
    );
  }

  testWidgets(
    'WorkspaceToolbar calls loadSample when "Beispiel laden" is clicked',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockImageLoaderService();

      // Setup a dummy result so the controller doesn't fail
      final mockImage = LoadedImageInfo(
        fileName: 'dummy.png',
        bytes: Uri.parse('data:,').data!.contentAsBytes(),
        width: 10,
        height: 10,
        fileSizeBytes: 100,
      );

      when(() => mockService.generateSampleFloorPlan())
          .thenAnswer((_) async => mockImage);

      final container = ProviderContainer(
        overrides: [imageLoaderServiceProvider.overrideWithValue(mockService)],
      );

      await tester.pumpWidget(createWidgetUnderTest(container));
      await tester.pumpAndSettle();

      // Find the button with text "Beispiel laden"
      final button = find.text('Beispiel laden');
      expect(button, findsOneWidget);

      // Tap it
      await tester.tap(button);
      await tester.pump(); // Start loading

      // Verify that the service was called
      verify(() => mockService.generateSampleFloorPlan()).called(1);

      await tester.pumpAndSettle(); // Finish loading
    },
  );
}
