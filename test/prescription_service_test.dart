import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/prescription/services/prescription_service.dart';

void main() {
  group('PrescriptionService', () {
    final service = PrescriptionService();

    test('extracts English medicines with strengths and formulations', () {
      const text = '''
      Doctor: Dr. Rahman
      Date: 2026-11-03
      1. Tab. Paracetamol 500mg
      2. Cap. Amoxicillin 250 mg
      Drink plenty of fresh water
      3. Syrup Antacid 100ml
      ''';

      final results = service.extract(text);

      expect(results, hasLength(3));
      expect(results[0].name, contains('Paracetamol 500mg'));
      expect(results[1].name, contains('Amoxicillin 250 mg'));
      expect(results[2].name, contains('Syrup Antacid 100ml'));
    });

    test('extracts Bengali medicines with dosage indicators', () {
      const text = '''
      রোগীর নাম: করিম
      ১. ট্যাবলেট নাপা ৫০০ মিগ্রা
      ২. ক্যাপসুল ওমেপ্রাজল ২০ মিগ্রা
      ৩. ১+০+১ খাবার পর
      ''';

      final results = service.extract(text);

      expect(results.length, greaterThanOrEqualTo(2));
      expect(results.any((c) => c.name.contains('নাপা')), isTrue);
      expect(results.any((c) => c.name.contains('ওমেপ্রাজল')), isTrue);
    });

    test('ignores normal everyday Bangla sentences with common words like দিন or বার', () {
      const text = '''
      আমাকে প্রয়োজনীয় অনুমতি দিন
      আজকে রবিবার ছুটির দিন
      দয়া করে অপেক্ষা করুন
      ''';

      final results = service.extract(text);

      expect(results, isEmpty);
    });
  });
}
