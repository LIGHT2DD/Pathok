import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  TranslationService({
    OnDeviceTranslatorModelManager? modelManager,
  }) : _modelManager = modelManager ?? OnDeviceTranslatorModelManager();

  final OnDeviceTranslatorModelManager _modelManager;
  final Map<String, OnDeviceTranslator> _translatorPool = {};

  /// Check if the offline model for the given BCP-47 language tag is already cached
  Future<bool> isModelDownloaded(String bcpCode) async {
    if (kIsWeb) return false;
    try {
      return await _modelManager.isModelDownloaded(bcpCode);
    } catch (e) {
      debugPrint('Error checking model download status: $e');
      return false;
    }
  }

  /// Download the on-device translation model (~25-30MB)
  Future<bool> downloadModel(String bcpCode) async {
    if (kIsWeb) return false;
    try {
      return await _modelManager.downloadModel(bcpCode);
    } catch (e) {
      debugPrint('Error downloading translation model: $e');
      return false;
    }
  }

  /// Translates text between English and Bengali using on-device ML Kit,
  /// with automatic fallback to domain-specific offline medical translation.
  Future<String> translate(
    String text, {
    required TranslateLanguage sourceLang,
    required TranslateLanguage targetLang,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    // First attempt on-device Neural Machine Translation via ML Kit on supported platforms
    if (!kIsWeb) {
      try {
        final poolKey = '${sourceLang.bcpCode}_${targetLang.bcpCode}';
        var translator = _translatorPool[poolKey];
        if (translator == null) {
          translator = OnDeviceTranslator(
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
          );
          _translatorPool[poolKey] = translator;
        }

        final translated = await translator.translateText(trimmed);
        if (translated.trim().isNotEmpty) {
          return translated;
        }
      } catch (e) {
        debugPrint('ML Kit on-device translation failed or model missing: $e');
        // If ML Kit translation failed (e.g. model not downloaded or platform unsupported),
        // we provide immediate offline domain-specific translation fallback!
      }
    }

    // Offline domain-specific prescription & document translation fallback
    if (targetLang == TranslateLanguage.bengali) {
      final fallback = PrescriptionOfflineTranslator.translateToBengali(trimmed);
      if (fallback != trimmed) {
        return fallback;
      }
    } else if (targetLang == TranslateLanguage.english) {
      final fallback = PrescriptionOfflineTranslator.translateToEnglish(trimmed);
      if (fallback != trimmed) {
        return fallback;
      }
    }

    throw StateError('অনুবাদ মডেল ডাউনলোড করা নেই। ইন্টারনেট সংযোগ চালু করে মডেল ডাউনলোড করুন।');
  }

  /// Closes all active translator instances and frees native memory
  Future<void> dispose() async {
    for (final translator in _translatorPool.values) {
      try {
        await translator.close();
      } catch (_) {}
    }
    _translatorPool.clear();
  }
}

class _TranslationRule {
  const _TranslationRule(this.pattern, this.replacement);
  final RegExp pattern;
  final String replacement;
}

/// Instant offline domain-specific translation engine for prescriptions,
/// study documents, bills, and document keywords (0 MB overhead, 100% offline).
class PrescriptionOfflineTranslator {
  static const Map<String, String> _digitMap = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static final RegExp _digitPattern = RegExp(r'[0-9]');

  // 1. Pre-compiled multi-word expressions and phrases
  static final List<_TranslationRule> _multiWordRules = [
    _TranslationRule(RegExp(r'\bPatient Name\b', caseSensitive: false), 'রোগীর নাম'),
    _TranslationRule(RegExp(r'\bDoctor Name\b', caseSensitive: false), 'চিকিৎসকের নাম'),
    _TranslationRule(RegExp(r'\bTotal Amount\b', caseSensitive: false), 'মোট পরিমাণ'),
    _TranslationRule(RegExp(r'\bDue Date\b', caseSensitive: false), 'পরিশোধের শেষ তারিখ'),
    _TranslationRule(RegExp(r'\bwith water\b', caseSensitive: false), 'পানির সাথে'),
    _TranslationRule(RegExp(r'\bafter meals?\b|\bpc\b', caseSensitive: false), 'খাবারের পর'),
    _TranslationRule(RegExp(r'\bbefore meals?\b|\bac\b', caseSensitive: false), 'খাবারের পূর্বে'),
    _TranslationRule(RegExp(r'\bempty stomach\b', caseSensitive: false), 'খালি পেটে'),
    _TranslationRule(RegExp(r'\bbedtime\b|\bhs\b', caseSensitive: false), 'ঘুমানোর পূর্বে'),
    _TranslationRule(RegExp(r'\bas needed\b|\bprn\b', caseSensitive: false), 'প্রয়োজন অনুযায়ী'),
    _TranslationRule(RegExp(r'\bdo not stop\b', caseSensitive: false), 'বন্ধ করবেন না'),
    _TranslationRule(RegExp(r'\bcontinue\b', caseSensitive: false), 'চালিয়ে যান'),
  ];

