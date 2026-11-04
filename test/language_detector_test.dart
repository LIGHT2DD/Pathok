import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:pathok/features/documents/services/language_detector.dart';

void main() {
  group('LanguageDetector', () {
    test('detects pure Bengali text accurately', () {
      const text = 'পাঠক একটি চমৎকার অফলাইন সহায়ক অ্যাপ যা সবার কাজে আসে।';
      final result = LanguageDetector.detect(text);
      expect(result.type, LanguageType.bengali);
      expect(result.locale, 'bn-BD');
      expect(result.bengaliRatio, greaterThan(0.9));
      expect(result.flag, '🇧🇩');
    });

    test('detects pure English text accurately', () {
      const text = 'Pathok is an offline-first assistant for document reading.';
      final result = LanguageDetector.detect(text);
      expect(result.type, LanguageType.english);
      expect(result.locale, 'en-US');
      expect(result.englishRatio, greaterThan(0.9));
      expect(result.flag, '🇬🇧');
    });

    test('detects mixed bilingual prescription accurately', () {
      const text = 'Tab Napa Extend 665mg\nপ্রতিদিন খাবার পর ১টি করে খাবেন ৭ দিন।';
      final result = LanguageDetector.detect(text);
      expect(result.type, LanguageType.mixed);
      expect(result.flag, '🌐');
      expect(result.bengaliRatio, greaterThan(0.2));
      expect(result.englishRatio, greaterThan(0.2));
    });

    test('segments text for code-switching TTS', () {
      const text = 'Tab Napa 500mg.\nখাবার পর খাবেন।';
      final segments = LanguageDetector.segmentByLanguage(text);
      expect(segments.length, 2);
      expect(segments[0].locale, 'en-US');
      expect(segments[1].locale, 'bn-BD');
    });

    test('ML Kit TranslateLanguage enums are accessible', () {
      expect(TranslateLanguage.bengali.bcpCode, 'bn');
      expect(TranslateLanguage.english.bcpCode, 'en');

      final translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.bengali,
      );
      expect(translator.sourceLanguage, TranslateLanguage.english);
      expect(translator.targetLanguage, TranslateLanguage.bengali);
      final manager = OnDeviceTranslatorModelManager();
      expect(manager, isNotNull);
    });
  });
}
