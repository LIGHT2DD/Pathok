import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/ocr/services/ocr_text_sanitizer.dart';

void main() {
  group('OcrTextSanitizer', () {
    test('removes isolated garbage symbols and replaces pipes with Bengali dari', () {
      const noisyText = 'প্যারাসিটামল ৫০০ মি.গ্রা. | দিনে ২ বার ~ ^ _ খাবারের পর';
      final cleaned = OcrTextSanitizer.sanitize(noisyText);

      expect(cleaned.contains('।'), isTrue);
      expect(cleaned.contains('~'), isFalse);
      expect(cleaned.contains('^'), isFalse);
      expect(cleaned.contains('_'), isFalse);
      expect(cleaned.contains('প্যারাসিটামল ৫০০ মি.গ্রা.'), isTrue);
    });

    test('repairs broken spaces between Bengali consonants and vowel diacritics', () {
      const brokenText = 'ক া ল ক ে   ব ি দ ্য ু ৎ   ব ি ল';
      final cleaned = OcrTextSanitizer.sanitize(brokenText);

      expect(cleaned.contains('কা'), isTrue);
      expect(cleaned.contains('বি'), isTrue);
    });

    test('reconstructs natural paragraphs from soft-wrapped OCR lines', () {
      const fragmentedText = 'এটি একটি গুরুত্বপূর্ণ নোটিশ\nযা সকল শিক্ষার্থীদের জন্য\nপ্রযোজ্য।\n\n১. সময়মত উপস্থিত থাকুন।';
      final formatted = OcrTextSanitizer.formatLayout(fragmentedText);

      // Lines without terminal punctuation should merge into one paragraph
      expect(formatted.contains('এটি একটি গুরুত্বপূর্ণ নোটিশ যা সকল শিক্ষার্থীদের জন্য প্রযোজ্য।'), isTrue);
      // Lists should remain preserved on new block
      expect(formatted.contains('১. সময়মত উপস্থিত থাকুন।'), isTrue);
    });
  });
}

