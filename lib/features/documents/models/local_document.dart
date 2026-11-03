import 'dart:math';

class LocalDocument {
  LocalDocument({
    String? id,
    required this.title,
    required this.sourcePath,
    this.thumbnailPath,
    required this.text,
    required this.fileType,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _generateId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  final String sourcePath;
  final String? thumbnailPath;
  String text;
  final String fileType;
  final DateTime createdAt;
  DateTime updatedAt;

  static String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  LocalDocument copyWith({
    String? title,
    String? text,
    String? thumbnailPath,
  }) {
    return LocalDocument(
      id: id,
      title: title ?? this.title,
      sourcePath: sourcePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      text: text ?? this.text,
      fileType: fileType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourcePath': sourcePath,
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        'text': text,
        'fileType': fileType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LocalDocument.fromJson(Map<String, dynamic> json) => LocalDocument(
        id: json['id'] as String?,
        title: json['title'] as String? ?? 'নথি',
        sourcePath: json['sourcePath'] as String? ?? '',
        thumbnailPath: json['thumbnailPath'] as String?,
        text: json['text'] as String? ?? '',
        fileType: json['fileType'] as String? ?? 'image',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}
