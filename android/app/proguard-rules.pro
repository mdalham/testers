-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

-keep class android.database.sqlite.** { *; }
-keep class sqflite.** { *; }

-keep class *.Adapter { *; }
-keep class **.hive.** { *; }

-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keep class com.facebook.** { *; }
-keep interface com.facebook.** { *; }
-dontwarn com.facebook.**

-keep class com.unity3d.ads.** { *; }
-keep interface com.unity3d.ads.** { *; }
-dontwarn com.unity3d.ads.**

-dontwarn io.flutter.embedding.**
-dontwarn com.google.ads.**
-dontwarn com.google.android.gms.**
-dontwarn androidx.**
-dontwarn org.jetbrains.**