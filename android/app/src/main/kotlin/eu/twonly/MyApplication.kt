package eu.twonly

import eu.twonly.directmedia.DirectMediaPrepare
import io.flutter.app.FlutterApplication
import io.crates.keyring.Keyring

class MyApplication : FlutterApplication() {
    companion object {
        lateinit var instance: MyApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Keyring.initializeNdkContext(this)
        // Registered from the application rather than the activity: a process
        // started by a push or by WorkManager itself must keep the flush alive
        // just as much as one the user opened.
        DirectMediaPrepare.ensurePeriodicFlush()
    }
}
