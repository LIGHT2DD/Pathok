import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../core/security/secure_data_store.dart';
import '../../ocr/services/image_preprocessor.dart';
import '../models/local_document.dart';

class DocumentRepository {
  DocumentRepository({SecureDataStore? secureStore})
      : _store = secureStore ?? SecureDataStore.instance;

  final SecureDataStore _store;

  /// Loads all stored documents and sorts them by most recently updated
  Future<List<LocalDocument>> getDocuments() async {
    final payload = await _store.read();
    final docList = payload['documents'] as List<dynamic>? ?? <dynamic>[];

    final documents = docList.map((value) {
      if (value is String) {
        return LocalDocument.fromJson(jsonDecode(value) as Map<String, dynamic>);
      }
      return LocalDocument.fromJson(value as Map<String, dynamic>);
    }).toList();

    documents.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return documents;
  }

  /// Saves the complete list of documents to encrypted storage using clean single JSON serialization
  Future<void> saveDocuments(List<LocalDocument> documents) async {
    final payload = await _store.read();
    payload['documents'] = documents
        .map((document) => document.toJson())
        .toList();
    await _store.write(payload);
  }

  /// Copies an external file into private app storage and creates a LocalDocument
  Future<LocalDocument> importFile({
    required String sourcePath,
    required String title,
    required String fileType,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = sourcePath.split('.').last;
    final targetPath = '${directory.path}/doc_${DateTime.now().microsecondsSinceEpoch}.$extension';

    // Copy source file to private directory
    await File(sourcePath).copy(targetPath);

    // Generate lightweight thumbnail for image documents to minimize UI rasterization latency
    String? thumbnailPath;
    if (fileType == 'image') {
      thumbnailPath = await ImagePreprocessor.generateThumbnail(targetPath);
    }

    return LocalDocument(
      title: title,
      sourcePath: targetPath,
      thumbnailPath: thumbnailPath,
      text: '',
      fileType: fileType,
    );
  }

  /// Renames a document and updates storage
  Future<void> renameDocument(
    List<LocalDocument> currentList,
    LocalDocument target,
    String newTitle,
  ) async {
    target.title = newTitle;
    target.updatedAt = DateTime.now();
    await saveDocuments(currentList);
  }

  /// Toggles document pinned status and re-sorts
  Future<void> togglePinDocument(
    List<LocalDocument> currentList,
    LocalDocument target,
  ) async {
    target.isPinned = !target.isPinned;
    target.updatedAt = DateTime.now();
    currentList.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    await saveDocuments(currentList);
  }

  /// Deletes a document, cleans up its local storage file, and updates persistence
  Future<void> deleteDocument(
    List<LocalDocument> currentList,
    LocalDocument target,
  ) async {
    final file = File(target.sourcePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }

    if (target.thumbnailPath != null) {
      final thumbFile = File(target.thumbnailPath!);
      if (await thumbFile.exists()) {
        try {
          await thumbFile.delete();
        } catch (_) {}
      }
    }

    currentList.removeWhere((d) => d.id == target.id);
    await saveDocuments(currentList);
  }

  /// Deletes all documents, their files, and clears secure storage
  Future<void> deleteAll(List<LocalDocument> documents) async {
    for (final document in documents) {
      final file = File(document.sourcePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      if (document.thumbnailPath != null) {
        final thumbFile = File(document.thumbnailPath!);
        if (await thumbFile.exists()) {
          try {
            await thumbFile.delete();
          } catch (_) {}
        }
      }
    }
    documents.clear();
    await _store.clear();
  }
}
