import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import '../models/ocr_result.dart';
import 'image_preprocessor.dart';
import 'ocr_text_sanitizer.dart';

class OfflineOcrService {
  /// Robust, multi-pass offline OCR recognizing Bengali & English text from documents
  Future<OcrResult> recognize(String path) async {
    // Single-pass quality evaluation and image preconditioning (lossless PNG, gentle contrast)
    final processed = await ImagePreprocessor.processAndPrepare(path);
    final quality = processed.quality;
    if (!quality.isUsable) {
      return OcrResult(
        text: '',
        quality: quality,
        confidenceLabel: 'ছবির ফাইল অ্যাক্সেস করা যায়নি',
      );
    }

    final preparedPath = processed.preparedPath;

    try {
      // Pass 1: Uniform block mode (PSM 6) on enhanced lossless PNG
      // Substantially superior accuracy for book pages, study notes, bills, and prescriptions
      String rawText = (await FlutterTesseractOcr.extractText(
        preparedPath,
        language: 'ben+eng',
        args: <String, String>{
          'psm': '6',
          'preserve_interword_spaces': '1',
        },
      )).trim();

      // Pass 2: If Pass 1 yielded no text or very sparse output, fallback to structured auto mode (PSM 3)
      if (rawText.isEmpty || rawText.length < 5) {
        rawText = (await FlutterTesseractOcr.extractText(
          preparedPath,
          language: 'ben+eng',
          args: <String, String>{
            'psm': '3',
            'preserve_interword_spaces': '1',
          },
        )).trim();
      }

      // Pass 3: If still empty, try raw source image directly with single-column mode (PSM 4)
      if (rawText.isEmpty && preparedPath != path) {
        rawText = (await FlutterTesseractOcr.extractText(
          path,
          language: 'ben+eng',
          args: <String, String>{
            'psm': '4',
            'preserve_interword_spaces': '1',
          },
        )).trim();
      }

      // Clean up temporary preprocessed file
      if (preparedPath != path) {
        final tempFile = File(preparedPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      // Post-Processing: Strip noise characters and reconstruct natural flowing paragraph layout
      final sanitized = OcrTextSanitizer.sanitize(rawText);
      final formattedText = OcrTextSanitizer.formatLayout(sanitized);

      return OcrResult(
        text: formattedText.isNotEmpty ? formattedText : sanitized,
        quality: quality,
        confidenceLabel: formattedText.isNotEmpty ? 'অফলাইন Tesseract 4 (ben+eng)' : 'কোনো লেখা পাওয়া যায়নি',
      );
    } catch (e) {
      // Clean up temporary file on error
      if (preparedPath != path) {
        try {
          final tempFile = File(preparedPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }

      return OcrResult(
        text: '',
        quality: quality,
        confidenceLabel: 'OCR ত্রুটি: $e',
      );
    }
  }

  Future<void> close() async {}
}
