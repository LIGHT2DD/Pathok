import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/ocr_result.dart';

class ProcessedImageResult {
  const ProcessedImageResult({
    required this.quality,
    required this.preparedPath,
  });

  final OcrQualityResult quality;
  final String preparedPath;
}

class ImagePreprocessor {
  const ImagePreprocessor._();

  /// Single-pass image quality assessment and OCR preconditioning.
  /// Decodes image once in a background isolate, validates readability,
  /// bakes EXIF orientation, clamps dimensions, converts to high-contrast grayscale,
  /// and writes an optimized intermediate JPEG for Tesseract.
  static Future<ProcessedImageResult> processAndPrepare(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return ProcessedImageResult(
        quality: const OcrQualityResult(
          isUsable: false,
          message: 'ছবির ফাইলটি পাওয়া যায়নি।',
        ),
        preparedPath: path,
      );
    }

    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/ocr_prep_${DateTime.now().microsecondsSinceEpoch}.jpg';

    return await Isolate.run(() {
      try {
        final targetFile = File(path);
        if (!targetFile.existsSync()) {
          return ProcessedImageResult(
            quality: const OcrQualityResult(
              isUsable: false,
              message: 'ছবির ফাইলটি পাওয়া যায়নি।',
            ),
            preparedPath: path,
          );
        }

        final bytes = targetFile.readAsBytesSync();
        if (bytes.isEmpty) {
          return ProcessedImageResult(
            quality: const OcrQualityResult(
              isUsable: false,
              message: 'ছবির ফাইলটি খালি।',
            ),
            preparedPath: path,
          );
        }

        var image = img.decodeImage(bytes);
        if (image == null) {
          return ProcessedImageResult(
            quality: const OcrQualityResult(
              isUsable: false,
              message: 'ছবির ফরম্যাট সমর্থিত নয় বা ফাইলটি নষ্ট।',
            ),
            preparedPath: path,
          );
        }

        final origWidth = image.width;
        final origHeight = image.height;

        // Fix EXIF rotation from mobile cameras
        image = img.bakeOrientation(image);

        // Optimal scaling for OCR:
        // Upscale small crops (< 1000px) so Bengali glyph diacritics are sharp
        if (image.width < 1000 && image.height < 1000) {
          final scale = 1200 / (image.width > image.height ? image.width : image.height);
          image = img.copyResize(
            image,
            width: (image.width * scale).toInt(),
            height: (image.height * scale).toInt(),
            interpolation: img.Interpolation.linear,
          );
        } else if (image.width > 2200 || image.height > 2200) {
          // Clamp overly large images to prevent excessive memory usage
          if (image.width > image.height) {
            image = img.copyResize(image, width: 2200);
          } else {
            image = img.copyResize(image, height: 2200);
          }
        }

        // Convert to grayscale and apply contrast normalization
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.25, brightness: 1.03);

        // Optimal quality (82): fast encoding, lightweight file, no degradation in OCR accuracy
        final encoded = img.encodeJpg(image, quality: 82);
        File(targetPath).writeAsBytesSync(encoded);

        return ProcessedImageResult(
          quality: OcrQualityResult(
            isUsable: true,
            width: origWidth,
            height: origHeight,
            message: 'ছবির কোয়ালিটি প্রস্তুত ($origWidth x $origHeight)।',
          ),
          preparedPath: targetPath,
        );
      } catch (_) {
        return ProcessedImageResult(
          quality: const OcrQualityResult(
            isUsable: true,
            message: 'ছবি লোড হয়েছে।',
          ),
          preparedPath: path,
        );
      }
    });
  }

  /// Validates file existence and basic readability
  static Future<OcrQualityResult> checkQuality(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const OcrQualityResult(
        isUsable: false,
        message: 'ছবির ফাইলটি পাওয়া যায়নি।',
      );
    }

    return await Isolate.run(() {
      try {
        final bytes = File(path).readAsBytesSync();
        if (bytes.isEmpty) {
          return const OcrQualityResult(
            isUsable: false,
            message: 'ছবির ফাইলটি খালি।',
          );
        }

        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          return const OcrQualityResult(
            isUsable: false,
            message: 'ছবির ফরম্যাট সমর্থিত নয় বা ফাইলটি নষ্ট।',
          );
        }

        return OcrQualityResult(
          isUsable: true,
          width: decoded.width,
          height: decoded.height,
          message: 'ছবির কোয়ালিটি প্রস্তুত (${decoded.width}x${decoded.height})।',
        );
      } catch (_) {
        return const OcrQualityResult(
          isUsable: true,
          message: 'ছবি লোড হয়েছে।',
        );
      }
    });
  }

  /// Preprocesses image using single-pass pipeline
  static Future<String> prepareForOcr(String path) async {
    final result = await processAndPrepare(path);
    return result.preparedPath;
  }

  /// Generates a lightweight, fast thumbnail for instant UI card rendering without loading full raw image
  static Future<String?> generateThumbnail(String path) async {
    try {
      final thumbPath = path.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '_thumb.jpg');
      return await Isolate.run(() {
        final file = File(path);
        if (!file.existsSync()) return null;
        final bytes = file.readAsBytesSync();
        var imgObj = img.decodeImage(bytes);
        if (imgObj == null) return null;
        imgObj = img.bakeOrientation(imgObj);
        final thumb = img.copyResize(imgObj, width: 400, interpolation: img.Interpolation.linear);
        final encoded = img.encodeJpg(thumb, quality: 75);
        File(thumbPath).writeAsBytesSync(encoded);
        return thumbPath;
      });
    } catch (_) {
      return null;
    }
  }
}
