-keep class net.sqlcipher.** { *; }
-keep class eu.twonly.location.NativeLiveLocationBridge { *; }

# Room 2.6 keeps database class names, but R8 full mode also needs the no-arg
# constructors that Room uses reflectively (including WorkDatabase_Impl).
-keep,allowoptimization class * extends androidx.room.RoomDatabase {
    public <init>();
}

# WorkManager instantiates these jobs by class name through reflection. Retain
# the classes, constructors and execution entry points in R8 full mode, including
# stable class names for work persisted before an app update.
-keep,allowoptimization class eu.twonly.** extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
    public androidx.work.ListenableWorker$Result doWork();
}

# Rust resolves these classes in JNI_OnLoad and calls these static methods by
# name. R8 cannot see those references in librust_lib_twonly.so. Keep only the
# JNI entry points; their implementations and other members may be optimized.
-keep,allowoptimization class eu.twonly.directmedia.DirectMediaTransfer {
    public static boolean schedule(java.lang.String);
    public static boolean recover(java.lang.String, long);
}
-keep,allowoptimization class eu.twonly.directmedia.DirectMediaPrepare {
    public static boolean schedule(java.lang.String);
}
-keep,allowoptimization class eu.twonly.media.NativeImageCodec {
    public static boolean decodeToPng(java.lang.String, java.lang.String);
}
-keep,allowoptimization class eu.twonly.media.NativeVideoCodec {
    public static boolean render(java.lang.String, java.lang.String, java.lang.String, boolean, long, long, java.lang.String);
    public static boolean extractFrame(java.lang.String, java.lang.String);
}
-keep,allowoptimization class eu.twonly.media.NativeGallery {
    public static boolean save(java.lang.String, boolean, java.lang.String, long, boolean, double, double, double);
}
-keep,allowoptimization class eu.twonly.location.NativeLocation {
    public static java.lang.String current(long);
}