  // 2. Pre-compiled frequencies & dosages
  static final List<_TranslationRule> _dosageRules = [
    _TranslationRule(RegExp(r'\b1\s*\+\s*0\s*\+\s*1\b'), 'সকালে ১টি এবং রাতে ১টি'),
    _TranslationRule(RegExp(r'\b1\s*\+\s*1\s*\+\s*1\b'), 'সকালে ১টি, দুপুরে ১টি এবং রাতে ১টি'),
    _TranslationRule(RegExp(r'\b1\s*\+\s*0\s*\+\s*0\b'), 'সকালে ১টি'),
    _TranslationRule(RegExp(r'\b0\s*\+\s*0\s*\+\s*1\b'), 'রাতে ১টি'),
    _TranslationRule(RegExp(r'\b0\s*\+\s*1\s*\+\s*0\b'), 'দুপরে ১টি'),
    _TranslationRule(RegExp(r'\b1\s*\+\s*1\s*\+\s*1\s*\+\s*1\b'), 'সকালে ১টি, দুপুরে ১টি, সন্ধ্যায় ১টি এবং রাতে ১টি'),
    _TranslationRule(RegExp(r'\bdaily\b|\bod\b', caseSensitive: false), 'প্রতিদিন একবার'),
    _TranslationRule(RegExp(r'\bbid\b|\bb\.i\.d\.?\b', caseSensitive: false), 'দিনে দুইবার'),
    _TranslationRule(RegExp(r'\btid\b|\bt\.i\.d\.?\b', caseSensitive: false), 'দিনে তিনবার'),
    _TranslationRule(RegExp(r'\bqid\b|\bq\.i\.d\.?\b', caseSensitive: false), 'দিনে চারবার'),
  ];

  // 3. Pre-compiled duration patterns
  static final RegExp _daysPattern = RegExp(r'\bfor\s+(\d+)\s+days?\b', caseSensitive: false);
  static final RegExp _weeksPattern = RegExp(r'\bfor\s+(\d+)\s+weeks?\b', caseSensitive: false);
  static final RegExp _monthsPattern = RegExp(r'\bfor\s+(\d+)\s+months?\b', caseSensitive: false);

  // 4. Pre-compiled units
  static final RegExp _mgPattern = RegExp(r'(\d+)\s*mg\b', caseSensitive: false);
  static final RegExp _mlPattern = RegExp(r'(\d+)\s*ml\b', caseSensitive: false);
  static final RegExp _mcgPattern = RegExp(r'(\d+)\s*mcg\b', caseSensitive: false);

  // 5. Pre-compiled forms of medicine
  static final List<_TranslationRule> _formRules = [
    _TranslationRule(RegExp(r'\bTab(?:let)?\.?\b', caseSensitive: false), 'ট্যাবলেট'),
    _TranslationRule(RegExp(r'\bCap(?:sule)?\.?\b', caseSensitive: false), 'ক্যাপসুল'),
    _TranslationRule(RegExp(r'\bSyr(?:up)?\.?\b', caseSensitive: false), 'সিরাপ'),
    _TranslationRule(RegExp(r'\bInj(?:ection)?\.?\b', caseSensitive: false), 'ইনজেকশন'),
    _TranslationRule(RegExp(r'\bDrop(?:s)?\.?\b', caseSensitive: false), 'ড্রপ'),
    _TranslationRule(RegExp(r'\bOint(?:ment)?\.?\b', caseSensitive: false), 'মলম'),
  ];

