# পাঠক (Pathok)

Pathok is an Android-first, accessibility-focused document reading assistant for
Bangla and English users.

## Current milestone

The initial Flutter foundation includes:

- Bangla-first Material 3 onboarding and navigation.
- Camera capture and gallery image import through the native Android picker.
- App-private persistent document metadata and source-file copies.
- PDF import and text PDF export.
- On-device Bangla and English OCR through Tesseract 4 with bundled models.
- Image file quality gating before OCR.
- Explicit OCR result limitation messaging when model confidence is unavailable.
- Conservative prescription-line extraction with mandatory confirmation.
- User-selected daily medicine reminders with Android local notifications.
- Destructive delete-all-data control for local documents, copied files, and reminders.
- Supplied Pathok launcher branding and Tabler icon font styling.
- Bangla text-to-speech controls using the device's installed voice.
- History and settings surfaces designed for TalkBack and large-text use.
- Searchable document history.
- Reminder deletion with notification cancellation.
- Onboarding completion stored locally with `shared_preferences`.

The current document list persists locally. OCR uses the Tesseract 4 Android
engine with bundled `ben.traineddata` and `eng.traineddata` models, so the
core OCR path does not require network access. OCR confidence is not exposed
by the Flutter integration; users are instructed to review and edit results.
Prescription extraction currently identifies medicine-like lines only; it does
not diagnose or recommend treatment. Reminder scheduling requires explicit
confirmation and a user-selected time; it does not infer a dosage schedule.

## Run and validate

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android camera/gallery permissions are supplied by `image_picker`. A device
or emulator with a compatible Bangla TTS voice is required for read-aloud.
`flutter run -d chrome` is supported for UI review; camera, Android Keystore,
biometric lock, Android notifications, and native Tesseract behavior must be
validated on Android.

Release artifacts are generated at:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

The current release build uses the generated debug signing key. A production
keystore and Play App Signing configuration must be supplied before publishing.

## Architecture direction

The app is currently a small vertical slice in `lib/main.dart` so the first
workflow can be tested end-to-end. Before adding prescription extraction and
encrypted persistence, the next refactor should split it into feature modules
(`onboarding`, `documents`, `speech`, and `settings`) and introduce repositories
plus Riverpod providers. Online OCR, if added later, must remain an explicitly
consented fallback.

## Next improvements

- Add a real Bangla OCR evaluation set and report Character Error Rate and Word
  Error Rate for printed documents and prescriptions.
- Add native image preprocessing (crop, deskew, perspective correction,
  contrast, blur and glare checks) before Tesseract.
- Expose Tesseract word-level confidence through the Android bridge and
  highlight low-confidence words for review.
- Add reminder edit, snooze, and multiple-times-per-day workflows.
- Add a production CI pipeline and configure a user-owned upload keystore
  before Play publishing.

## Security notes

Document metadata, OCR text, and confirmed reminder records are encrypted with
AES-GCM. The encryption key is stored through Android Keystore-backed
`flutter_secure_storage`. Existing plaintext metadata is migrated once and
removed from `shared_preferences`. App lock uses the device biometric or PIN
through `local_auth`, and delete-all-data removes encrypted records, copied
files, and scheduled notifications.

The release build still uses the generated debug signing key. Configure a
production keystore and Play App Signing before publishing.
