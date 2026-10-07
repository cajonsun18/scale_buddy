import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/services/image_loader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageLoaderService', () {
    late ImageLoaderService service;

    setUp(() {
      service = ImageLoaderService();
    });

    test('generateSampleFloorPlan creates a valid image', () async {
      final info = await service.generateSampleFloorPlan();

      expect(info.width, 1400);
      expect(info.height, 900);
      expect(info.fileName, 'Muster_Grundriss_EG.png');
      expect(info.bytes, isNotEmpty);
      expect(info.fileSizeBytes, greaterThan(0));
    });

    test('loadFromBytes decodes an image', () async {
      // Generate an image to have valid bytes
      final sample = await service.generateSampleFloorPlan();

      final info = await service.loadFromBytes(
        sample.bytes,
        fileName: 'test.png',
      );
      expect(info, isNotNull);
      expect(info!.width, 1400);
      expect(info.height, 900);
      expect(info.fileName, 'test.png');
    });

    test('loadFromBytes returns null for invalid bytes', () async {
      final info = await service.loadFromBytes(Uint8List.fromList([1, 2, 3]));
      expect(info, isNull);
    });
  });
}
