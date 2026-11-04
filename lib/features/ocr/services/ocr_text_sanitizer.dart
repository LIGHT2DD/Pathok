class OcrTextSanitizer {
  static final RegExp _isolatedNoiseSymbols = RegExp(
    r'(?:^|\s)[~^|_\/\\«»§¢€©®•★]{1,3}(?=\s|$)',
  );

  static final RegExp _pipeDariPattern = RegExp(r'\s*\|\s*');
  static final RegExp _multipleSpaces = RegExp(r'[ \t]{2,}');
  static final RegExp _excessiveNewlines = RegExp(r'\n{3,}');
  static final RegExp _brokenBengaliVowels = RegExp(r'([\u0980-\u09FF])\s+([\u09BE-\u09CD])');

  static final RegExp _bulletOrNumberPattern = RegExp(
    r'^(?:[0-9০-৯]+[\.\)\-]|[\•\-\*\>])\s+',
  );

  static final RegExp _terminalPunctuation = RegExp(
    r'[।\.\?\!\:\;\,]$',
  );

  /// Cleans raw Tesseract OCR output by removing garbage noise symbols,
  /// fixing broken Bengali matras, and eliminating stray artifacts.
  static String sanitize(String rawText) {
    if (rawText.trim().isEmpty) return '';

    var text = rawText;

    // 1. Normalize vertical pipes commonly misrecognized in place of Bengali dāri (।)
    text = text.replaceAll(_pipeDariPattern, ' । ');

    // 2. Remove broken spaces between Bengali consonants and dependent vowel diacritics
    text = text.replaceAllMapped(_brokenBengaliVowels, (m) => '${m[1]}${m[2]}');

    // 3. Remove isolated noise characters and stray punctuation tokens
    text = text.replaceAll(_isolatedNoiseSymbols, ' ');

    // 4. Split into lines and filter out empty / pure garbage noise lines
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.replaceAll(_multipleSpaces, ' ').trim();
      if (line.isEmpty) {
        cleanedLines.add('');
        continue;
      }

      // Discard lines that consist solely of 1-2 random non-alphanumeric noise chars
      final alphaNumericCount = line.replaceAll(RegExp(r'[^a-zA-Z0-9\u0980-\u09FF]'), '').length;
      if (line.length <= 3 && alphaNumericCount == 0) {
        continue;
      }

      cleanedLines.add(line);
    }

    return cleanedLines.join('\n');
  }

  /// Reconstructs natural flowing paragraphs from OCR line fragments,
  /// preserving genuine paragraph breaks, lists, headers, and bullet points.
  static String formatLayout(String sanitizedText) {
    if (sanitizedText.trim().isEmpty) return '';

    final lines = sanitizedText.split('\n');
    final formatted = <String>[];
    String currentParagraph = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        if (currentParagraph.isNotEmpty) {
          formatted.add(currentParagraph);
          currentParagraph = '';
        }
        continue;
      }

      final isListOrBullet = _bulletOrNumberPattern.hasMatch(line);
      final hasLatinLetters = RegExp(r'[a-zA-Z]').hasMatch(line);
      final isHeader = hasLatinLetters && line.length < 40 && !_terminalPunctuation.hasMatch(line) && line.toUpperCase() == line;

      if (currentParagraph.isEmpty) {
        currentParagraph = line;
      } else {
        final lastLineEndsWithTerminal = _terminalPunctuation.hasMatch(currentParagraph);

        // If previous line ends with terminal punctuation or this line is a bullet/header, start new block
        if (lastLineEndsWithTerminal || isListOrBullet || isHeader) {
          formatted.add(currentParagraph);
          currentParagraph = line;
        } else {
          // Soft-wrapped line: join smoothly with a single space
          currentParagraph = '$currentParagraph $line';
        }
      }
    }

    if (currentParagraph.isNotEmpty) {
      formatted.add(currentParagraph);
    }

    // Join paragraphs with double newlines and clamp excessive whitespace
    return formatted.join('\n\n').replaceAll(_excessiveNewlines, '\n\n').trim();
  }
}
