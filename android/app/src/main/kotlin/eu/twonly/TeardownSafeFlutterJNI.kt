package eu.twonly

import android.os.Looper
import io.flutter.embedding.engine.FlutterJNI

/** Drops ImageReader frame callbacks delivered after Flutter's engine was detached. */
internal class TeardownSafeFlutterJNI : FlutterJNI() {
    override fun scheduleFrame() {
        // Flutter's ImageReaderSurfaceProducer can outlive the engine during
        // activity destruction. There is no frame to draw once it is detached.
        // Delegate off-thread calls so Flutter still enforces its thread check.
        if (Looper.myLooper() == Looper.getMainLooper() && !isAttached) return
        super.scheduleFrame()
    }
}
