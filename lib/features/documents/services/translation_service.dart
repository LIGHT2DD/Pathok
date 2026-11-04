import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  TranslationService({
    OnDeviceTranslatorModelManager? modelManager,
  }) : _modelManager = modelManager ?? OnDeviceTranslatorModelManager();

  final OnDeviceTranslatorModelManager _modelManager;

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
        final translator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );
        try {
          final translated = await translator.translateText(trimmed);
          if (translated.trim().isNotEmpty) {
            return translated;
          }
        } finally {
          await translator.close();
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

  static String toBengaliDigits(String input) {
    return input.replaceAllMapped(_digitPattern, (m) => _digitMap[m[0]] ?? m[0]!);
  }

  static String translateToBengali(String text) {
    var out = text;

    // 1. Multi-word expressions and phrases FIRST
    out = out.replaceAll(RegExp(r'\bPatient Name\b', caseSensitive: false), 'রোগীর নাম');
    out = out.replaceAll(RegExp(r'\bDoctor Name\b', caseSensitive: false), 'চিকিৎসকের নাম');
    out = out.replaceAll(RegExp(r'\bTotal Amount\b', caseSensitive: false), 'মোট পরিমাণ');
    out = out.replaceAll(RegExp(r'\bDue Date\b', caseSensitive: false), 'পরিশোধের শেষ তারিখ');
    out = out.replaceAll(RegExp(r'\bwith water\b', caseSensitive: false), 'পানির সাথে');
    out = out.replaceAll(RegExp(r'\bafter meals?\b|\bpc\b', caseSensitive: false), 'খাবারের পর');
    out = out.replaceAll(RegExp(r'\bbefore meals?\b|\bac\b', caseSensitive: false), 'খাবারের পূর্বে');
    out = out.replaceAll(RegExp(r'\bempty stomach\b', caseSensitive: false), 'খালি পেটে');
    out = out.replaceAll(RegExp(r'\bbedtime\b|\bhs\b', caseSensitive: false), 'ঘুমানোর পূর্বে');
    out = out.replaceAll(RegExp(r'\bas needed\b|\bprn\b', caseSensitive: false), 'প্রয়োজন অনুযায়ী');
    out = out.replaceAll(RegExp(r'\bdo not stop\b', caseSensitive: false), 'বন্ধ করবেন না');
    out = out.replaceAll(RegExp(r'\bcontinue\b', caseSensitive: false), 'চালিয়ে যান');

    // 2. Common Frequencies & Dosage patterns
    out = out.replaceAll(RegExp(r'\b1\s*\+\s*0\s*\+\s*1\b'), 'সকালে ১টি এবং রাতে ১টি');
    out = out.replaceAll(RegExp(r'\b1\s*\+\s*1\s*\+\s*1\b'), 'সকালে ১টি, দুপুরে ১টি এবং রাতে ১টি');
    out = out.replaceAll(RegExp(r'\b1\s*\+\s*0\s*\+\s*0\b'), 'সকালে ১টি');
    out = out.replaceAll(RegExp(r'\b0\s*\+\s*0\s*\+\s*1\b'), 'রাতে ১টি');
    out = out.replaceAll(RegExp(r'\b0\s*\+\s*1\s*\+\s*0\b'), 'দুপরে ১টি');
    out = out.replaceAll(RegExp(r'\b1\s*\+\s*1\s*\+\s*1\s*\+\s*1\b'), 'সকালে ১টি, দুপুরে ১টি, সন্ধ্যায় ১টি এবং রাতে ১টি');
    out = out.replaceAll(RegExp(r'\bdaily\b|\bod\b', caseSensitive: false), 'প্রতিদিন একবার');
    out = out.replaceAll(RegExp(r'\bbid\b|\bb\.i\.d\.?\b', caseSensitive: false), 'দিনে দুইবার');
    out = out.replaceAll(RegExp(r'\btid\b|\bt\.i\.d\.?\b', caseSensitive: false), 'দিনে তিনবার');
    out = out.replaceAll(RegExp(r'\bqid\b|\bq\.i\.d\.?\b', caseSensitive: false), 'দিনে চারবার');

    // 3. Duration patterns
    out = out.replaceAllMapped(RegExp(r'\bfor\s+(\d+)\s+days?\b', caseSensitive: false), (m) {
      final days = toBengaliDigits(m[1] ?? '১');
      return '$days দিনের জন্য';
    });
    out = out.replaceAllMapped(RegExp(r'\bfor\s+(\d+)\s+weeks?\b', caseSensitive: false), (m) {
      final weeks = toBengaliDigits(m[1] ?? '১');
      return '$weeks সপ্তাহের জন্য';
    });
    out = out.replaceAllMapped(RegExp(r'\bfor\s+(\d+)\s+months?\b', caseSensitive: false), (m) {
      final months = toBengaliDigits(m[1] ?? '১');
      return '$months মাসের জন্য';
    });

    // 4. Units
    out = out.replaceAllMapped(RegExp(r'(\d+)\s*mg\b', caseSensitive: false), (m) {
      return '${toBengaliDigits(m[1] ?? "")} মি.গ্রা.';
    });
    out = out.replaceAllMapped(RegExp(r'(\d+)\s*ml\b', caseSensitive: false), (m) {
      return '${toBengaliDigits(m[1] ?? "")} মি.লি.';
    });
    out = out.replaceAllMapped(RegExp(r'(\d+)\s*mcg\b', caseSensitive: false), (m) {
      return '${toBengaliDigits(m[1] ?? "")} মাইক্রোগ্রাম';
    });

    // 5. Forms of medicine
    out = out.replaceAll(RegExp(r'\bTab(?:let)?\.?\b', caseSensitive: false), 'ট্যাবলেট');
    out = out.replaceAll(RegExp(r'\bCap(?:sule)?\.?\b', caseSensitive: false), 'ক্যাপসুল');
    out = out.replaceAll(RegExp(r'\bSyr(?:up)?\.?\b', caseSensitive: false), 'সিরাপ');
    out = out.replaceAll(RegExp(r'\bInj(?:ection)?\.?\b', caseSensitive: false), 'ইনজেকশন');
    out = out.replaceAll(RegExp(r'\bDrop(?:s)?\.?\b', caseSensitive: false), 'ড্রপ');
    out = out.replaceAll(RegExp(r'\bOint(?:ment)?\.?\b', caseSensitive: false), 'মলম');

    // 6. Single-word Document Headers & Keywords
    out = out.replaceAll(RegExp(r'\bPrescription\b', caseSensitive: false), 'প্রেসক্রিপশন');
    out = out.replaceAll(RegExp(r'\bDoctor\b', caseSensitive: false), 'চিকিৎসক');
    out = out.replaceAll(RegExp(r'\bDate\b', caseSensitive: false), 'তারিখ');
    out = out.replaceAll(RegExp(r'\bAge\b', caseSensitive: false), 'বয়স');
    out = out.replaceAll(RegExp(r'\bDiagnosis\b', caseSensitive: false), 'রোগ নির্ণয়');
    out = out.replaceAll(RegExp(r'\bAdvice\b', caseSensitive: false), 'পরামর্শ');
    out = out.replaceAll(RegExp(r'\bInvestigation\b', caseSensitive: false), 'পরীক্ষা-নিরীক্ষা');
    out = out.replaceAll(RegExp(r'\bBill\b', caseSensitive: false), 'বিল');
    out = out.replaceAll(RegExp(r'\bAmount\b', caseSensitive: false), 'টাকা');
    out = out.replaceAll(RegExp(r'\bTotal\b', caseSensitive: false), 'মোট');
    out = out.replaceAll(RegExp(r'\bElectricity\b', caseSensitive: false), 'বিদ্যুৎ');
    out = out.replaceAll(RegExp(r'\bWater\b', caseSensitive: false), 'পানি');
    out = out.replaceAll(RegExp(r'\bGas\b', caseSensitive: false), 'গ্যাস');
    out = out.replaceAll(RegExp(r'\bPaid\b', caseSensitive: false), 'পরিশোধিত');
    out = out.replaceAll(RegExp(r'\bUnpaid\b', caseSensitive: false), 'বকেয়া');
    out = out.replaceAll(RegExp(r'\bReceipt\b', caseSensitive: false), 'রসিদ');
    out = out.replaceAll(RegExp(r'\bAccount\b', caseSensitive: false), 'হিসাব');
    out = out.replaceAll(RegExp(r'\bMeter\b', caseSensitive: false), 'মিটার');

    // Study & Education terms
    out = out.replaceAll(RegExp(r'\bChapter\b', caseSensitive: false), 'অধ্যায়');
    out = out.replaceAll(RegExp(r'\bPage\b', caseSensitive: false), 'পৃষ্ঠা');
    out = out.replaceAll(RegExp(r'\bQuestion\b', caseSensitive: false), 'প্রশ্ন');
    out = out.replaceAll(RegExp(r'\bAnswer\b', caseSensitive: false), 'উত্তর');
    out = out.replaceAll(RegExp(r'\bSubject\b', caseSensitive: false), 'বিষয়');
    out = out.replaceAll(RegExp(r'\bBook\b', caseSensitive: false), 'বই');
    out = out.replaceAll(RegExp(r'\bSummary\b', caseSensitive: false), 'সারসংক্ষেপ');
    out = out.replaceAll(RegExp(r'\bNote\b', caseSensitive: false), 'নোট');
    out = out.replaceAll(RegExp(r'\bNotice\b', caseSensitive: false), 'বিজ্ঞপ্তি');
    out = out.replaceAll(RegExp(r'\bExam(?:ination)?\b', caseSensitive: false), 'পরীক্ষা');
    out = out.replaceAll(RegExp(r'\bResult\b', caseSensitive: false), 'ফলাফল');
    out = out.replaceAll(RegExp(r'\bImportant\b', caseSensitive: false), 'গুরুত্বপূর্ণ');
    out = out.replaceAll(RegExp(r'\bEducation\b', caseSensitive: false), 'শিক্ষা');
    out = out.replaceAll(RegExp(r'\bStudent\b', caseSensitive: false), 'শিক্ষার্থী');
    out = out.replaceAll(RegExp(r'\bTeacher\b', caseSensitive: false), 'শিক্ষক');
    out = out.replaceAll(RegExp(r'\bSchool\b', caseSensitive: false), 'বিদ্যালয়');
    out = out.replaceAll(RegExp(r'\bCollege\b', caseSensitive: false), 'কলেজ');
    out = out.replaceAll(RegExp(r'\bUniversity\b', caseSensitive: false), 'বিশ্ববিদ্যালয়');

    return out;
  }

  /// Translates common Bengali document terms and phrases to English offline
  static String translateToEnglish(String text) {
    var out = text;

    // Multi-word first
    out = out.replaceAll('রোগীর নাম', 'Patient Name');
    out = out.replaceAll('চিকিৎসকের নাম', 'Doctor Name');
    out = out.replaceAll('মোট পরিমাণ', 'Total Amount');
    out = out.replaceAll('পরিশোধের শেষ তারিখ', 'Due Date');
    out = out.replaceAll('খাবারের পূর্বে', 'Before meals');
    out = out.replaceAll('খাবারের পর', 'After meals');
    out = out.replaceAll('খালি পেটে', 'Empty stomach');
    out = out.replaceAll('ঘুমানোর পূর্বে', 'Before bedtime');
    out = out.replaceAll('দিনে দুইবার', 'Twice daily (BID)');
    out = out.replaceAll('দিনে তিনবার', 'Three times daily (TID)');
    out = out.replaceAll('দিনে চারবার', 'Four times daily (QID)');
    out = out.replaceAll('প্রতিদিন একবার', 'Once daily');
    out = out.replaceAll('পানির সাথে', 'With water');
    out = out.replaceAll('চালিয়ে যান', 'Continue');
    out = out.replaceAll('বন্ধ করবেন না', 'Do not stop');

    // Single words
    out = out.replaceAll('প্রেসক্রিপশন', 'Prescription');
    out = out.replaceAll('চিকিৎসক', 'Doctor');
    out = out.replaceAll('তারিখ', 'Date');
    out = out.replaceAll('বয়স', 'Age');
    out = out.replaceAll('রোগ নির্ণয়', 'Diagnosis');
    out = out.replaceAll('পরামর্শ', 'Advice');
    out = out.replaceAll('পরীক্ষা-নিরীক্ষা', 'Investigation');
    out = out.replaceAll('বিল', 'Bill');
    out = out.replaceAll('টাকা', 'Amount');
    out = out.replaceAll('মোট', 'Total');
    out = out.replaceAll('বিদ্যুৎ', 'Electricity');
    out = out.replaceAll('পানি', 'Water');
    out = out.replaceAll('গ্যাস', 'Gas');
    out = out.replaceAll('বকেয়া', 'Unpaid');
    out = out.replaceAll('পরিশোধিত', 'Paid');
    out = out.replaceAll('রসিদ', 'Receipt');
    out = out.replaceAll('হিসাব', 'Account');
    out = out.replaceAll('মিটার', 'Meter');

    out = out.replaceAll('ট্যাবলেট', 'Tablet');
    out = out.replaceAll('ক্যাপসুল', 'Capsule');
    out = out.replaceAll('সিরাপ', 'Syrup');
    out = out.replaceAll('ইনজেকশন', 'Injection');
    out = out.replaceAll('ড্রপ', 'Drops');
    out = out.replaceAll('মলম', 'Ointment');
    out = out.replaceAll('ওষুধ', 'Medicine');
    out = out.replaceAll('রোগী', 'Patient');

    out = out.replaceAll('অধ্যায়', 'Chapter');
    out = out.replaceAll('পৃষ্ঠা', 'Page');
    out = out.replaceAll('প্রশ্ন', 'Question');
    out = out.replaceAll('উত্তর', 'Answer');
    out = out.replaceAll('বিষয়', 'Subject');
    out = out.replaceAll('বই', 'Book');
    out = out.replaceAll('সারসংক্ষেপ', 'Summary');
    out = out.replaceAll('নোট', 'Note');
    out = out.replaceAll('বিজ্ঞপ্তি', 'Notice');
    out = out.replaceAll('পরীক্ষা', 'Exam');
    out = out.replaceAll('ফলাফল', 'Result');
    out = out.replaceAll('গুরুত্বপূর্ণ', 'Important');
    out = out.replaceAll('শিক্ষা', 'Education');
    out = out.replaceAll('শিক্ষার্থী', 'Student');
    out = out.replaceAll('শিক্ষক', 'Teacher');
    out = out.replaceAll('বিদ্যালয়', 'School');
    out = out.replaceAll('কলেজ', 'College');
    out = out.replaceAll('বিশ্ববিদ্যালয়', 'University');

    return out;
  }
}
