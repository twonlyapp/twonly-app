package eu.twonly

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterJNI
import java.util.concurrent.atomic.AtomicReference
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadow.api.Shadow

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class, shadows = [ShadowFrameJNI::class])
class TeardownSafeFlutterJNITest {
    @Before
    fun resetInjector() = FlutterInjector.reset()

    @After
    fun restoreInjector() = FlutterInjector.reset()

    @Test
    fun queuedFrameAfterDetachmentIsDroppedAndReattachmentStillDraws() {
        val jni = TeardownSafeFlutterJNI()
        val native = Shadow.extract<ShadowFrameJNI>(jni)
        jni.attachToNative()
        jni.scheduleFrame()
        assertEquals(1, native.frames)

        Handler(Looper.getMainLooper()).post { jni.scheduleFrame() }
        jni.detachFromNativeAndReleaseResources()
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(1, native.frames)

        jni.attachToNative()
        jni.scheduleFrame()
        assertEquals(2, native.frames)
        jni.detachFromNativeAndReleaseResources()
    }

    @Test
    fun otherNativeCallsStillRejectADetachedEngine() {
        assertThrows(RuntimeException::class.java) {
            TeardownSafeFlutterJNI().markTextureFrameAvailable(1L)
        }
    }

    @Test
    fun offThreadFrameRequestsStillFail() {
        val failure = AtomicReference<Throwable>()
        Thread {
            try {
                TeardownSafeFlutterJNI().scheduleFrame()
            } catch (error: Throwable) {
                failure.set(error)
            }
        }.apply { start(); join() }
        assertNotNull(failure.get())
        assertTrue(failure.get().message.orEmpty().contains("main thread"))
    }

    @Test
    fun applicationInstallsTheGuardBeforeOnCreate() {
        // attachBaseContext runs before providers can initialize Flutter.
        MyApplication::class.java.getDeclaredMethod("attachBaseContext", Context::class.java).apply {
            isAccessible = true
        }.invoke(MyApplication(), RuntimeEnvironment.getApplication())
        assertTrue(
            FlutterInjector.instance().flutterJNIFactory.provideFlutterJNI() is TeardownSafeFlutterJNI,
        )
    }
}

// Keep Flutter's real attachment state and Java validation. Replace only JNI
// entry points, which cannot load an Android engine in a host-side JVM test.
@Implements(FlutterJNI::class)
class ShadowFrameJNI {
    var frames = 0

    @Implementation
    protected fun nativeAttach(jni: FlutterJNI): Long = 1L

    @Implementation
    protected fun nativeDestroy(id: Long) {}

    @Implementation
    protected fun nativeScheduleFrame(id: Long) { frames++ }
}
