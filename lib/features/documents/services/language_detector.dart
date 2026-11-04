import 'dart:math';

enum LanguageType {
  bengali,
  english,
  mixed,
  unknown,
}

class LanguageDetectionResult {
  const LanguageDetectionResult({
    required this.type,
    required this.locale,
    required this.bengaliRatio,
    required this.englishRatio,
    required this.confidence,
    required this.label,
    required this.shortLabel,
    required this.flag,
  });

  final LanguageType type;
  final String locale; // 'bn-BD' or 'en-US'
  final double bengaliRatio;
  final double englishRatio;
  final double confidence;
  final String label;
  final String shortLabel;
  final String flag;

  bool get isBengali => type == LanguageType.bengali;
  bool get isEnglish => type == LanguageType.english;
  bool get isMixed => type == LanguageType.mixed;
}

class LanguageSegment {
  const LanguageSegment({
    required this.text,
    required this.locale,
    required this.startOffset,
    required this.endOffset,
  });

  final String text;
  final String locale; // 'bn-BD' or 'en-US'
  final int startOffset;
  final int endOffset;
}

class LanguageDetector {
  static final RegExp _boundaryRegex = RegExp(r'([।\n.!?]+)');

  /// Analyzes script distribution and returns classification & confidence
  static LanguageDetectionResult detect(String text) {
    if (text.trim().isEmpty) {
      return const LanguageDetectionResult(
        type: LanguageType.unknown,
        locale: 'bn-BD',
        bengaliRatio: 0.0,
        englishRatio: 0.0,
        confidence: 0.0,
        label: 'অনির্ধারিত',
        shortLabel: 'অজানা',
        flag: '📄',
      );
    }

    int bengaliCount = 0;
    int englishCount = 0;

    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      // Bengali Unicode range: 0x0980 to 0x09FF
      if (codeUnit >= 0x0980 && codeUnit <= 0x09FF) {
        bengaliCount++;
      } else if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
          (codeUnit >= 0x0061 && codeUnit <= 0x007A)) {
        // Latin letters A-Z, a-z
        englishCount++;
      }
    }

    final totalLetters = bengaliCount + englishCount;
    if (totalLetters == 0) {
      return const LanguageDetectionResult(
        type: LanguageType.unknown,
        locale: 'bn-BD',
        bengaliRatio: 0.0,
        englishRatio: 0.0,
        confidence: 0.0,
        label: 'অনির্ধারিত',
        shortLabel: 'অজানা',
        flag: '📄',
      );
    }

    final bnRatio = bengaliCount / totalLetters;
    final enRatio = englishCount / totalLetters;

    if (bnRatio >= 0.70) {
      final pct = (bnRatio * 100).round();
      return LanguageDetectionResult(
        type: LanguageType.bengali,
        locale: 'bn-BD',
        bengaliRatio: bnRatio,
        englishRatio: enRatio,
        confidence: bnRatio,
        label: 'বাংলা ($pct%)',
        shortLabel: 'বাংলা',
        flag: '🇧🇩',
      );
    } else if (enRatio >= 0.70) {
      final pct = (enRatio * 100).round();
      return LanguageDetectionResult(
        type: LanguageType.english,
        locale: 'en-US',
        bengaliRatio: bnRatio,
        englishRatio: enRatio,
        confidence: enRatio,
        label: 'English ($pct%)',
        shortLabel: 'English',
        flag: '🇬🇧',
      );
    } else {
      final maxRatio = max(bnRatio, enRatio);
      return LanguageDetectionResult(
        type: LanguageType.mixed,
        locale: bnRatio >= enRatio ? 'bn-BD' : 'en-US',
        bengaliRatio: bnRatio,
        englishRatio: enRatio,
        confidence: maxRatio,
        label: 'দ্বিভাষিক (বাংলা ${(bnRatio * 100).round()}%, English ${(enRatio * 100).round()}%)',
        shortLabel: 'দ্বিভাষিক',
        flag: '🌐',
      );
    }
  }

  /// Splits text into sentence/phrase segments tagged with their respective
  /// language locale ('bn-BD' vs 'en-US') for seamless code-switching TTS.
  static List<LanguageSegment> segmentByLanguage(
    String fullText, {
    String defaultLocale = 'bn-BD',
  }) {
    if (fullText.trim().isEmpty) return const [];

    // Split at sentence/line breaks: \n, ।, ., !, ?
    final matches = _boundaryRegex.allMatches(fullText).toList();

    final rawSegments = <LanguageSegment>[];
    int cursor = 0;

    for (final match in matches) {
      final chunkEnd = match.end;
      if (chunkEnd > cursor) {
        final chunk = fullText.substring(cursor, chunkEnd);
        if (chunk.trim().isNotEmpty) {
          final loc = _detectChunkLocale(chunk, fallback: defaultLocale);
          rawSegments.add(LanguageSegment(
            text: chunk,
            locale: loc,
            startOffset: cursor,
            endOffset: chunkEnd,
          ));
        }
        cursor = chunkEnd;
      }
    }

    if (cursor < fullText.length) {
      final remaining = fullText.substring(cursor);
      if (remaining.trim().isNotEmpty) {
        final loc = _detectChunkLocale(remaining, fallback: defaultLocale);
        rawSegments.add(LanguageSegment(
          text: remaining,
          locale: loc,
          startOffset: cursor,
          endOffset: fullText.length,
        ));
      }
    }

    if (rawSegments.isEmpty) {
      return [
        LanguageSegment(
          text: fullText,
          locale: _detectChunkLocale(fullText, fallback: defaultLocale),
          startOffset: 0,
          endOffset: fullText.length,
        ),
      ];
    }

    // Merge adjacent segments that share the same language locale
    final merged = <LanguageSegment>[];
    LanguageSegment? current;

    for (final seg in rawSegments) {
      if (current == null) {
        current = seg;
      } else if (current.locale == seg.locale) {
        current = LanguageSegment(
          text: '${current.text}${seg.text}',
          locale: current.locale,
          startOffset: current.startOffset,
          endOffset: seg.endOffset,
        );
      } else {
        merged.add(current);
        current = seg;
      }
    }
    if (current != null) {
      merged.add(current);
    }

    return merged;
  }

  static String _detectChunkLocale(String chunk, {required String fallback}) {
    int bn = 0;
    int en = 0;
    for (int i = 0; i < chunk.length; i++) {
      final c = chunk.codeUnitAt(i);
      if (c >= 0x0980 && c <= 0x09FF) {
        bn++;
      } else if ((c >= 0x0041 && c <= 0x005A) || (c >= 0x0061 && c <= 0x007A)) {
        en++;
      }
    }
    if (bn > en && bn > 0) return 'bn-BD';
    if (en > bn && en > 0) return 'en-US';
    return fallback;
  }
}
