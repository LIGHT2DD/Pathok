import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfService {
  static pw.Font? _cachedBengaliFont;

  static Future<pw.Font> _loadBengaliFont() async {
    if (_cachedBengaliFont != null) return _cachedBengaliFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      _cachedBengaliFont = pw.Font.ttf(fontData);
      return _cachedBengaliFont!;
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  /// Extracts textual content from a PDF using offline native extraction
  Future<String> extractText(String pdfPath) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw StateError('PDF ফাইলটি পাওয়া যায়নি।');
    }

    final bytes = await file.readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);

    try {
      final textExtractor = sf.PdfTextExtractor(document);
      final extractedText = textExtractor.extractText().trim();

      if (extractedText.isNotEmpty) {
        return extractedText;
      }

      return 'PDF-এ কোনো শনাক্তকরণযোগ্য টেক্সট লেয়ার পাওয়া যায়নি।';
    } finally {
      document.dispose();
    }
  }

  /// Exports text into a clean PDF with proper Unicode support for Bengali & English
  Future<File> exportToPdf({
    required String title,
    required String text,
    required String defaultNotice,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final outputFile = File('${directory.path}/pathok_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf');

    // Use cached Bengali-compatible TrueType font for zero redundant I/O
    final bengaliFont = await _loadBengaliFont();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: bengaliFont,
        bold: bengaliFont,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: bengaliFont,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'পাঠক (Pathok)',
                  style: pw.TextStyle(
                    font: bengaliFont,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Paragraph(
            text: text.isEmpty ? defaultNotice : text,
            style: pw.TextStyle(
              font: bengaliFont,
              fontSize: 12,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );

    await outputFile.writeAsBytes(await pdf.save());
    return outputFile;
  }
}
