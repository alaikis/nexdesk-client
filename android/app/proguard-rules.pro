# Flutter
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App
-keep class com.elstella.flutter_app.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }

# libsodium / sodium
-keep class org.libsodium.jni.** { *; }

# Don't warn about missing classes
-dontwarn io.flutter.**
-dontwarn org.webrtc.**
-dontwarn org.libsodium.jni.**
-dontwarn com.elstella.nex.**