  // 6. Pre-compiled single-word keywords
  static final List<_TranslationRule> _keywordRules = [
    _TranslationRule(RegExp(r'\bPrescription\b', caseSensitive: false), 'প্রেসক্রিপশন'),
    _TranslationRule(RegExp(r'\bDoctor\b', caseSensitive: false), 'চিকিৎসক'),
    _TranslationRule(RegExp(r'\bDate\b', caseSensitive: false), 'তারিখ'),
    _TranslationRule(RegExp(r'\bAge\b', caseSensitive: false), 'বয়স'),
    _TranslationRule(RegExp(r'\bDiagnosis\b', caseSensitive: false), 'রোগ নির্ণয়'),
    _TranslationRule(RegExp(r'\bAdvice\b', caseSensitive: false), 'পরামর্শ'),
    _TranslationRule(RegExp(r'\bInvestigation\b', caseSensitive: false), 'পরীক্ষা-নিরীক্ষা'),
    _TranslationRule(RegExp(r'\bBill\b', caseSensitive: false), 'বিল'),
    _TranslationRule(RegExp(r'\bAmount\b', caseSensitive: false), 'টাকা'),
    _TranslationRule(RegExp(r'\bTotal\b', caseSensitive: false), 'মোট'),
    _TranslationRule(RegExp(r'\bElectricity\b', caseSensitive: false), 'বিদ্যুৎ'),
    _TranslationRule(RegExp(r'\bWater\b', caseSensitive: false), 'পানি'),
    _TranslationRule(RegExp(r'\bGas\b', caseSensitive: false), 'গ্যাস'),
    _TranslationRule(RegExp(r'\bPaid\b', caseSensitive: false), 'পরিশোধিত'),
    _TranslationRule(RegExp(r'\bUnpaid\b', caseSensitive: false), 'বকেয়া'),
    _TranslationRule(RegExp(r'\bReceipt\b', caseSensitive: false), 'রসিদ'),
    _TranslationRule(RegExp(r'\bAccount\b', caseSensitive: false), 'হিসাব'),
    _TranslationRule(RegExp(r'\bMeter\b', caseSensitive: false), 'মিটার'),
    _TranslationRule(RegExp(r'\bChapter\b', caseSensitive: false), 'অধ্যায়'),
    _TranslationRule(RegExp(r'\bPage\b', caseSensitive: false), 'পৃষ্ঠা'),
    _TranslationRule(RegExp(r'\bQuestion\b', caseSensitive: false), 'প্রশ্ন'),
    _TranslationRule(RegExp(r'\bAnswer\b', caseSensitive: false), 'উত্তর'),
    _TranslationRule(RegExp(r'\bSubject\b', caseSensitive: false), 'বিষয়'),
    _TranslationRule(RegExp(r'\bBook\b', caseSensitive: false), 'বই'),
    _TranslationRule(RegExp(r'\bSummary\b', caseSensitive: false), 'সারসংক্ষেপ'),
    _TranslationRule(RegExp(r'\bNote\b', caseSensitive: false), 'নোট'),
    _TranslationRule(RegExp(r'\bNotice\b', caseSensitive: false), 'বিজ্ঞপ্তি'),
    _TranslationRule(RegExp(r'\bExam(?:ination)?\b', caseSensitive: false), 'পরীক্ষা'),
    _TranslationRule(RegExp(r'\bResult\b', caseSensitive: false), 'ফলাফল'),
    _TranslationRule(RegExp(r'\bImportant\b', caseSensitive: false), 'গুরুত্বপূর্ণ'),
    _TranslationRule(RegExp(r'\bEducation\b', caseSensitive: false), 'শিক্ষা'),
    _TranslationRule(RegExp(r'\bStudent\b', caseSensitive: false), 'শিক্ষার্থী'),
    _TranslationRule(RegExp(r'\bTeacher\b', caseSensitive: false), 'শিক্ষক'),
    _TranslationRule(RegExp(r'\bSchool\b', caseSensitive: false), 'বিদ্যালয়'),
    _TranslationRule(RegExp(r'\bCollege\b', caseSensitive: false), 'কলেজ'),
    _TranslationRule(RegExp(r'\bUniversity\b', caseSensitive: false), 'বিশ্ববিদ্যালয়'),
  ];

  static String toBengaliDigits(String input) {
    return input.replaceAllMapped(_digitPattern, (m) => _digitMap[m[0]] ?? m[0]!);
  }

  static String translateToBengali(String text) {
    var out = text;

    // 1. Multi-word expressions and phrases FIRST
    for (final rule in _multiWordRules) {
      out = out.replaceAll(rule.pattern, rule.replacement);
    }

    // 2. Common Frequencies & Dosage patterns
    for (final rule in _dosageRules) {
      out = out.replaceAll(rule.pattern, rule.replacement);
    }

    // 3. Duration patterns
    out = out.replaceAllMapped(_daysPattern, (m) {
      final days = toBengaliDigits(m[1] ?? '১');
      return '$days দিনের জন্য';
    });
    out = out.replaceAllMapped(_weeksPattern, (m) {
      final weeks = toBengaliDigits(m[1] ?? '১');
      return '$weeks সপ্তাহের জন্য';
    });
    out = out.replaceAllMapped(_monthsPattern, (m) {
      final months = toBengaliDigits(m[1] ?? '১');
      return '$months মাসের জন্য';
    });

    // 4. Units
    out = out.replaceAllMapped(_mgPattern, (m) {
      return '${toBengaliDigits(m[1] ?? "")} মি.গ্রা.';
    });
    out = out.replaceAllMapped(_mlPattern, (m) {
      return '${toBengaliDigits(m[1] ?? "")} মি.লি.';
    });
    out = out.replaceAllMapped(_mcgPattern, (m) {
      return '${toBengaliDigits(m[1] ?? "")} মাইক্রোগ্রাম';
    });

    // 5. Forms of medicine
    for (final rule in _formRules) {
      out = out.replaceAll(rule.pattern, rule.replacement);
    }

    // 6. Single-word Document Headers & Keywords
    for (final rule in _keywordRules) {
      out = out.replaceAll(rule.pattern, rule.replacement);
    }

    return out;
  }

