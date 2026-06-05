# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio (HTTP client)
-keep class com.fmpprep.frontend.** { *; }
-dontwarn com.fmpprep.frontend.**

# Keep serializable classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Image picker
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# General
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
