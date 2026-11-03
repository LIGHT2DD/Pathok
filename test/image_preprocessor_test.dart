import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/ocr/services/image_preprocessor.dart';

void main() {
  group('ImagePreprocessor', () {
    test('reports unusable when file does not exist', () async {
      final result = await ImagePreprocessor.checkQuality('/non/existent/path/photo.jpg');

      expect(result.isUsable, isFalse);
      expect(result.message, contains('পাওয়া যায়নি'));
    });
  });
}

