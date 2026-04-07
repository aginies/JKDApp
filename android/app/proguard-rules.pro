# Keep all Garmin ConnectIQ SDK classes with their original names.
# Android unmarshals IQDevice (and other Parcelables) from broadcast Intents by
# class name, so renaming them causes ClassNotFoundException at runtime.
-keep class com.garmin.android.connectiq.** { *; }
-dontwarn com.garmin.android.connectiq.**
