import 'dart:math';

class LocalDocument {
  LocalDocument({
    String? id,
    required this.title,
    required this.sourcePath,
    this.thumbnailPath,
    required this.text,
    this.translatedText,
    this.detectedLanguage,
    required this.fileType,
    this.category = 'general',
    this.isPinned = false,
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
  String? translatedText;
  String? detectedLanguage;
  final String fileType;
  String category;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;

  static String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Automatically categorizes documents based on OCR text keywords and title
  static String detectCategory(String text, String title) {
    final lower = '$title $text'.toLowerCase();

    // Prescription keywords
    if (lower.contains(RegExp(
      r'(?:rx|dr\.|doctor|patient|dosage|mg|ml|mcg|প্রেসক্রিপশন|ট্যাবলেট|ক্যাপসুল|সিরাপ|ড্রপ|ইনজেকশন|ডাক্তার|হাসপাতাল)',
      caseSensitive: false,
    ))) {
      return 'prescription';
    }

    // Bill / Invoice keywords
    if (lower.contains(RegExp(
      r'(?:bill|invoice|receipt|vat|tax|total|amount|bdt|tk|টাকা|রসিদ|ভাউচার|বিল|বিদ্যুৎ|গ্যাস|মিটার|পরিশোধ)',
      caseSensitive: false,
    ))) {
      return 'bill';
    }

    // Study & Books keywords
    if (lower.contains(RegExp(
      r'(?:chapter|lesson|textbook|lecture|homework|assignment|exam|syllabus|বই|অধ্যায়|পাঠ|পড়াশোনা|লেকচার|প্রশ্ন|পরীক্ষা|সিলেবাস)',
      caseSensitive: false,
    ))) {
      return 'study';
    }

    // Official Identity / Cards keywords
    if (lower.contains(RegExp(
      r'(?:nid|national id|identification|passport|birth|certificate|ভোটার|জাতীয় পরিচয়পত্র|পাসপোর্ট|জন্ম নিবন্ধন|স্মার্ট কার্ড)',
      caseSensitive: false,
    ))) {
      return 'id_card';
    }

    return 'general';
  }

  LocalDocument copyWith({
    String? title,
    String? text,
    String? translatedText,
    String? detectedLanguage,
    String? thumbnailPath,
    String? category,
    bool? isPinned,
  }) {
    return LocalDocument(
      id: id,
      title: title ?? this.title,
      sourcePath: sourcePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      text: text ?? this.text,
      translatedText: translatedText ?? this.translatedText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      fileType: fileType,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
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
        if (translatedText != null) 'translatedText': translatedText,
        if (detectedLanguage != null) 'detectedLanguage': detectedLanguage,
        'fileType': fileType,
        'category': category,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LocalDocument.fromJson(Map<String, dynamic> json) => LocalDocument(
        id: json['id'] as String?,
        title: json['title'] as String? ?? 'নথি',
        sourcePath: json['sourcePath'] as String? ?? '',
        thumbnailPath: json['thumbnailPath'] as String?,
        text: json['text'] as String? ?? '',
        translatedText: json['translatedText'] as String?,
        detectedLanguage: json['detectedLanguage'] as String?,
        fileType: json['fileType'] as String? ?? 'image',
        category: json['category'] as String? ?? 'general',
        isPinned: json['isPinned'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}
