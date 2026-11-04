import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.isEnglish);

  final bool isEnglish;

  // General
  String get appName => isEnglish ? 'Pathok' : 'পাঠক';
  String get tagline => isEnglish ? 'Your All-in-One AI Document Companion' : 'আপনার অল-ইন-ওয়ান এআই নথি ও পাঠ সহকারী';
  String get cancel => isEnglish ? 'Cancel' : 'বাতিল';
  String get save => isEnglish ? 'Save' : 'সংরক্ষণ';
  String get delete => isEnglish ? 'Delete' : 'মুছুন';
  String get deletePermanently => isEnglish ? 'Delete permanently' : 'স্থায়ীভাবে মুছুন';
  String get close => isEnglish ? 'Close' : 'বন্ধ করুন';
  String get confirm => isEnglish ? 'Confirm' : 'নিশ্চিত করুন';
  String get retry => isEnglish ? 'Retry' : 'পুনরায় চেষ্টা করুন';
  String get error => isEnglish ? 'Error' : 'ত্রুটি';
  String get success => isEnglish ? 'Success' : 'সফল';
  String get noText => isEnglish ? 'No text entered.' : 'কোনো লেখা নেই।';
  String get emptyText => isEnglish ? 'Empty text' : 'খালি লেখা';

  // Navigation
  String get navHome => isEnglish ? 'Home' : 'হোম';
  String get navDocuments => isEnglish ? 'Documents' : 'নথি';
  String get navSettings => isEnglish ? 'Settings' : 'সেটিংস';

  // Onboarding
  String get onboardingTitle => isEnglish ? 'Read documents with ease' : 'সহজে নথি পড়ুন';
  String get onboardingSubtitle => isEnglish ? 'An offline, privacy-first reading assistant for Bangla & English.' : 'অফলাইন ও ব্যক্তিগত বাংলা এবং ইংরেজি পাঠ সহকারী।';
  String get onboardingBenefit1 => isEnglish ? 'Scan photos or PDFs to extract text' : 'ছবি বা PDF স্ক্যান করে লেখা পড়ুন';
  String get onboardingBenefit2 => isEnglish ? 'Listen to text offline with native speech' : 'ডিভাইসের ভয়েস দিয়ে অফলাইনে শুনুন';
  String get onboardingBenefit3 => isEnglish ? 'Encrypted and strictly private on this device' : 'আপনার ডিভাইসেই তথ্য এনক্রিপ্ট ও সুরক্ষিত';
  String get onboardingNoAccount => isEnglish ? 'No account or internet connection required.' : 'কোনো অ্যাকাউন্ট বা ইন্টারনেট সংযোগ লাগবে না।';
  String get getStarted => isEnglish ? 'Get started' : 'শুরু করুন';

  // Auth / Lock
  String get lockedTitle => isEnglish ? 'Pathok is locked' : 'পাঠক লক করা আছে';
  String get unlock => isEnglish ? 'Unlock' : 'আনলক করুন';
  String get authReason => isEnglish ? 'Authenticate to access your private documents' : 'আপনার গোপনীয় নথি দেখতে পরিচয় যাচাই করুন';

  // Home Dashboard
  String get welcomeGreeting => isEnglish ? 'Welcome!' : 'স্বাগতম!';
  String get greetingMorning => isEnglish ? 'Good morning!' : 'শুভ সকাল!';
  String get greetingAfternoon => isEnglish ? 'Good afternoon!' : 'শুভ দুপুর!';
  String get greetingEvening => isEnglish ? 'Good evening!' : 'শুভ সন্ধ্যা!';
  String get offlineBadge => isEnglish ? 'Offline & Encrypted' : 'অফলাইন ও সুরক্ষিত';
  String get quickActions => isEnglish ? 'Quick Actions' : 'কুইক অ্যাকশন';
  String get welcomeSubtitle => isEnglish ? 'Ready to listen to your documents?' : 'আপনার নথি শুনতে প্রস্তুত?';
  String get addNewDocument => isEnglish ? 'Add a new document' : 'নতুন নথি যোগ করুন';
  String get scanCamera => isEnglish ? 'Scan with camera' : 'ক্যামেরা দিয়ে স্ক্যান করুন';
  String get scanCameraSubtitle => isEnglish ? 'Take a clear photo of a printed document' : 'ছাপা নথির স্পষ্ট ছবি তুলুন';
  String get choosePdf => isEnglish ? 'Choose a PDF' : 'PDF বেছে নিন';
  String get choosePdfSubtitle => isEnglish ? 'Select a PDF document from storage' : 'ডিভাইস থেকে PDF নথি নির্বাচন করুন';
  String get chooseImage => isEnglish ? 'Choose an image' : 'ছবি বেছে নিন';
  String get chooseImageSubtitle => isEnglish ? 'Select an image from gallery' : 'গ্যালারি থেকে ছবি বেছে নিন';
  String get recentDocuments => isEnglish ? 'Recent documents' : 'সাম্প্রতিক নথি';
  String get noDocumentsYet => isEnglish ? 'No documents yet.\nChoose an option above to begin.' : 'এখনও কোনো নথি নেই।\nউপরের একটি অপশন দিয়ে শুরু করুন।';
  String documentsCount(int count) => isEnglish ? '$count documents' : '$countটি নথি';
  String get filterAll => isEnglish ? 'All' : 'সব';
  String get filterPhotos => isEnglish ? 'Photos' : 'ছবি';
  String get filterPdfs => isEnglish ? 'PDFs' : 'PDF';
  String get categoryStudy => isEnglish ? 'Study & Books' : 'পড়াশোনা ও বই';
  String get categoryBills => isEnglish ? 'Bills & Finances' : 'বিল ও রসিদ';
  String get categoryPrescriptions => isEnglish ? 'Prescriptions & Health' : 'প্রেসক্রিপশন ও স্বাস্থ্য';
  String get categoryGeneral => isEnglish ? 'Notices & General' : 'সাধারণ নথি';
  String get categoryIdCards => isEnglish ? 'Cards & ID' : 'পরিচয়পত্র';
  String get categoryHubs => isEnglish ? 'Document Hubs' : 'ক্যাটাগরি হাব';
  String get fastScanBadge => isEnglish ? 'FAST SCAN' : 'দ্রুত স্ক্যান';
  String get categoryStudySubtitle => isEnglish ? 'Books & Study' : 'বই ও পড়াশোনা';
  String get categoryBillsSubtitle => isEnglish ? 'Utilities & Receipts' : 'বিদ্যুৎ ও রসিদ';
  String get categoryPrescriptionsSubtitle => isEnglish ? 'Medicines & Health' : 'ওষুধ ও প্রেসক্রিপশন';
  String get categoryGeneralSubtitle => isEnglish ? 'Notes & Notices' : 'নোট ও নোটিশ';
  String get pinDocument => isEnglish ? 'Pin to top' : 'উপরে পিন করুন';
  String get unpinDocument => isEnglish ? 'Unpin' : 'পিন সরান';
  String get pinned => isEnglish ? 'Pinned' : 'পিন করা';
  String get todaysMedicines => isEnglish ? "Today's Medicines" : 'আজকের ওষুধ';
  String get markTaken => isEnglish ? 'Mark as taken' : 'খেয়েছি';
  String get taken => isEnglish ? 'Taken' : 'খাওয়া হয়েছে';
  String get pending => isEnglish ? 'Pending' : 'বাকি আছে';
  String get snooze10m => isEnglish ? 'Snooze 10m' : '১০ মি. পর';
  String get allMedicinesTaken => isEnglish ? 'All medicines taken today!' : 'আজকের সব ওষুধ খাওয়া সম্পন্ন হয়েছে!';
  String get playingAudio => isEnglish ? 'Playing voice...' : 'ভয়েস চলছে...';
  String get audioSpeed => isEnglish ? 'Speed' : 'গতি';

  // Document Screen
  String get documentDetails => isEnglish ? 'Document' : 'নথি বিবরণ';
  String get recognizedText => isEnglish ? 'Recognized text' : 'স্বীকৃত লেখা';
  String get documentHint => isEnglish ? 'Enter or edit text here...' : 'এখানে নথির লেখা লিখুন বা সম্পাদনা করুন...';
  String get runOfflineOcr => isEnglish ? 'Run offline OCR' : 'অফলাইন OCR চালান';
  String get extractPdfText => isEnglish ? 'Extract text from PDF' : 'PDF থেকে লেখা বের করুন';
  String get recognizing => isEnglish ? 'Recognizing text...' : 'লেখা শনাক্ত হচ্ছে...';
  String get extractingPdf => isEnglish ? 'Extracting PDF text...' : 'PDF লেখা বিশ্লেষণ হচ্ছে...';
  String get listenToText => isEnglish ? 'Listen to text' : 'লেখা শুনুন';
  String get pauseListening => isEnglish ? 'Pause' : 'বিরতি';
  String get resumeListening => isEnglish ? 'Resume' : 'পুনরায় শুনুন';
  String get pausedAudio => isEnglish ? 'Audio paused' : 'ভয়েস স্থগিত আছে';
  String get stopListening => isEnglish ? 'Stop' : 'থামুন';
  String get prescriptionAssistance => isEnglish ? 'Prescription assistance' : 'প্রেসক্রিপশন সহায়তা';
  String get exportPdf => isEnglish ? 'Export as PDF' : 'PDF হিসেবে সংরক্ষণ';
  String get shareText => isEnglish ? 'Share text' : 'লেখা শেয়ার করুন';
  String get pdfExportSuccess => isEnglish ? 'PDF exported successfully' : 'PDF সফলভাবে তৈরি হয়েছে';
  String get noTextToShare => isEnglish ? 'There is no text to share.' : 'শেয়ার করার মতো কোনো লেখা নেই।';
  String get noTextToSpeak => isEnglish ? 'Add text before starting playback.' : 'শোনার আগে লেখা যোগ করুন।';
  String get ocrFailed => isEnglish ? 'OCR failed. Please try with a clearer photo.' : 'OCR ব্যর্থ হয়েছে। আরও স্পষ্ট ছবি দিয়ে চেষ্টা করুন।';
  String get noTextFoundInImage => isEnglish ? 'No readable text was detected.' : 'কোনো স্পষ্ট লেখা পাওয়া যায়নি।';

  // TTS Language & Translation
  String get speechLanguage => isEnglish ? 'Speech language' : 'পড়ার ভাষা';
  String get speechBangla => isEnglish ? 'Bangla' : 'বাংলা';
  String get speechEnglish => isEnglish ? 'English' : 'ইংরেজি';
  String get languageDetected => isEnglish ? 'Detected language' : 'শনাক্ত ভাষা';
  String get mixedLanguage => isEnglish ? 'Bilingual' : 'দ্বিভাষিক';
  String languageRatio(int bnPct, int enPct) => isEnglish 
      ? 'Bengali letters: $bnPct% | English letters: $enPct%' 
      : 'বাংলা অক্ষর: $bnPct% | ইংরেজি অক্ষর: $enPct%';
  String get bilingualVoiceSubtitle => isEnglish 
      ? 'Switch naturally between Bengali and English voices' 
      : 'ইংরেজি শব্দ ও বাংলা নির্দেশনা আলাদা স্বাভাবিক কণ্ঠে পড়ুন';
  String get speechBanglaSubtitle => isEnglish 
      ? 'Read all text in Bangla voice' 
      : 'সব লেখা বাংলা ভয়েসে শুনুন';
  String get speechEnglishSubtitle => isEnglish 
      ? 'Read all text in English voice' 
      : 'সব লেখা ইংরেজি ভয়েসে শুনুন';
  String get originalText => isEnglish ? 'Original' : 'মূল পাঠ';
  String get translatedText => isEnglish ? 'Translated' : 'অনুবাদ';
  String get translate => isEnglish ? 'Translate' : 'অনুবাদ করুন';
  String get translateToBangla => isEnglish ? 'Translate to Bangla' : 'বাংলায় অনুবাদ করুন';
  String get translateToEnglish => isEnglish ? 'Translate to English' : 'ইংরেজিতে অনুবাদ করুন';
  String get translating => isEnglish ? 'Translating text...' : 'অনুবাদ করা হচ্ছে...';
  String get translationComplete => isEnglish ? 'Translation completed' : 'অনুবাদ সম্পন্ন হয়েছে';
  String get translationFailed => isEnglish ? 'Translation failed' : 'অনুবাদ ব্যর্থ হয়েছে';
  String get downloadingModel => isEnglish ? 'Downloading offline model (~25MB)...' : 'অফলাইন মডেল ডাউনলোড হচ্ছে (~২৫ মেগাবাইট)...';
  String get instantTranslation => isEnglish ? 'Instant Offline Translation' : 'তাৎক্ষণিক অনুবাদ';
  String get downloadModel => isEnglish ? 'Download Model' : 'মডেল ডাউনলোড';
  String get downloadModelPromptEnToBn => isEnglish 
      ? 'An on-device Google ML Kit model (~25MB) is available for neural translation.\n\nWould you like to download it now or use instant offline translation?'
      : 'পূর্ণাঙ্গ অনুবাদের জন্য গুগল এমএল কিট অফলাইন মডেল (~২৫ মেগাবাইট) প্রয়োজন।\n\nআপনি কি এখন ডাউনলোড করবেন, নাকি তাৎক্ষণিক অফলাইন অনুবাদ ব্যবহার করবেন?';
  String get downloadModelPromptBnToEn => isEnglish
      ? 'Translate to English using the on-device ML model or instant offline translation.'
      : 'ইংরেজি অনুবাদের জন্য ডিভাইসের এমএল মডেল বা তাৎক্ষণিক অফলাইন রূপান্তর ব্যবহৃত হবে।';
  String get bilingualVoice => isEnglish ? 'Bilingual Voice' : 'দ্বিভাষিক ভয়েস';
  String get clearTranslation => isEnglish ? 'Remove translation' : 'অনুবাদ সরান';

  // Prescription & Reminders
  String get possibleMedicines => isEnglish ? 'Possible medicines' : 'সম্ভাব্য ওষুধ';
  String get prescriptionDisclaimer => isEnglish 
      ? 'These candidates were identified from the text and are NOT medical advice. Verify medicine names and dosages carefully before setting a reminder.'
      : 'লেখা থেকে সম্ভাব্য ওষুধের নাম শনাক্ত করা হয়েছে। এটি চিকিৎসার পরামর্শ নয়। রিমাইন্ডার সেট করার পূর্বে অবশ্যই যাচাই করুন।';
  String get noMedicinesFound => isEnglish ? 'No medicine lines detected in the text.' : 'লেখায় কোনো ওষুধের নাম শনাক্ত হয়নি।';
  String get scheduleReminder => isEnglish ? 'Schedule reminder' : 'রিমাইন্ডার সেট করুন';
  String get selectTime => isEnglish ? 'Select time' : 'সময় নির্বাচন করুন';
  String reminderSavedCount(int count) => isEnglish ? '$count reminder(s) scheduled.' : '$countটি রিমাইন্ডার সংরক্ষিত হয়েছে।';
  String get verifyInstructions => isEnglish ? 'Verify dosage with doctor/pack' : 'ব্যবহারবিধি যাচাই করুন';
  String get presetMorning => isEnglish ? 'Morning (08:00)' : 'সকাল (০৮:০০)';
  String get presetNoon => isEnglish ? 'Afternoon (13:30)' : 'দুপুর (০১:৩০)';
  String get presetNight => isEnglish ? 'Night (21:30)' : 'রাত (০৯:৩০)';
  String get duplicateWarning => isEnglish ? 'Similar/duplicate medicine found' : 'অনুরূপ বা দ্বৈত ওষুধ শনাক্ত';
  String get appendPage => isEnglish ? 'Append page' : 'পরবর্তী পাতা যোগ';
  String get pageAppended => isEnglish ? 'Page appended successfully' : 'পাতা সফলভাবে যোগ করা হয়েছে';
  String get liveReader => isEnglish ? 'Karaoke speech highlight' : 'লাইভ পড়ার হাইলাইট';

  // Bill / Finance Analysis
  String get billAnalysis => isEnglish ? 'Bill Analysis' : 'বিল বিশ্লেষণ';
  String get totalAmount => isEnglish ? 'Total Amount' : 'মোট টাকা';
  String get dueDate => isEnglish ? 'Due Date' : 'পরিশোধের শেষ তারিখ';
  String get billerName => isEnglish ? 'Biller / Provider' : 'বিল প্রদানকারী সংস্থা';
  String get accountNo => isEnglish ? 'Account / Meter No.' : 'হিসাব বা মিটার নম্বর';
  String get billSummaryCopied => isEnglish ? 'Bill payment summary copied!' : 'বিল বিবরণ কপি করা হয়েছে!';
  String get copyPaymentSummary => isEnglish ? 'Copy Payment Summary' : 'পেমেন্ট বিবরণ কপি করুন';
  String get billPaymentDetails => isEnglish ? 'Bill & Payment Summary' : 'বিল ও পেমেন্ট বিবরণী';

  // Word & Phrase Lookup
  String get wordLookup => isEnglish ? 'Word / Phrase Lookup' : 'শব্দার্থ ও অনুবাদ';
  String get enterWordOrPhrase => isEnglish ? 'Enter word or phrase' : 'শব্দ বা ছোট বাক্য লিখুন';
  String get lookup => isEnglish ? 'Lookup' : 'অর্থ খুঁজুন';
  String get wordMeaning => isEnglish ? 'Meaning' : 'অনুবাদ ও অর্থ';
  String get documentWords => isEnglish ? 'Document Words (Tap to Translate):' : 'নথির মূল শব্দসমূহ:';

  // History Screen
  String get searchDocuments => isEnglish ? 'Search documents' : 'নথি খুঁজুন';
  String get noDocumentsMatch => isEnglish ? 'No documents match this search.' : 'এই অনুসন্ধানের সাথে কোনো নথি মেলেনি।';
  String get renameDocument => isEnglish ? 'Rename document' : 'নথির নাম পরিবর্তন';
  String get deleteDocument => isEnglish ? 'Delete document?' : 'নথি মুছবেন?';
  String deleteDocumentConfirm(String title) => isEnglish 
      ? '"$title" will be permanently deleted.' 
      : '“$title” স্থায়ীভাবে মুছে ফেলা হবে।';

  // Settings
  String get preferences => isEnglish ? 'Preferences' : 'পছন্দসমূহ';
  String get language => isEnglish ? 'Language' : 'ভাষা';
  String get currentLanguage => isEnglish ? 'English' : 'বাংলা';
  String get darkMode => isEnglish ? 'Dark mode' : 'ডার্ক মোড';
  String get darkModeSubtitle => isEnglish ? 'High contrast appearance' : 'উচ্চ বৈসাদৃশ্য ডিসপ্লে';
  String get readingVoice => isEnglish ? 'Reading voice' : 'পড়ার কণ্ঠ';
  String get readingVoiceSubtitle => isEnglish ? 'Select male or female voice' : 'পুরুষ বা নারী কণ্ঠ বেছে নিন';
  String get voiceTestSample => isEnglish ? 'This is how your selected voice will read documents.' : 'আপনার নির্বাচিত কণ্ঠে এভাবেই নথি পড়া হবে।';
  String get appLock => isEnglish ? 'App lock' : 'অ্যাপ লক';
  String get appLockSubtitle => isEnglish ? 'Require fingerprint or PIN' : 'বায়োমেট্রিক বা পিন দিয়ে সুরক্ষিত রাখুন';
  String get remindersTitle => isEnglish ? 'Active Reminders' : 'সক্রিয় রিমাইন্ডার';
  String get noRemindersYet => isEnglish ? 'No reminders saved yet.' : 'এখনও কোনো রিমাইন্ডার নেই।';
  String get privacyAccessibility => isEnglish ? 'Privacy & Security' : 'গোপনীয়তা ও নিরাপত্তা';
  String get offlineMode => isEnglish ? 'Offline mode' : 'সম্পূর্ণ অফলাইন';
  String get offlineModeSubtitle => isEnglish ? 'All OCR and processing runs locally' : 'সব কাজ আপনার ডিভাইসেই ঘটে';
  String get exportEncryptedBackup => isEnglish ? 'Export encrypted backup' : 'এনক্রিপ্ট করা ব্যাকআপ নিন';
  String get exportBackupSubtitle => isEnglish ? 'Create password-protected backup file' : 'পাসওয়ার্ড দিয়ে ব্যাকআপ ফাইল সংরক্ষণ করুন';
  String get restoreBackup => isEnglish ? 'Restore backup' : 'ব্যাকআপ রিস্টোর করুন';
  String get restoreBackupSubtitle => isEnglish ? 'Restore from previous Pathok backup' : 'পূর্বের ব্যাকআপ থেকে নথি ফিরিয়ে আনুন';
  String get deleteAllData => isEnglish ? 'Delete all local data' : 'সব তথ্য মুছে ফেলুন';
  String get deleteAllConfirm => isEnglish 
      ? 'All documents, saved images, and scheduled reminders will be permanently erased.' 
      : 'সব সংরক্ষিত নথি, ছবি এবং রিমাইন্ডার স্থায়ীভাবে মুছে ফেলা হবে।';
  String get allDataDeleted => isEnglish ? 'All local data was deleted.' : 'সব স্থানীয় তথ্য মুছে ফেলা হয়েছে।';
  String get enterPassphrase => isEnglish ? 'Enter backup passphrase (min 6 characters)' : 'ব্যাকআপের পাসওয়ার্ড লিখুন (কমপক্ষে ৬ অক্ষর)';
  String get backupSaved => isEnglish ? 'Backup successfully saved.' : 'ব্যাকআপ সফলভাবে সংরক্ষিত হয়েছে।';
  String get backupRestored => isEnglish ? 'Backup successfully restored.' : 'ব্যাকআপ সফলভাবে রিস্টোর হয়েছে।';
  String get invalidPassphrase => isEnglish ? 'Incorrect passphrase or corrupted backup file.' : 'ভুল পাসওয়ার্ড অথবা ব্যাকআপ ফাইলটি ত্রুটিযুক্ত।';

  String get onboardingBadge => isEnglish ? '100% Offline & Private' : '১০০% অফলাইন ও নিরাপদ';
  String get onboardingFeature1Title => isEnglish ? 'Scan Documents & Photos' : 'ছবি ও PDF স্ক্যানিং';
  String get onboardingFeature2Title => isEnglish ? 'Natural Voice Playback' : 'স্বাভাবিক ভয়েস পাঠ';
  String get onboardingFeature3Title => isEnglish ? 'Encrypted & Local' : 'ডিভাইসে এনক্রিপ্ট ও সুরক্ষিত';
  String get ttsVoiceMissingBengali => isEnglish 
      ? 'Bangla voice data is missing on device. Playing with default voice.' 
      : 'ডিভাইসে বাংলা ভয়েস ডেটা পাওয়া যায়নি। ডিফল্ট ভয়েসে চালানো হচ্ছে।';

  static AppStrings of(BuildContext context) {
    final locale = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    return AppStrings(locale?.isEnglish ?? true);
  }
}

class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    required this.isEnglish,
    required super.child,
    super.key,
  });

  final bool isEnglish;

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) => isEnglish != oldWidget.isEnglish;
}

