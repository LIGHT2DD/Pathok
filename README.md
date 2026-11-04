# পাঠক (Pathok) — All-in-One AI Document Companion

**Pathok** is an offline-first, privacy-focused intelligent document companion and reading assistant designed for users of all generations — students, professionals, families, and commuters. It bridges languages and document formats, empowering users to scan, extract, understand, translate, and listen to physical documents, receipts, study materials, and medical prescriptions.

---

## 🌟 Key Features

### 1. 🗂️ Universal Category Hubs
Organize and access documents with one tap through interactive Bento category hubs on the Home Dashboard:
- 📚 **Study & Books (পড়াশোনা ও বই)** — Textbooks, lecture notes, question papers, and articles.
- 🧾 **Bills & Finances (বিল ও রসিদ)** — Utility bills, receipts, invoices, and vouchers.
- 💊 **Prescriptions & Health (প্রেসক্রিপশন ও স্বাস্থ্য)** — Doctor prescriptions, medicine dosages, and diagnostic reports.
- 📄 **Notices & General (সাধারণ নথি)** — Official notices, letters, office circulars, and certificates.
- *Includes live document count badges and one-tap category filtering.*

### 2. 🧾 Smart Utility Bill & Invoice Extractor
- Automatically analyzes electricity (DESCO, DPDC), water (WASA), gas (Titas), mobile financial services (bKash, Nagad), and general utility bills.
- Accurately detects and extracts:
  - **Biller / Provider**
  - **Total Amount (মোট টাকা / ৳)**
  - **Due Date (বিল পরিশোধের শেষ তারিখ)**
  - **Account / Meter Number**
- 1-tap **"Copy Summary for Mobile Banking"** to effortlessly paste bill payment details into bKash or Nagad.

### 3. 🌐 Bidirectional Translation & Vocabulary Lookup (English $\leftrightarrow$ Bangla)
- **Full Document Translation**:
  - Script ratio analysis detects whether the document is English or Bengali.
  - Translates **English $\rightarrow$ Bangla** and **Bangla $\rightarrow$ English** on demand.
  - Dual-tab document interface: `[ Original (মূল পাঠ) ]` and `[ Translated (অনুবাদ) ]`.
- **Direct Word & Sentence Selection**:
  - Highlight any text in the document using native selection to trigger an inline **"Translate"** popup menu action.
- **Smart Vocabulary Extractor Chips**:
  - Automatically parses key vocabulary words from the document into clickable suggestion chips.
- **Dedicated Word / Phrase Lookup Sheet**:
  - Bidirectional search with instant pronunciation audio in `bn-BD` or `en-US`.
- **Hybrid Offline Translation Architecture**:
  - Powered on-device by Google ML Kit Neural Machine Translation (`google_mlkit_translation`).
  - Zero-bandwidth domain-specific fallback dictionary (`PrescriptionOfflineTranslator`) for medical, study, and financial keywords.

### 4. 🎙️ Expanded Audio Controls & Bilingual Speech
- **Study Speed Playback**: Cycle playback speeds tailored for both close listening and rapid revision:
  `0.75x` $\rightarrow$ `1.0x` $\rightarrow$ `1.25x` $\rightarrow$ `1.5x` $\rightarrow$ `1.75x` $\rightarrow$ `2.0x`.
- **Live Karaoke Highlighting**: Word-by-word synchronized highlighting during voice playback.
- **Bilingual Code-Switching Engine**: Automatically detects mixed language sentences and seamlessly switches pronunciation between native Bengali (`bn-BD`) and English (`en-US`) voices.
- **Lock-Screen & Notification Media Controls**: Play, pause, resume, and stop speech playback directly from the lock screen and notification drawer.

### 5. 🔍 Offline OCR & PDF Ingestion
- **Camera & Gallery OCR**: Powered by on-device Tesseract 4 engine with pre-bundled `ben.traineddata` and `eng.traineddata`.
- **Multi-Pass Image Enhancement**: Automatic grayscale conversion, adaptive thresholding, and contrast preconditioning via `ImagePreprocessor`.
- **PDF Extraction**: Native multi-page text extraction and structured text export via `SyncfusionFlutterPdf`.

### 6. 💊 Prescription Assistance & Medicine Reminders
- Identifies dosage lines and frequencies from prescriptions.
- Daily medicine reminder scheduling with exact Android alarms and lock-screen privacy safeguards.
- Interactive daily checklist on the Home Dashboard with taken/pending status tracking.

### 7. 🔒 Security & Privacy by Design
- **Local AES-256-GCM Encryption**: All document metadata, notes, and reminders are encrypted at rest using an Android Keystore-backed key (`flutter_secure_storage`).
- **Encrypted Backup & Restore**: Export and import encrypted backups protected by PBKDF2-SHA256 user passphrases.
- **Biometric & PIN App Lock**: Locks upon app minimization and requires fingerprint or PIN authentication to open.
- **Zero Cloud Dependence**: All OCR, parsing, and data storage run 100% locally on the device.

---

## 🛠️ Project Architecture

```
lib/
├── app/
│   ├── app.dart                   # Application root, theme management, and locale scope
│   └── theme.dart                 # Material 3 light and dark themes
├── core/
│   ├── constants/                 # PathokIcons, VoiceProfiles
│   ├── localization/              # AppStrings (100% pure Bangla or English based on Settings)
│   ├── notifications/             # Local notifications & ongoing audio playback notification
│   └── security/                  # AES-256-GCM encrypted persistence (SecureDataStore)
└── features/
    ├── auth/                      # Biometric & PIN lock screen
    ├── documents/
    │   ├── data/                  # DocumentRepository (secure persistence, file copies)
    │   ├── models/                # LocalDocument model (categories, translation fields)
    │   ├── presentation/          # HomeScreen, HomeTab (Bento hubs), DocumentScreen, HistoryTab
    │   └── services/              # BillExtractor, LanguageDetector, PdfService, TranslationService
    ├── ocr/                       # OfflineOcrService, ImagePreprocessor
    ├── onboarding/                # Clean task-first onboarding flow
    ├── prescription/              # PrescriptionService, MedicineReminder, PrescriptionDialog
    └── settings/                  # SettingsTab (Language toggle, voice picker, theme, backups)
```

---

## 🚀 Running & Building

### 1. Run Unit & Widget Tests
```powershell
flutter test
```

### 2. Run Static Analysis
```powershell
flutter analyze
```

### 3. Run in Chrome (Web Preview)
```powershell
flutter run -d chrome
```

### 4. Build Small ARM64 Android APK
To compile an optimized, standalone 64-bit ARM APK:
```powershell
flutter build apk --debug --target-platform android-arm64 --split-per-abi
```
The resulting lightweight binary is generated at:
`build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`

---

## 📜 License
Private & Proprietary. All rights reserved.
