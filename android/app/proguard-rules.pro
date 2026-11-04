# ML Kit optional scripts
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Flutter Play Core Deferred Components (not used in standalone APK)
-dontwarn com.google.android.play.core.**

# Flutter framework & plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage & AndroidX Security
-keep class androidx.security.crypto.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# flutter_tesseract_ocr
-keep class io.paratoner.flutter_tesseract_ocr.** { *; }

# flutter_tts
-keep class com.tundralabs.fluttertts.** { *; }

# Desugar JDK libraries
-dontwarn java.lang.invoke.**

# Google ML Kit Translation
-keep class com.google.mlkit.nl.translate.** { *; }
-dontwarn com.google.mlkit.nl.translate.**
