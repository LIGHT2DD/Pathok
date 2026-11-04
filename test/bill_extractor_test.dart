import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/documents/services/bill_extractor.dart';

void main() {
  group('BillExtractor', () {
    test('extracts DESCO electricity bill fields accurately', () {
      const text = '''
      Dhaka Electric Supply Company Ltd. (DESCO)
      Consumer Bill for Electricity
      Account No: 48920185
      Meter Number: 1049285
      Total Amount: 1,450.50 BDT
      Due Date: 28/11/2026
      Please pay before due date.
      ''';

      final result = BillExtractor.extract(text, 'DESCO Electricity Bill');
      expect(result.isBill, isTrue);
      expect(result.billerName?.contains('DESCO'), isTrue);
      expect(result.totalAmount, equals('1,450.50 ৳'));
      expect(result.dueDate, equals('28/11/2026'));
      expect(result.accountNumber, equals('48920185'));
    });

    test('extracts Bengali bill terms and dates accurately', () {
      const text = '''
      ঢাকা ওয়াসা পানি বিল
      গ্রাহক হিসাব: ৮৪৯২০০০১
      মোট টাকা: ৳ ৮৫০
      পরিশোধের শেষ তারিখ: ২৫/১২/২০২৬
      ''';

      final result = BillExtractor.extract(text, 'ওয়াসা বিল');
      expect(result.isBill, isTrue);
      expect(result.billerName?.contains('ওয়াসা'), isTrue);
      expect(result.totalAmount, contains('৮৫০'));
      expect(result.dueDate, equals('২৫/১২/২০২৬'));
    });

    test('returns isBill false on non-bill documents', () {
      const text = 'Today we discussed history chapter 4 and the syllabus.';
      final result = BillExtractor.extract(text, 'Class Lecture Note');
      expect(result.isBill, isFalse);
    });
  });
}

