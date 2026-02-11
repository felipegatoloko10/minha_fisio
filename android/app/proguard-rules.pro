#Flutter Wrapper
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-dontwarn com.dexterous.flutterlocalnotifications.**

# Gson (Necessário para serialização das notificações)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
