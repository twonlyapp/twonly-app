package eu.twonly

import io.flutter.embedding.android.FlutterFragmentActivity
import android.view.KeyEvent
import dev.darttools.flutter_android_volume_keydown.FlutterAndroidVolumeKeydownPlugin.eventSink
import android.view.KeyEvent.KEYCODE_VOLUME_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_UP
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

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

        MediaStoreChannel.configure(flutterEngine, applicationContext)
        VideoCompressionChannel.configure(flutterEngine, applicationContext)
    }
}
