import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/documents/models/local_document.dart';

void main() {
  group('LocalDocument Model', () {
    test('generates unique id and timestamps automatically', () {
      final doc1 = LocalDocument(
        title: 'Doc 1',
        sourcePath: '/path/1.jpg',
        text: 'Text 1',
        fileType: 'image',
      );

      final doc2 = LocalDocument(
        title: 'Doc 2',
        sourcePath: '/path/2.pdf',
        text: 'Text 2',
        fileType: 'pdf',
      );

      expect(doc1.id, isNotEmpty);
      expect(doc2.id, isNotEmpty);
      expect(doc1.id, isNot(equals(doc2.id)));
      expect(doc1.createdAt, isNotNull);
      expect(doc1.updatedAt, isNotNull);
    });

    test('serializes to and from json accurately with category and pinning', () {
      final original = LocalDocument(
        id: 'test-uuid-1234',
        title: 'Prescription',
        sourcePath: '/data/presc.jpg',
        thumbnailPath: '/data/presc_thumb.jpg',
        text: 'Napa 500mg',
        fileType: 'image',
        category: 'prescription',
        isPinned: true,
      );

      final json = original.toJson();
      final restored = LocalDocument.fromJson(json);

      expect(restored.id, equals('test-uuid-1234'));
      expect(restored.title, equals('Prescription'));
      expect(restored.sourcePath, equals('/data/presc.jpg'));
      expect(restored.thumbnailPath, equals('/data/presc_thumb.jpg'));
      expect(restored.text, equals('Napa 500mg'));
      expect(restored.fileType, equals('image'));
      expect(restored.category, equals('prescription'));
      expect(restored.isPinned, isTrue);
    });

    test('copyWith updates fields, category, and isPinned', () {
      final original = LocalDocument(
        title: 'Original Title',
        sourcePath: '/path/doc.jpg',
        text: 'Initial text',
        fileType: 'image',
      );

      final modified = original.copyWith(
        title: 'Updated Title',
        text: 'Edited recognized text',
        category: 'bill',
        isPinned: true,
      );

      expect(modified.id, equals(original.id));
      expect(modified.title, equals('Updated Title'));
      expect(modified.text, equals('Edited recognized text'));
      expect(modified.category, equals('bill'));
      expect(modified.isPinned, isTrue);
    });

    test('detectCategory accurately categorizes documents by text keywords', () {
      expect(
        LocalDocument.detectCategory('ডাক্তারের প্রেসক্রিপশন নাপা ৫০০ মিগ্রা', 'প্রেসক্রিপশন'),
        equals('prescription'),
      );
      expect(
        LocalDocument.detectCategory('বিদ্যুৎ বিল পরিশোধের মোট টাকা ৫০০', 'Electricity Bill'),
        equals('bill'),
      );
      expect(
        LocalDocument.detectCategory('গণপ্রজাতন্ত্রী বাংলাদেশ জাতীয় পরিচয়পত্র NID No 1234', 'Smart NID'),
        equals('id_card'),
      );
      expect(
        LocalDocument.detectCategory('আজকের মিটিং নোট এবং পরিকল্পনা', 'Notes'),
        equals('general'),
      );
    });
  });
}
