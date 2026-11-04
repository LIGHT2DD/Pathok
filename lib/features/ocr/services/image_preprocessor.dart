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
  /// bakes EXIF orientation, clamps dimensions, converts to gentle grayscale,
  /// and writes a lossless intermediate PNG (0 compression artifacts) for Tesseract.
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
    final targetPath = '${tempDir.path}/ocr_prep_${DateTime.now().microsecondsSinceEpoch}.png';

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
        // Upscale small crops (< 900px) so Bengali glyph diacritics are sharp
        if (image.width < 900 && image.height < 900) {
          final scale = 1200 / (image.width > image.height ? image.width : image.height);
          image = img.copyResize(
            image,
            width: (image.width * scale).toInt(),
            height: (image.height * scale).toInt(),
            interpolation: img.Interpolation.linear,
          );
        } else if (image.width > 2400 || image.height > 2400) {
          // Clamp overly large images to prevent excessive memory usage while keeping high DPI
          if (image.width > image.height) {
            image = img.copyResize(image, width: 2400);
          } else {
            image = img.copyResize(image, height: 2400);
          }
        }

        // Illumination normalization: gentle contrast enhancement without bleaching diacritics
        image = _normalizeShadowsAndEnhance(image);

        // Lossless PNG encoding: completely eliminates lossy JPEG 8x8 DCT ringing noise
        // which Tesseract commonly misinterprets as punctuation or trash characters
        final encoded = img.encodePng(image);
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

  /// Normalizes illumination to eliminate room shadows while preserving fine Bangla diacritics
  static img.Image _normalizeShadowsAndEnhance(img.Image image) {
    var enhanced = img.grayscale(image);

    // Balanced contrast & gamma: removes faint shadows without bleaching out light ink or handwriting
    enhanced = img.adjustColor(
      enhanced,
      contrast: 1.12,
      brightness: 1.00,
      gamma: 0.98,
    );

    return enhanced;
  }
}
