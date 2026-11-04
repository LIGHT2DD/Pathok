import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
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
import '../services/bill_extractor.dart';
import '../services/language_detector.dart';
import '../services/pdf_service.dart';
import '../services/translation_service.dart';

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
  late final TextEditingController _translatedController;
  final FlutterTts _tts = FlutterTts();
  final OfflineOcrService _ocrService = OfflineOcrService();
  final PdfService _pdfService = PdfService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final TranslationService _translationService = TranslationService();

  bool _speaking = false;
  bool _paused = false;
  int _lastWordStart = 0;
  int _utteranceOffset = 0;
  bool _processing = false;
  bool _translating = false;
  int _selectedTabIndex = 0; // 0: Original text, 1: Translated text
  String _speechLang = 'bn-BD';
  bool _userSelectedLanguage = false;
  double _speechRate = 0.45; // ~1.0x normal speech rate
  final ValueNotifier<TextRange?> _karaokeWordRange = ValueNotifier<TextRange?>(null);
  Timer? _debounceSaveTimer;

  LanguageDetectionResult? _languageResult;
  bool _isCodeSwitchingActive = false;
  int _currentSegmentIndex = 0;
  List<LanguageSegment> _audioSegments = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.document.text);
    _translatedController = TextEditingController(text: widget.document.translatedText ?? '');
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
    final result = LanguageDetector.detect(text);
    _languageResult = result;
    widget.document.detectedLanguage = result.label;
    if (!_userSelectedLanguage) {
      _speechLang = result.locale;
    }
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
      if (_isCodeSwitchingActive && _currentSegmentIndex < _audioSegments.length - 1) {
        return; // Don't cancel playback while next segment is queued
      }
      ReminderNotificationService.instance.cancelAudioPlaybackNotification();
      if (mounted) {
        setState(() {
          _speaking = false;
          _paused = false;
          _lastWordStart = 0;
          _utteranceOffset = 0;
          _isCodeSwitchingActive = false;
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
            _isCodeSwitchingActive = false;
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
            _isCodeSwitchingActive = false;
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
    if (_debounceSaveTimer?.isActive ?? false) {
      _debounceSaveTimer?.cancel();
      widget.onChanged();
    }
    _controller.dispose();
    _translatedController.dispose();
    _karaokeWordRange.dispose();
    _tts.stop();
    ReminderNotificationService.instance.cancelAudioPlaybackNotification();
    _ocrService.close();
    unawaited(_translationService.dispose());
    super.dispose();
  }

  void _debounceSave() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onChanged();
      }
    });
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
      widget.document.category = LocalDocument.detectCategory(text, widget.document.title);
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
      widget.document.category = LocalDocument.detectCategory(extractedText, widget.document.title);
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
      _isCodeSwitchingActive = false;
    });
    await _tts.stop();
    await ReminderNotificationService.instance.showAudioPlaybackNotification(
      title: widget.document.title,
      isPlaying: false,
      voiceLabel: _selectedTabIndex == 1
          ? 'অনুবাদ'
          : (!_userSelectedLanguage && (_languageResult?.isMixed ?? false)
              ? 'দ্বিভাষিক'
              : (_speechLang == 'bn-BD' ? 'বাংলা' : 'English')),
    );
  }

  Future<void> _stopSpeech() async {
    await _tts.stop();
    await ReminderNotificationService.instance.cancelAudioPlaybackNotification();
    if (mounted) {
      setState(() {
        _speaking = false;
        _paused = false;
        _lastWordStart = 0;
        _utteranceOffset = 0;
        _isCodeSwitchingActive = false;
      });
    }
    _karaokeWordRange.value = null;
  }

  Future<void> _resumeSpeech() async {
    final text = _selectedTabIndex == 1 ? _translatedController.text : _controller.text;
    if (text.isEmpty) return;

    // Sentence boundary detection for natural audio continuation:
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

    final activeText = _selectedTabIndex == 1 ? _translatedController.text.trim() : _controller.text.trim();
    if (activeText.isEmpty) {
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

  Future<void> _prepareTtsEngine(String targetLang) async {
    String lang = targetLang;
    if (lang == 'bn-BD') {
      final isBdAvail = await _isLanguageAvailable('bn-BD');
      if (!isBdAvail) {
        final isInAvail = await _isLanguageAvailable('bn-IN');
        if (isInAvail) lang = 'bn-IN';
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getString('tts_voice_profile') ?? 'female_natural';
    final profile = VoiceProfile.getById(profileId);

    try {
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(profile.pitch);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _speakFromOffset(int offset) async {
    final fullText = _selectedTabIndex == 1 ? _translatedController.text : _controller.text;
    if (offset >= fullText.length) {
      await _stopSpeech();
      return;
    }

    final textToSpeak = fullText.substring(offset).trim();
    if (textToSpeak.isEmpty) {
      await _stopSpeech();
      return;
    }

    final isTranslatedTab = _selectedTabIndex == 1;
    final bool useCodeSwitching = !isTranslatedTab &&
        !_userSelectedLanguage &&
        (_languageResult?.isMixed ?? false);

    if (mounted) {
      setState(() {
        _speaking = true;
        _paused = false;
      });
    }

    final voiceLabel = useCodeSwitching
        ? 'দ্বিভাষিক (Bilingual)'
        : (isTranslatedTab
            ? 'অনুবাদ (বাংলা)'
            : (_speechLang == 'bn-BD' ? 'বাংলা' : 'English'));

    await ReminderNotificationService.instance.showAudioPlaybackNotification(
      title: widget.document.title,
      isPlaying: true,
      voiceLabel: voiceLabel,
    );

    if (useCodeSwitching) {
      final segments = LanguageDetector.segmentByLanguage(fullText);
      _audioSegments = segments;
      _isCodeSwitchingActive = true;

      int startIdx = 0;
      for (int i = 0; i < segments.length; i++) {
        if (offset >= segments[i].startOffset && offset < segments[i].endOffset) {
          startIdx = i;
          break;
        }
      }

      for (int i = startIdx; i < segments.length; i++) {
        if (!_speaking) break;
        final seg = segments[i];
        _currentSegmentIndex = i;

        final segText = (i == startIdx && offset > seg.startOffset)
            ? seg.text.substring(offset - seg.startOffset).trim()
            : seg.text.trim();

        if (segText.isEmpty) continue;

        _utteranceOffset = (i == startIdx) ? offset : seg.startOffset;

        await _prepareTtsEngine(seg.locale);
        await _tts.speak(segText);
      }

      _isCodeSwitchingActive = false;
      if (_speaking && mounted) {
        await _stopSpeech();
      }
    } else {
      _isCodeSwitchingActive = false;
      final targetLang = isTranslatedTab ? 'bn-BD' : _speechLang;
      await _prepareTtsEngine(targetLang);

      if (textToSpeak.length > 3500) {
        await _speakLongText(textToSpeak, offset);
      } else {
        _utteranceOffset = offset;
        await _tts.speak(textToSpeak);
      }
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
      if (!_userSelectedLanguage && (_languageResult?.isMixed ?? false)) {
        _userSelectedLanguage = true;
        _speechLang = 'bn-BD';
      } else if (_speechLang == 'bn-BD' || _speechLang == 'bn-IN') {
        _userSelectedLanguage = true;
        _speechLang = 'en-US';
      } else {
        if (_languageResult?.isMixed ?? false) {
          _userSelectedLanguage = false;
        } else {
          _userSelectedLanguage = true;
          _speechLang = 'bn-BD';
        }
      }
    });

    if (_speaking) {
      _stopSpeech().then((_) {
        if (mounted) _speakFromOffset(_utteranceOffset);
      });
    }
  }

  void _cycleSpeechRate() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_speechRate == 0.35) {
        _speechRate = 0.45; // 1.0x (Normal)
      } else if (_speechRate == 0.45) {
        _speechRate = 0.55; // 1.25x (Fast)
      } else if (_speechRate == 0.55) {
        _speechRate = 0.65; // 1.5x (Study Speed)
      } else if (_speechRate == 0.65) {
        _speechRate = 0.75; // 1.75x (Speed Listening)
      } else if (_speechRate == 0.75) {
        _speechRate = 0.85; // 2.0x (Max Speed)
      } else {
        _speechRate = 0.35; // 0.75x (Slow)
      }
    });
    if (_speaking) {
      _tts.setSpeechRate(_speechRate);
    }
  }

  String get _speechRateLabel {
    if (_speechRate == 0.35) return '0.75x';
    if (_speechRate == 0.45) return '1.0x';
    if (_speechRate == 0.55) return '1.25x';
    if (_speechRate == 0.65) return '1.5x';
    if (_speechRate == 0.75) return '1.75x';
    if (_speechRate == 0.85) return '2.0x';
    return '1.0x';
  }

  Future<void> _translateDocument() async {
    final text = _controller.text.trim();
    final strings = AppStrings.of(context);
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.noText)),
      );
      return;
    }

    setState(() => _translating = true);

    try {
      final isSourceBengali = _languageResult?.isBengali ?? false;
      final sourceLang = isSourceBengali ? TranslateLanguage.bengali : TranslateLanguage.english;
      final targetLang = isSourceBengali ? TranslateLanguage.english : TranslateLanguage.bengali;

      final isModelReady = await _translationService.isModelDownloaded(targetLang.bcpCode);

      if (!isModelReady && mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.translate_rounded, color: Color(0xff2563eb)),
                const SizedBox(width: 8),
                Text(strings.translate),
              ],
            ),
            content: Text(
              isSourceBengali
                  ? strings.downloadModelPromptBnToEn
                  : strings.downloadModelPromptEnToBn,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'instant'),
                child: Text(strings.instantTranslation),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'download'),
                child: Text(strings.downloadModel),
              ),
            ],
          ),
        );

        if (choice == 'download') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.downloadingModel)),
            );
          }
          await _translationService.downloadModel(targetLang.bcpCode);
        }
      }

      final translated = await _translationService.translate(
        text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      if (translated.trim().isNotEmpty) {
        setState(() {
          _translatedController.text = translated;
          widget.document.translatedText = translated;
          _selectedTabIndex = 1;
        });
        widget.document.updatedAt = DateTime.now();
        widget.onChanged();

        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.translationComplete)),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.translationFailed}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _showLanguageOptionsSheet(AppStrings strings, ThemeData theme) {
    final bnPct = ((_languageResult?.bengaliRatio ?? 0.0) * 100).round();
    final enPct = ((_languageResult?.englishRatio ?? 0.0) * 100).round();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_languageResult?.flag ?? '📄', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    strings.languageDetected,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.languageRatio(bnPct, enPct),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome, color: Color(0xff2563eb)),
                title: Text(strings.bilingualVoice),
                subtitle: Text(strings.bilingualVoiceSubtitle),
                trailing: (!_userSelectedLanguage)
                    ? const Icon(Icons.check_circle, color: Color(0xff2563eb))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _userSelectedLanguage = false;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🇧🇩', style: TextStyle(fontSize: 22)),
                title: Text(strings.speechBangla),
                subtitle: Text(strings.speechBanglaSubtitle),
                trailing: (_userSelectedLanguage && (_speechLang == 'bn-BD' || _speechLang == 'bn-IN'))
                    ? const Icon(Icons.check_circle, color: Color(0xff2563eb))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _userSelectedLanguage = true;
                    _speechLang = 'bn-BD';
                  });
                  HapticFeedback.selectionClick();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                title: Text(strings.speechEnglish),
                subtitle: Text(strings.speechEnglishSubtitle),
                trailing: (_userSelectedLanguage && _speechLang == 'en-US')
                    ? const Icon(Icons.check_circle, color: Color(0xff2563eb))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _userSelectedLanguage = true;
                    _speechLang = 'en-US';
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _showBillAnalysis() async {
    final strings = AppStrings.of(context);
    final result = BillExtractor.extract(_controller.text, widget.document.title);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xfffffbeb),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xffd97706), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.billAnalysis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          result.billerName ?? strings.billPaymentDetails,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (result.totalAmount != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffecfdf5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffa7f3d0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.totalAmount,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff065f46)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.totalAmount!,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xff047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (result.dueDate != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined, color: Color(0xffd97706)),
                  title: Text(strings.dueDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(result.dueDate!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
              if (result.accountNumber != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tag_rounded, color: Color(0xff2563eb)),
                  title: Text(strings.accountNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(result.accountNumber!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(strings.copyPaymentSummary),
                  onPressed: () {
                    final summary = StringBuffer();
                    if (result.billerName != null) summary.writeln(result.billerName);
                    if (result.totalAmount != null) summary.writeln('Amount: ${result.totalAmount}');
                    if (result.dueDate != null) summary.writeln('Due Date: ${result.dueDate}');
                    if (result.accountNumber != null) summary.writeln('Account: ${result.accountNumber}');
                    Clipboard.setData(ClipboardData(text: summary.toString()));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.billSummaryCopied)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractKeyWords(String text) {
    if (text.isEmpty) return const [];
    final tokens = text.split(RegExp(r'[\s,\.!?;:()\[\]{}।\n\r"“”]+'));
    final seen = <String>{};
    final result = <String>[];
    for (final token in tokens) {
      final t = token.trim();
      if (t.length >= 2 && !RegExp(r'^[0-9০-৯\W]+$').hasMatch(t)) {
        if (seen.add(t.toLowerCase())) {
          result.add(t);
          if (result.length >= 10) break;
        }
      }
    }
    return result;
  }

  Future<void> _showWordLookupDialog({String? initialWord}) async {
    final strings = AppStrings.of(context);
    final wordController = TextEditingController(text: initialWord ?? '');
    String translatedResult = '';
    bool isLookingUp = false;
    final docWords = _extractKeyWords(
      _selectedTabIndex == 1 && _translatedController.text.trim().isNotEmpty
          ? _translatedController.text
          : widget.document.text,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> performLookup(String word) async {
            final trimmed = word.trim();
            if (trimmed.isEmpty) return;
            setModalState(() => isLookingUp = true);

            final isBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed);
            final src = isBengali ? TranslateLanguage.bengali : TranslateLanguage.english;
            final tgt = isBengali ? TranslateLanguage.english : TranslateLanguage.bengali;

            try {
              final res = await _translationService.translate(trimmed, sourceLang: src, targetLang: tgt);
              if (ctx.mounted) {
                setModalState(() {
                  translatedResult = res;
                  isLookingUp = false;
                });
              }
            } catch (_) {
              final res = isBengali
                  ? PrescriptionOfflineTranslator.translateToEnglish(trimmed)
                  : PrescriptionOfflineTranslator.translateToBengali(trimmed);
              if (ctx.mounted) {
                setModalState(() {
                  translatedResult = (res != trimmed)
                      ? res
                      : '$trimmed (অফলাইন অনুবাদ অনুপলব্ধ / Download model for full dictionary)';
                  isLookingUp = false;
                });
              }
            }
          }

          if (initialWord != null && initialWord.trim().isNotEmpty && translatedResult.isEmpty && !isLookingUp) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              performLookup(initialWord);
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffe0f2fe),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.translate_rounded, color: Color(0xff0284c7), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      strings.wordLookup,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: wordController,
                  autofocus: initialWord == null,
                  decoration: InputDecoration(
                    hintText: strings.enterWordOrPhrase,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => performLookup(wordController.text),
                    ),
                  ),
                  onSubmitted: (word) => performLookup(word),
                ),
                if (docWords.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    strings.documentWords,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff64748b)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: docWords.map((w) {
                      return ActionChip(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        label: Text(w, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          wordController.text = w;
                          performLookup(w);
                        },
                      );
                    }).toList(),
                  ),
                ],
                if (isLookingUp) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ] else if (translatedResult.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.wordMeaning,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff64748b)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                translatedResult,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xff0f172a)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: Color(0xff2563eb)),
                          onPressed: () {
                            final isBn = RegExp(r'[\u0980-\u09FF]').hasMatch(translatedResult);
                            _tts.setLanguage(isBn ? 'bn-BD' : 'en-US');
                            _tts.speak(translatedResult);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareText() async {
    final strings = AppStrings.of(context);
    final text = _selectedTabIndex == 1 ? _translatedController.text.trim() : _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.noTextToShare)),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: _selectedTabIndex == 1 ? '${widget.document.title} (অনুবাদ)' : widget.document.title,
      ),
    );
  }

  Widget _buildLiveReader(ThemeData theme, bool isDark, TextRange? wordRange) {
    final text = _selectedTabIndex == 1 ? _translatedController.text : _controller.text;
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

    final textWidget = RichText(
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

    return SelectionArea(
      contextMenuBuilder: (context, selectableRegionState) {
        final strings = AppStrings.of(context);
        // ignore: deprecated_member_use
        final textEditingVal = selectableRegionState.textEditingValue;
        final selected = textEditingVal.selection.isValid
            ? textEditingVal.text.substring(
                textEditingVal.selection.start,
                textEditingVal.selection.end,
              ).trim()
            : '';

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: [
            ...selectableRegionState.contextMenuButtonItems,
            if (selected.isNotEmpty)
              ContextMenuButtonItem(
                label: strings.translate,
                onPressed: () {
                  selectableRegionState.hideToolbar();
                  _showWordLookupDialog(initialWord: selected);
                },
              ),
          ],
        );
      },
      child: textWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isImage = widget.document.fileType == 'image';
    final previewPath = (!kIsWeb &&
            widget.document.thumbnailPath != null &&
            File(widget.document.thumbnailPath!).existsSync())
        ? widget.document.thumbnailPath!
        : widget.document.sourcePath;
    final hasFile = !kIsWeb && File(previewPath).existsSync();

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
              final exportDoc = _selectedTabIndex == 1 &&
                      _translatedController.text.trim().isNotEmpty
                  ? widget.document.copyWith(
                      title: '${widget.document.title} (অনুবাদ)',
                      text: _translatedController.text,
                    )
                  : widget.document;
              widget.onExport(exportDoc);
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
                          // Language Detection Pill
                          ActionChip(
                            avatar: Text(
                              _languageResult?.flag ?? '🌐',
                              style: const TextStyle(fontSize: 14),
                            ),
                            label: Text(
                              _languageResult?.shortLabel ?? strings.languageDetected,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: isDark ? const Color(0xff1e293b) : const Color(0xffe0f2fe),
                            side: BorderSide(
                              color: isDark ? const Color(0xff334155) : const Color(0xffbae6fd),
                            ),
                            onPressed: () => _showLanguageOptionsSheet(strings, theme),
                          ),
                          const SizedBox(width: 8),

                          // OCR / PDF Extraction
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

                          // Translation Action Chip
                          ActionChip(
                            avatar: _translating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.translate_rounded, size: 16),
                            label: Text(
                              _translating
                                  ? strings.translating
                                  : (_languageResult?.isBengali ?? false
                                      ? strings.translateToEnglish
                                      : strings.translateToBangla),
                            ),
                            onPressed: _processing || _translating || _controller.text.trim().isEmpty
                                ? null
                                : _translateDocument,
                          ),
                          const SizedBox(width: 8),

                          // Word & Phrase Lookup Chip
                          ActionChip(
                            avatar: const Icon(Icons.manage_search_rounded, size: 16),
                            label: Text(strings.wordLookup),
                            onPressed: _showWordLookupDialog,
                          ),
                          const SizedBox(width: 8),

                          // Smart Bill Analysis Chip (Visible for bills / financial receipts)
                          if (widget.document.category == 'bill' ||
                              BillExtractor.extract(_controller.text, widget.document.title).hasKeyFields) ...[
                            ActionChip(
                              avatar: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xffd97706)),
                              label: Text(strings.billAnalysis),
                              onPressed: _showBillAnalysis,
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Append Page
                          ActionChip(
                            avatar: const Icon(Icons.note_add_outlined, size: 16),
                            label: Text(strings.appendPage),
                            onPressed: _processing ? null : _appendPage,
                          ),
                          const SizedBox(width: 8),

                          // Prescription Assistance
                          ActionChip(
                            avatar: const Icon(PathokIcons.pill, size: 16),
                            label: Text(strings.prescriptionAssistance),
                            onPressed: _controller.text.trim().isEmpty ? null : _showPrescriptionCandidates,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dual-View Tab Selector (Visible when translation is present)
                    if (widget.document.translatedText != null &&
                        widget.document.translatedText!.trim().isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff1f2937) : const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xff374151) : const Color(0xffe2e8f0),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (_selectedTabIndex != 0) {
                                    if (_speaking || _paused) _stopSpeech();
                                    setState(() => _selectedTabIndex = 0);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 0 ? theme.colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    strings.originalText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _selectedTabIndex == 0 ? Colors.white : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  if (_selectedTabIndex != 1) {
                                    if (_speaking || _paused) _stopSpeech();
                                    setState(() => _selectedTabIndex = 1);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 1 ? theme.colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.translate,
                                        size: 14,
                                        color: _selectedTabIndex == 1 ? Colors.white : theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        strings.translatedText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _selectedTabIndex == 1 ? Colors.white : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                                  const Spacer(),
                                  if (_selectedTabIndex == 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffecfdf5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'অনুবাদ পাঠ',
                                        style: TextStyle(fontSize: 11, color: Color(0xff059669), fontWeight: FontWeight.w700),
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
                                controller: _selectedTabIndex == 1 ? _translatedController : _controller,
                                minLines: 8,
                                maxLines: 18,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: isDark ? const Color(0xfff1f5f9) : const Color(0xff0f172a),
                                ),
                                onChanged: (value) {
                                  if (_selectedTabIndex == 1) {
                                    widget.document.translatedText = value;
                                  } else {
                                    widget.document.text = value;
                                    _detectSpeechLanguageFromText(value);
                                  }
                                  widget.document.updatedAt = DateTime.now();
                                  _debounceSave();
                                },
                                decoration: InputDecoration(
                                  hintText: _selectedTabIndex == 1
                                      ? 'অনুবাদিত লেখা এখানে প্রদর্শিত হবে...'
                                      : strings.documentHint,
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
                              _selectedTabIndex == 1
                                  ? '${strings.translatedText} (${isBengaliSpeech ? strings.speechBangla : strings.speechEnglish})'
                                  : (!_userSelectedLanguage && (_languageResult?.isMixed ?? false)
                                      ? strings.bilingualVoice
                                      : (isBengaliSpeech ? '${strings.speechBangla} Voice' : '${strings.speechEnglish} Voice')),
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
                          (!_userSelectedLanguage && (_languageResult?.isMixed ?? false) && _selectedTabIndex == 0)
                              ? Icons.auto_awesome
                              : Icons.record_voice_over,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          (!_userSelectedLanguage && (_languageResult?.isMixed ?? false) && _selectedTabIndex == 0)
                              ? (strings.isEnglish ? 'AUTO' : 'অটো')
                              : (isBengaliSpeech ? (strings.isEnglish ? 'BN' : 'বাং') : 'EN'),
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
