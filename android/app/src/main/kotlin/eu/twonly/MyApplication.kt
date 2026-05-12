package eu.twonly

import io.flutter.app.FlutterApplication
import dev.fluttercommunity.workmanager.WorkmanagerDebug
import dev.fluttercommunity.workmanager.LoggingDebugHandler
import io.crates.keyring.Keyring

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        Keyring.initializeNdkContext(this)
        // This enables the internal plugin logging to Logcat
        WorkmanagerDebug.setCurrent(LoggingDebugHandler())
    }
}