import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/constants/voice_profiles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/notifications/notification_service.dart';
import '../../ocr/services/ocr_service.dart';
import '../../prescription/models/medicine_reminder.dart';
import '../../prescription/presentation/prescription_dialog.dart';
import '../../prescription/services/prescription_service.dart';
import '../models/local_document.dart';
import '../services/pdf_service.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({
    required this.document,
    required this.onChanged,
    required this.onExport,
    required this.onReminderSaved,
    super.key,
  });

  final LocalDocument document;
  final VoidCallback onChanged;
  final Future<void> Function(LocalDocument document) onExport;
  final ValueChanged<MedicineReminder> onReminderSaved;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final TextEditingController _controller;
  final FlutterTts _tts = FlutterTts();
  final OfflineOcrService _ocrService = OfflineOcrService();
  final PdfService _pdfService = PdfService();
  final PrescriptionService _prescriptionService = PrescriptionService();

  bool _speaking = false;
  bool _paused = false;
  int _lastWordStart = 0;
  int _utteranceOffset = 0;
  bool _processing = false;
  String _speechLang = 'bn-BD';
  bool _userSelectedLanguage = false;
  double _speechRate = 0.45; // ~1.0x normal speech rate
  final ValueNotifier<TextRange?> _karaokeWordRange = ValueNotifier<TextRange?>(null);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.document.text);
    _detectSpeechLanguageFromText(widget.document.text);
    _initTts();

    // Auto-extract text on opening if document is new/empty
    if (widget.document.text.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.document.fileType == 'image') {
          _processImageOcr();
        } else if (widget.document.fileType == 'pdf') {
          _processPdfExtraction();
        }
      });
    }
  }

  void _detectSpeechLanguageFromText(String text) {
    if (_userSelectedLanguage) return;
    final hasBengaliChars = RegExp(r'[\u0980-\u09FF]').hasMatch(text);
    _speechLang = hasBengaliChars ? 'bn-BD' : 'en-US';
  }

  void _initTts() {
    _tts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _speaking = true;
          _paused = false;
        });
      }
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _speaking = false;
          _paused = false;
          _lastWordStart = 0;
          _utteranceOffset = 0;
        });
      }
      _karaokeWordRange.value = null;
    });

    _tts.setErrorHandler((dynamic msg) {
      if (!_paused) {
        _karaokeWordRange.value = null;
        if (mounted) {
          setState(() {
            _speaking = false;
            _paused = false;
          });
        }
      }
    });

    _tts.setCancelHandler(() {
      if (!_paused) {
        _karaokeWordRange.value = null;
        if (mounted) {
          setState(() {
            _speaking = false;
            _paused = false;
          });
        }
      }
    });

    // High performance localized progress tracking with absolute document offsets
    _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      final absoluteStart = _utteranceOffset + startOffset;
      final absoluteEnd = _utteranceOffset + endOffset;
      _lastWordStart = absoluteStart;
      _karaokeWordRange.value = TextRange(start: absoluteStart, end: absoluteEnd);
    });

    _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _karaokeWordRange.dispose();
    _tts.stop();
    _ocrService.close();
    super.dispose();
  }

  Future<void> _processImageOcr() async {
    setState(() => _processing = true);
    final strings = AppStrings.of(context);

    try {
      final result = await _ocrService.recognize(widget.document.sourcePath);
      if (!result.quality.isUsable) {
        throw StateError(result.quality.message);
      }
      final text = result.text;
      if (text.isEmpty) {
        throw StateError(strings.noTextFoundInImage);
      }

      _controller.text = text;
      widget.document.text = text;
      widget.document.updatedAt = DateTime.now();
      widget.onChanged();

      _detectSpeechLanguageFromText(text);

      if (mounted) {
        HapticFeedback.lightImpact();
        SemanticsService.sendAnnouncement(
          View.of(context),
          '${strings.recognizedText}: ${result.confidenceLabel}',
          TextDirection.ltr,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.recognizedText} (${result.confidenceLabel})'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.ocrFailed}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _processPdfExtraction() async {
    setState(() => _processing = true);
    final strings = AppStrings.of(context);

    try {
      final extractedText = await _pdfService.extractText(widget.document.sourcePath);
      if (extractedText.isEmpty) {
        throw StateError(strings.noTextFoundInImage);
      }

      _controller.text = extractedText;
      widget.document.text = extractedText;
      widget.document.updatedAt = DateTime.now();
      widget.onChanged();

      _detectSpeechLanguageFromText(extractedText);

      if (mounted) {
        HapticFeedback.lightImpact();
        SemanticsService.sendAnnouncement(
          View.of(context),
          strings.recognizedText,
          TextDirection.ltr,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.recognizedText)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.error}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _appendPage() async {
    final strings = AppStrings.of(context);

    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PathokIcons.scan, color: Color(0xff2563eb)),
                title: Text(strings.scanCamera),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(PathokIcons.photo, color: Color(0xff059669)),
                title: Text(strings.chooseImage),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xffe11d48)),
                title: Text(strings.choosePdf),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _processing = true);
    HapticFeedback.lightImpact();

    try {
      String newText = '';
      if (source == 'camera' || source == 'gallery') {
        final img = await ImagePicker().pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 92,
        );
        if (img == null) return;
        final res = await _ocrService.recognize(img.path);
        newText = res.text.trim();
      } else if (source == 'pdf') {
        final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        if (files.isEmpty || files.first.path == null) return;
        newText = (await _pdfService.extractText(files.first.path!)).trim();
      }

      if (newText.isEmpty) {
        throw StateError(strings.noTextFoundInImage);
      }

      final combined = _controller.text.trim().isEmpty
          ? newText
          : '${_controller.text.trim()}\n\n--- Page ---\n\n$newText';

      _controller.text = combined;
      widget.document.text = combined;
      widget.document.updatedAt = DateTime.now();
      widget.onChanged();

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.pageAppended)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<bool> _isLanguageAvailable(String lang) async {
    try {
      final dynamic res = await _tts.isLanguageAvailable(lang);
      if (res is bool) return res;
      if (res is num) return res >= 0; // Android TextToSpeech returns 0, 1, or 2 for supported locales
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pauseSpeech() async {
    setState(() {
      _speaking = false;
      _paused = true;
    });
    await _tts.stop();
  }

  Future<void> _stopSpeech() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _speaking = false;
        _paused = false;
        _lastWordStart = 0;
        _utteranceOffset = 0;
      });
    }
    _karaokeWordRange.value = null;
  }

  Future<void> _resumeSpeech() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    // Sentence boundary detection for natural audio continuation:
    // If paused mid-sentence, resume from the start of that sentence so words are never cut in half
    int sentenceStart = _lastWordStart;
    if (sentenceStart > 0 && sentenceStart < text.length) {
      final terminators = RegExp(r'[।\n.!?]');
      final textBefore = text.substring(0, sentenceStart);
      final matches = terminators.allMatches(textBefore).toList();
      if (matches.isNotEmpty) {
        sentenceStart = matches.last.end;
        while (sentenceStart < text.length && text[sentenceStart].trim().isEmpty) {
          sentenceStart++;
        }
      } else {
        sentenceStart = 0;
      }
    } else {
      sentenceStart = 0;
    }

    _utteranceOffset = sentenceStart;
    await _speakFromOffset(sentenceStart);
  }

  Future<void> _toggleSpeech() async {
    final strings = AppStrings.of(context);

    if (_speaking) {
      await _pauseSpeech();
      return;
    }

    if (_paused) {
      await _resumeSpeech();
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.noTextToSpeak)),
        );
      }
      return;
    }

    _lastWordStart = 0;
    _utteranceOffset = 0;
    await _speakFromOffset(0);
  }

  Future<void> _speakFromOffset(int offset) async {
    final fullText = _controller.text;
    if (offset >= fullText.length) {
      await _stopSpeech();
      return;
    }

    final textToSpeak = fullText.substring(offset).trim();
    if (textToSpeak.isEmpty) {
      await _stopSpeech();
      return;
    }

    final strings = AppStrings.of(context);
    String targetLang = _speechLang;

    // Check voice engine availability for target language
    if (targetLang == 'bn-BD') {
      final isBdAvail = await _isLanguageAvailable('bn-BD');
      if (!isBdAvail) {
        final isInAvail = await _isLanguageAvailable('bn-IN');
        if (isInAvail) {
          targetLang = 'bn-IN';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.ttsVoiceMissingBengali),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getString('tts_voice_profile') ?? 'female_natural';
    final profile = VoiceProfile.getById(profileId);

    try {
      await _tts.setLanguage(targetLang);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(profile.pitch);
      await _tts.setVolume(1.0);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _speaking = true;
        _paused = false;
      });
    }

    // If text exceeds Android 4000 char utterance limit, split and speak safely
    if (textToSpeak.length > 3500) {
      await _speakLongText(textToSpeak, offset);
    } else {
      await _tts.speak(textToSpeak);
    }
  }

  Future<void> _speakLongText(String fullText, int baseOffset) async {
    final segments = fullText.split(RegExp(r'(?<=[।\n.!?])\s+'));
    final buffer = StringBuffer();
    int currentOffset = baseOffset;

    for (final seg in segments) {
      if (!_speaking) break;
      if (buffer.length + seg.length > 3000) {
        _utteranceOffset = currentOffset;
        await _tts.speak(buffer.toString());
        currentOffset += buffer.length;
        buffer.clear();
      }
      buffer.write('$seg ');
    }
    if (_speaking && buffer.isNotEmpty) {
      _utteranceOffset = currentOffset;
      await _tts.speak(buffer.toString());
    }
  }

  void _toggleSpeechLanguage() {
    HapticFeedback.selectionClick();
    setState(() {
      _userSelectedLanguage = true;
      _speechLang = (_speechLang == 'bn-BD' || _speechLang == 'bn-IN') ? 'en-US' : 'bn-BD';
    });

    if (_speaking) {
      _tts.stop().then((_) {
        if (mounted) _speakFromOffset(_utteranceOffset);
      });
    }
  }

  void _cycleSpeechRate() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_speechRate == 0.45) {
        _speechRate = 0.55; // Faster (~1.25x)
      } else if (_speechRate == 0.55) {
        _speechRate = 0.35; // Slower (~0.75x)
      } else {
        _speechRate = 0.45; // Normal (~1.0x)
      }
    });
    if (_speaking) {
      _tts.setSpeechRate(_speechRate);
    }
  }

  String get _speechRateLabel {
    if (_speechRate == 0.55) return '1.25x';
    if (_speechRate == 0.35) return '0.75x';
    return '1.0x';
  }

  Future<void> _showPrescriptionCandidates() async {
    final strings = AppStrings.of(context);
    final candidates = _prescriptionService.extract(_controller.text);

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.noMedicinesFound)),
        );
      }
      return;
    }

    final selectedReminders = await PrescriptionDialog.show(context, candidates);
    if (selectedReminders == null || selectedReminders.isEmpty || !mounted) return;

    for (final reminder in selectedReminders) {
      await _prescriptionService.saveReminder(reminder);
      await ReminderNotificationService.instance.schedule(reminder);
      widget.onReminderSaved(reminder);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.reminderSavedCount(selectedReminders.length))),
      );
    }
  }

  Future<void> _shareText() async {
    final strings = AppStrings.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.noTextToShare)),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: text, subject: widget.document.title),
    );
  }

  Widget _buildLiveReader(ThemeData theme, bool isDark, TextRange? wordRange) {
    final text = _controller.text;
    if (wordRange == null || wordRange.start < 0 || wordRange.start >= text.length) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? const Color(0xfff1f5f9) : const Color(0xff0f172a),
        ),
      );
    }

    final safeStart = wordRange.start.clamp(0, text.length);
    final safeEnd = wordRange.end.clamp(safeStart, text.length);

    final before = text.substring(0, safeStart);
    final highlighted = text.substring(safeStart, safeEnd);
    final after = text.substring(safeEnd);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          fontFamily: theme.textTheme.bodyMedium?.fontFamily,
          color: isDark ? const Color(0xfff1f5f9) : const Color(0xff0f172a),
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlighted,
            style: TextStyle(
              backgroundColor: _paused
                  ? (isDark ? const Color(0xffd97706) : const Color(0xfffef08a))
                  : (isDark ? const Color(0xffb45309) : const Color(0xfffde047)),
              color: isDark ? Colors.white : const Color(0xff78350f),
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isImage = widget.document.fileType == 'image';
    final previewPath = (widget.document.thumbnailPath != null &&
            File(widget.document.thumbnailPath!).existsSync())
        ? widget.document.thumbnailPath!
        : widget.document.sourcePath;
    final hasFile = File(previewPath).existsSync();

    final isBengaliSpeech = _speechLang == 'bn-BD' || _speechLang == 'bn-IN';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: strings.exportPdf,
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onExport(widget.document);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: strings.shareText,
            onPressed: () {
              HapticFeedback.lightImpact();
              _shareText();
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    // Document Preview Card
                    if (isImage && hasFile)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(previewPath),
                          height: 200,
                          cacheHeight: 400,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (!isImage)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xffffe4e6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Color(0xffe11d48),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.document.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      strings.choosePdfSubtitle,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Contextual Action Pills Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (isImage)
                            ActionChip(
                              avatar: _processing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(PathokIcons.scan, size: 16),
                              label: Text(_processing ? strings.recognizing : strings.runOfflineOcr),
                              onPressed: _processing ? null : _processImageOcr,
                            )
                          else
                            ActionChip(
                              avatar: _processing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.document_scanner_outlined, size: 16),
                              label: Text(_processing ? strings.extractingPdf : strings.extractPdfText),
                              onPressed: _processing ? null : _processPdfExtraction,
                            ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.note_add_outlined, size: 16),
                            label: Text(strings.appendPage),
                            onPressed: _processing ? null : _appendPage,
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(PathokIcons.pill, size: 16),
                            label: Text(strings.prescriptionAssistance),
                            onPressed: _controller.text.trim().isEmpty ? null : _showPrescriptionCandidates,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Clean Text Box / Karaoke Reader Box
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_speaking || _paused) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _speaking ? const Color(0xff10b981) : const Color(0xfff59e0b),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _speaking ? strings.liveReader : strings.pausedAudio,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _speaking ? theme.colorScheme.primary : const Color(0xffd97706),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              RepaintBoundary(
                                child: ValueListenableBuilder<TextRange?>(
                                  valueListenable: _karaokeWordRange,
                                  builder: (context, wordRange, _) =>
                                      _buildLiveReader(theme, isDark, wordRange),
                                ),
                              ),
                            ] else
                              TextField(
                                controller: _controller,
                                minLines: 8,
                                maxLines: 18,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: isDark ? const Color(0xfff1f5f9) : const Color(0xff0f172a),
                                ),
                                onChanged: (value) {
                                  widget.document.text = value;
                                  widget.document.updatedAt = DateTime.now();
                                  widget.onChanged();
                                },
                                decoration: InputDecoration(
                                  hintText: strings.documentHint,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Modern Floating Bottom Player / Audio Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff111827) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Play / Pause / Resume Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _speaking
                              ? const Color(0xfff59e0b) // Amber for Pause
                              : (_paused
                                  ? const Color(0xff10b981) // Emerald for Resume
                                  : theme.colorScheme.primary), // Blue for Play
                        ),
                        child: IconButton(
                          iconSize: 26,
                          color: Colors.white,
                          tooltip: _speaking
                              ? strings.pauseListening
                              : (_paused ? strings.resumeListening : strings.listenToText),
                          icon: Icon(
                            _speaking
                                ? Icons.pause_rounded
                                : (_paused ? Icons.play_arrow_rounded : PathokIcons.volume),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _toggleSpeech();
                          },
                        ),
                      ),

                      // Dedicated Stop / Reset Button (visible when audio is active or paused)
                      if (_speaking || _paused) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xff374151) : const Color(0xfffee2e2),
                          ),
                          child: IconButton(
                            iconSize: 22,
                            tooltip: strings.stopListening,
                            color: const Color(0xffef4444),
                            icon: const Icon(Icons.stop_rounded),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _stopSpeech();
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),

                      // Player Title & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _speaking
                                  ? strings.playingAudio
                                  : (_paused ? strings.pausedAudio : strings.listenToText),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _paused
                                    ? const Color(0xffd97706)
                                    : (_speaking ? theme.colorScheme.primary : null),
                              ),
                            ),
                            Text(
                              isBengaliSpeech ? 'বাংলা ভয়েস (Bangla)' : 'English Voice (ইংরেজি)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 1-Tap Voice Language Toggle
                      ActionChip(
                        avatar: Icon(
                          Icons.record_voice_over,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          isBengaliSpeech ? 'বাং' : 'EN',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        onPressed: _toggleSpeechLanguage,
                      ),
                      const SizedBox(width: 6),

                      // Speed Switch Chip
                      ActionChip(
                        label: Text(_speechRateLabel),
                        onPressed: _cycleSpeechRate,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
