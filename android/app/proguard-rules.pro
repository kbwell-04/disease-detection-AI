# Keep all TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }

# Keep GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }

# Keep JNI and native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep classes with annotations
-keep @interface android.support.annotation.Keep
-keep @interface androidx.annotation.Keep
-keep class * {
    @android.support.annotation.Keep <fields>;
    @android.support.annotation.Keep <methods>;
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
}
