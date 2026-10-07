import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/loaded_image_info.dart';

import '../utils/mock_data.dart';

void main() {
  test('LoadedImageInfo formattedFileSize', () {
    LoadedImageInfo createInfo(int size) {
      return LoadedImageInfo(
        fileName: 'test.png',
        bytes: mockPngBytes,
        width: 100,
        height: 100,
        fileSizeBytes: size,
      );
    }

    expect(createInfo(500).formattedFileSize, '500 B');
    expect(createInfo(1023).formattedFileSize, '1023 B');
    expect(createInfo(1024).formattedFileSize, '1.0 KB');
    expect(createInfo(1536).formattedFileSize, '1.5 KB'); // 1.5 * 1024
    expect(createInfo(1024 * 1024).formattedFileSize, '1.00 MB');
    expect(
      createInfo((1.43 * 1024 * 1024).round()).formattedFileSize,
      '1.43 MB',
    );
  });
}
