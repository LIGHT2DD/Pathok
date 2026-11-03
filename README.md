# পাঠক (Pathok)

Pathok is an Android-first, accessibility-focused document reading assistant for
Bangla and English users.

## Current milestone

The initial Flutter foundation includes:

- Bangla-first Material 3 onboarding and navigation.
- Camera capture and gallery image import through the native Android picker.
- App-private persistent document metadata and source-file copies.
- PDF import and text PDF export.
- On-device Latin-script OCR through Google ML Kit.
- Bangla text-to-speech controls using the device's installed voice.
- History and settings surfaces designed for TalkBack and large-text use.
- Onboarding completion stored locally with `shared_preferences`.

The current document list persists locally. The first OCR integration supports
Latin-script documents on Android through Google ML Kit. Google ML Kit's Latin
script recognizer does not provide Bangla recognition, so Bangla OCR is not
claimed until a verified on-device Bangla model is packaged and evaluated.

## Run and validate

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android camera/gallery permissions are supplied by `image_picker`. A device
or emulator with a compatible Bangla TTS voice is required for read-aloud.

## Architecture direction

The app is currently a small vertical slice in `lib/main.dart` so the first
workflow can be tested end-to-end. Before adding prescription extraction and
encrypted persistence, the next refactor should split it into feature modules
(`onboarding`, `documents`, `speech`, and `settings`) and introduce repositories
plus Riverpod providers. Offline OCR must be backed by a verified on-device
model; online OCR must remain an explicitly consented fallback.
