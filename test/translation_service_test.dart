import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/documents/services/translation_service.dart';

void main() {
  group('PrescriptionOfflineTranslator', () {
    test('translates prescription dosages, frequencies, and instructions accurately to Bengali', () {
      const input = 'Tab Napa 500mg 1+0+1 after meal for 5 days with water';
      final result = PrescriptionOfflineTranslator.translateToBengali(input);

      expect(result.contains('ট্যাবলেট'), isTrue);
      expect(result.contains('৫০০ মি.গ্রা.'), isTrue);
      expect(result.contains('সকালে ১টি এবং রাতে ১টি'), isTrue);
      expect(result.contains('খাবারের পর'), isTrue);
      expect(result.contains('৫ দিনের জন্য'), isTrue);
      expect(result.contains('পানির সাথে'), isTrue);
    });

    test('translates document headings like Prescription and Due Date', () {
      const input = 'Prescription: Patient Name John, Bill Due Date: 12';
      final result = PrescriptionOfflineTranslator.translateToBengali(input);

      expect(result.contains('প্রেসক্রিপশন'), isTrue);
      expect(result.contains('রোগীর নাম'), isTrue);
      expect(result.contains('বিল'), isTrue);
      expect(result.contains('পরিশোধের শেষ তারিখ'), isTrue);
    });

    test('converts numbers to Bengali digits', () {
      expect(PrescriptionOfflineTranslator.toBengaliDigits('1234567890'), '১২৩৪৫৬৭৮৯০');
    });

    test('translates study, bills, and general terms accurately to Bengali', () {
      const input = 'Chapter 1: Student Question and Answer. Electricity Bill Total Amount: 500';
      final result = PrescriptionOfflineTranslator.translateToBengali(input);

      expect(result.contains('অধ্যায়'), isTrue);
      expect(result.contains('শিক্ষার্থী'), isTrue);
      expect(result.contains('প্রশ্ন'), isTrue);
      expect(result.contains('উত্তর'), isTrue);
      expect(result.contains('বিদ্যুৎ'), isTrue);
      expect(result.contains('বিল'), isTrue);
      expect(result.contains('মোট পরিমাণ'), isTrue);
    });

    test('translates Bengali terms back to English accurately', () {
      const input = 'প্রেসক্রিপশন: রোগীর নাম, পরিশোধের শেষ তারিখ, ওষুধ ও অধ্যায়';
      final result = PrescriptionOfflineTranslator.translateToEnglish(input);

      expect(result.contains('Prescription'), isTrue);
      expect(result.contains('Patient Name'), isTrue);
      expect(result.contains('Due Date'), isTrue);
      expect(result.contains('Medicine'), isTrue);
      expect(result.contains('Chapter'), isTrue);
    });
  });
}
