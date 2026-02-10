#Flutter Wrapper
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepclassmembers class * {
    ** fromJson(...);
}
-keep class com.google.gson.** { *; }
