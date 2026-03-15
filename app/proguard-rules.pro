# Android základné pravidlá
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.view.View

# Zachovať všetky triedy s native metódami
-keepclasseswithmembernames class * {
    native <methods>;
}

# Zachovať všetky enum hodnoty
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Zachovať Serializable triedy
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Zachovať Parcelable implementácie
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# AndroidX pravidlá
-keep class androidx.** { *; }
-dontwarn androidx.**

# Kotlin pravidlá
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Aplikácia-špecifické pravidlá
-keep class sk.dataindicator.** { *; }

# Network state monitoring
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service

# Material Design komponenty
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Optimalizácie - odstránenie logov v release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# R8 optimalizácie
-allowaccessmodification
-repackageclasses