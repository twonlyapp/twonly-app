package eu.twonly

import io.flutter.app.FlutterApplication
import dev.fluttercommunity.workmanager.WorkmanagerDebug
import dev.fluttercommunity.workmanager.LoggingDebugHandler

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        // This enables the internal plugin logging to Logcat
        WorkmanagerDebug.setCurrent(LoggingDebugHandler())
    }
}