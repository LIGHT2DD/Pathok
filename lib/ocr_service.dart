import 'dart:io';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrQualityResult {
  const OcrQualityResult({
    required this.isUsable,
    required this.message,
  });

  final bool isUsable;
  final String message;
}

class OcrResult {
  const OcrResult({
    required this.text,
    required this.quality,
    required this.confidenceLabel,
  });

  final String text;
  final OcrQualityResult quality;
  final String confidenceLabel;
}

class OfflineOcrService {
  Future<OcrResult> recognize(String path) async {
    final quality = await _checkQuality(path);
    if (!quality.isUsable) {
      return OcrResult(
        text: '',
        quality: quality,
        confidenceLabel: 'নির্ধারণ করা যায়নি',
      );
    }

    final text = (await FlutterTesseractOcr.extractText(
      path,
      language: 'ben+eng',
      args: <String, String>{
        'psm': '3',
        'preserve_interword_spaces': '1',
      },
    ))
        .trim();
    return OcrResult(
      text: text,
      quality: quality,
      confidenceLabel: 'Tesseract confidence দেয়নি; ফলাফল যাচাই করুন',
    );
  }

  Future<OcrQualityResult> _checkQuality(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const OcrQualityResult(
        isUsable: false,
        message: 'ছবির ফাইলটি পাওয়া যায়নি।',
      );
    }
    final size = await file.length();
    if (size < 10 * 1024) {
      return const OcrQualityResult(
        isUsable: false,
        message: 'ছবিটি খুব ছোট বা অস্পষ্ট হতে পারে। পরিষ্কার ছবি নিন।',
      );
    }
    return const OcrQualityResult(
      isUsable: true,
      message: 'ছবির মৌলিক মান যাচাই হয়েছে।',
    );
  }

  Future<void> close() async {}
}
