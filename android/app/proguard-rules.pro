# flutter_local_notifications persists scheduled notifications using Gson.
# Preserve generic signatures so Gson TypeToken can recover its type at runtime.
-keepattributes Signature
-keepattributes *Annotation*
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Keep Gson model fields used while restoring scheduled notifications.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class org.xmlpull.** { *; }