  // Pre-defined static pairs for Bengali to English translation
  static const List<MapEntry<String, String>> _bnToEnPhrases = [
    MapEntry('রোগীর নাম', 'Patient Name'),
    MapEntry('চিকিৎসকের নাম', 'Doctor Name'),
    MapEntry('মোট পরিমাণ', 'Total Amount'),
    MapEntry('পরিশোধের শেষ তারিখ', 'Due Date'),
    MapEntry('খাবারের পূর্বে', 'Before meals'),
    MapEntry('খাবারের পর', 'After meals'),
    MapEntry('খালি পেটে', 'Empty stomach'),
    MapEntry('ঘুমানোর পূর্বে', 'Before bedtime'),
    MapEntry('দিনে দুইবার', 'Twice daily (BID)'),
    MapEntry('দিনে তিনবার', 'Three times daily (TID)'),
    MapEntry('দিনে চারবার', 'Four times daily (QID)'),
    MapEntry('প্রতিদিন একবার', 'Once daily'),
    MapEntry('পানির সাথে', 'With water'),
    MapEntry('চালিয়ে যান', 'Continue'),
    MapEntry('বন্ধ করবেন না', 'Do not stop'),
    MapEntry('প্রেসক্রিপশন', 'Prescription'),
    MapEntry('চিকিৎসক', 'Doctor'),
    MapEntry('তারিখ', 'Date'),
    MapEntry('বয়স', 'Age'),
    MapEntry('রোগ নির্ণয়', 'Diagnosis'),
    MapEntry('পরামর্শ', 'Advice'),
    MapEntry('পরীক্ষা-নিরীক্ষা', 'Investigation'),
    MapEntry('বিল', 'Bill'),
    MapEntry('টাকা', 'Amount'),
    MapEntry('মোট', 'Total'),
    MapEntry('বিদ্যুৎ', 'Electricity'),
    MapEntry('পানি', 'Water'),
    MapEntry('গ্যাস', 'Gas'),
    MapEntry('বকেয়া', 'Unpaid'),
    MapEntry('পরিশোধিত', 'Paid'),
    MapEntry('রসিদ', 'Receipt'),
    MapEntry('হিসাব', 'Account'),
    MapEntry('মিটার', 'Meter'),
    MapEntry('ট্যাবলেট', 'Tablet'),
    MapEntry('ক্যাপসুল', 'Capsule'),
    MapEntry('সিরাপ', 'Syrup'),
    MapEntry('ইনজেকশন', 'Injection'),
    MapEntry('ড্রপ', 'Drops'),
    MapEntry('মলম', 'Ointment'),
    MapEntry('ওষুধ', 'Medicine'),
    MapEntry('রোগী', 'Patient'),
    MapEntry('অধ্যায়', 'Chapter'),
    MapEntry('পৃষ্ঠা', 'Page'),
    MapEntry('প্রশ্ন', 'Question'),
    MapEntry('উত্তর', 'Answer'),
    MapEntry('বিষয়', 'Subject'),
    MapEntry('বই', 'Book'),
    MapEntry('সারসংক্ষেপ', 'Summary'),
    MapEntry('নোট', 'Note'),
    MapEntry('বিজ্ঞপ্তি', 'Notice'),
    MapEntry('পরীক্ষা', 'Exam'),
    MapEntry('ফলাফল', 'Result'),
    MapEntry('গুরুত্বপূর্ণ', 'Important'),
    MapEntry('শিক্ষা', 'Education'),
    MapEntry('শিক্ষার্থী', 'Student'),
    MapEntry('শিক্ষক', 'Teacher'),
    MapEntry('বিদ্যালয়', 'School'),
    MapEntry('কলেজ', 'College'),
    MapEntry('বিশ্ববিদ্যালয়', 'University'),
  ];

  /// Translates common Bengali document terms and phrases to English offline
  static String translateToEnglish(String text) {
    var out = text;
    for (final entry in _bnToEnPhrases) {
      out = out.replaceAll(entry.key, entry.value);
    }
    return out;
  }
}
