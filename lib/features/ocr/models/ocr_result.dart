class OcrQualityResult {
  const OcrQualityResult({
    required this.isUsable,
    required this.message,
    this.width = 0,
    this.height = 0,
  });

  final bool isUsable;
  final String message;
  final int width;
  final int height;
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

