package eu.twonly

import android.content.Context
import eu.twonly.directmedia.DirectMediaPrepare
import io.flutter.FlutterInjector
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterJNI
import io.crates.keyring.Keyring

class MyApplication : FlutterApplication() {
    companion object {
        lateinit var instance: MyApplication
            private set
    }

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Install before content providers or background services can create
        // an engine and access FlutterInjector for the first time.
        FlutterInjector.setInstance(
            FlutterInjector.Builder().setFlutterJNIFactory(object : FlutterJNI.Factory() {
                override fun provideFlutterJNI(): FlutterJNI = TeardownSafeFlutterJNI()
            }).build(),
        )
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        NativeErrorReporting.startIfAllowed(this)
        Keyring.initializeNdkContext(this)
        // Registered from the application rather than the activity: a process
        // started by a push or by WorkManager itself must keep the flush alive
        // just as much as one the user opened.
        DirectMediaPrepare.ensurePeriodicFlush()
        eu.twonly.backup.BackupWorker.ensureScheduled(this)
    }
}
