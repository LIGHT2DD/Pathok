# Flutter framework & plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Core Deferred Components
-dontwarn com.google.android.play.core.**

# Keep all registered Flutter plugins
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.paratoner.flutter_tesseract_ocr.** { *; }
-keep class com.eyedeadevelopment.fluttertts.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_translation.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Google ML Kit & Google Play Services
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AndroidX Security & Crypto
-keep class androidx.security.crypto.** { *; }

# Desugar JDK libraries
-dontwarn java.lang.invoke.**
