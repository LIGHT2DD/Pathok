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

    test('serializes to and from json accurately', () {
      final original = LocalDocument(
        id: 'test-uuid-1234',
        title: 'Prescription',
        sourcePath: '/data/presc.jpg',
        text: 'Napa 500mg',
        fileType: 'image',
      );

      final json = original.toJson();
      final restored = LocalDocument.fromJson(json);

      expect(restored.id, equals('test-uuid-1234'));
      expect(restored.title, equals('Prescription'));
      expect(restored.sourcePath, equals('/data/presc.jpg'));
      expect(restored.text, equals('Napa 500mg'));
      expect(restored.fileType, equals('image'));
    });

    test('copyWith updates fields and updatedAt timestamp', () {
      final original = LocalDocument(
        title: 'Original Title',
        sourcePath: '/path/doc.jpg',
        text: 'Initial text',
        fileType: 'image',
      );

      final modified = original.copyWith(
        title: 'Updated Title',
        text: 'Edited recognized text',
      );

      expect(modified.id, equals(original.id));
      expect(modified.title, equals('Updated Title'));
      expect(modified.text, equals('Edited recognized text'));
      expect(modified.sourcePath, equals(original.sourcePath));
    });
  });
}

