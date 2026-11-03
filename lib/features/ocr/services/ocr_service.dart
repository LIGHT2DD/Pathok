import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import '../models/ocr_result.dart';
import 'image_preprocessor.dart';

class OfflineOcrService {
  /// Robust, multi-pass offline OCR recognizing Bengali & English text from documents
  Future<OcrResult> recognize(String path) async {
    // Single-pass quality evaluation and image preconditioning (single decode, no redundant I/O)
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
      // Pass 1: Standard structured page segmentation (PSM 3) on enhanced image
      String text = (await FlutterTesseractOcr.extractText(
        preparedPath,
        language: 'ben+eng',
        args: <String, String>{
          'psm': '3',
          'preserve_interword_spaces': '1',
        },
      )).trim();

      // Pass 2: If Pass 1 yielded no text, fallback to uniform text block mode (PSM 6)
      // Particularly effective for prescription lines, receipts, and medicine packaging
      if (text.isEmpty) {
        text = (await FlutterTesseractOcr.extractText(
          preparedPath,
          language: 'ben+eng',
          args: <String, String>{
            'psm': '6',
            'preserve_interword_spaces': '1',
          },
        )).trim();
      }

      // Pass 3: If still empty, try raw original image with single-column mode (PSM 4)
      if (text.isEmpty && preparedPath != path) {
        text = (await FlutterTesseractOcr.extractText(
          path,
          language: 'ben+eng',
          args: <String, String>{
            'psm': '4',
            'preserve_interword_spaces': '1',
          },
        )).trim();
      }

      // Clean up temporary preprocessed file if different
      if (preparedPath != path) {
        final tempFile = File(preparedPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      return OcrResult(
        text: text,
        quality: quality,
        confidenceLabel: text.isNotEmpty ? 'অফলাইন Tesseract 4 (ben+eng)' : 'কোনো লেখা পাওয়া যায়নি',
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
