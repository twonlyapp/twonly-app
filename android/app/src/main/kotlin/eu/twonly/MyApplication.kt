package eu.twonly

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
    }
}
