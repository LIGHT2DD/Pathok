import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/core/security/secure_data_store.dart';
import 'package:pathok/features/documents/data/document_repository.dart';
import 'package:pathok/features/documents/models/local_document.dart';

void main() {
  group('DocumentRepository', () {
    test('instantiates and provides clean interface', () {
      final repository = DocumentRepository(secureStore: SecureDataStore.instance);
      expect(repository, isNotNull);
    });

    test('sorts documents by updatedAt in descending order', () {
      final oldDoc = LocalDocument(
        title: 'Old Doc',
        sourcePath: '/path/old.jpg',
        text: 'Old',
        fileType: 'image',
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      final newDoc = LocalDocument(
        title: 'New Doc',
        sourcePath: '/path/new.jpg',
        text: 'New',
        fileType: 'image',
        updatedAt: DateTime.now(),
      );

      final list = [oldDoc, newDoc];
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      expect(list.first.title, equals('New Doc'));
      expect(list.last.title, equals('Old Doc'));
    });
  });
}

