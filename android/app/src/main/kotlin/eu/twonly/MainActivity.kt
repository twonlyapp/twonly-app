package eu.twonly

import io.flutter.embedding.android.FlutterFragmentActivity
import android.view.KeyEvent
import dev.darttools.flutter_android_volume_keydown.FlutterAndroidVolumeKeydownPlugin.eventSink
import android.view.KeyEvent.KEYCODE_VOLUME_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_UP
import io.flutter.embedding.engine.FlutterEngine
import android.content.Context
import io.crates.keyring.Keyring
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import android.os.Bundle

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (keyCode == KEYCODE_VOLUME_DOWN && eventSink != null) {
            eventSink!!.success(true)
            return true
        }
        if (keyCode == KEYCODE_VOLUME_UP && eventSink != null) {
            eventSink!!.success(false)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Keyring.initializeNdkContext(applicationContext)

        VideoCompressionChannel.configure(flutterEngine, applicationContext)
    }
}
