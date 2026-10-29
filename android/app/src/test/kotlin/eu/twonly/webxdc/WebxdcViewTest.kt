package eu.twonly.webxdc

import android.app.Activity
import android.app.Application
import android.os.Looper
import android.webkit.WebView
import android.widget.FrameLayout
import java.time.Duration
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
class WebxdcViewTest {
    @Test
    fun detachedWebViewIsDestroyedWithoutBeingAttachedAgain() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val container = FrameLayout(activity)
        activity.setContentView(container)
        val view = WebxdcView(activity, "game", "origin")
        val webView = view.getView() as WebView
        container.addView(webView)

        // PlatformViewsController removes the view before calling dispose().
        container.removeView(webView)
        view.dispose()
        shadowOf(Looper.getMainLooper()).idle()

        assertFalse(webView.isAttachedToWindow)
        assertTrue(shadowOf(webView).wasDestroyCalled())
    }

    @Test
    fun cancelledCloseResumesTheCurrentWebView() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = WebxdcView(activity, "game", "origin")
        val webView = view.getView() as WebView
        activity.setContentView(webView)

        WebxdcView.setPaused("game", true)
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(shadowOf(webView).wasOnPauseCalled())

        WebxdcView.setPaused("game", false)
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(shadowOf(webView).wasOnResumeCalled())
        view.dispose()
        shadowOf(Looper.getMainLooper()).idle()
    }

    @Test
    fun appIsNeverLoadedWhileWebRtcIsNotShownToBeBlocked() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = WebxdcView(activity, "game", "origin")
        val webView = view.getView() as WebView

        // Robolectric runs no JavaScript, so the hold never confirms. Past the
        // fill's timeout, nothing of the app may have been requested.
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(70))

        assertNull(shadowOf(webView).lastLoadedUrl)
        view.dispose()
        shadowOf(Looper.getMainLooper()).idle()
    }

    @Test
    fun aSlowFillIsWaitedForAndATimedOutOneIsRetried() {
        WebRtcHolder.resetForTest()
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val answers = mutableListOf<Boolean>()

        // A cold renderer on a slow phone: an app opened now must still load
        // once the fill is done, not be refused while it runs.
        WebRtcHolder.awaitHolding(activity) { answers.add(it) }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(30))
        assertTrue(answers.isEmpty())

        // A page that never answers is given up on, but not for good.
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(31))
        assertEquals(listOf(false), answers)
        WebRtcHolder.awaitHolding(activity) { answers.add(it) }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1))
        assertEquals(listOf(false), answers)

        WebRtcHolder.resetForTest()
    }

    @Test
    fun queuedPauseDoesNotActOnAReplacedWebView() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val oldView = WebxdcView(activity, "old-game", "old-origin")
        val oldWebView = oldView.getView() as WebView
        activity.setContentView(oldWebView)
        WebxdcView.setPaused("old-game", true)

        val newView = WebxdcView(activity, "new-game", "new-origin")
        val newWebView = newView.getView() as WebView
        activity.setContentView(newWebView)
        shadowOf(Looper.getMainLooper()).idle()

        assertFalse(shadowOf(oldWebView).wasOnPauseCalled())
        assertFalse(shadowOf(newWebView).wasOnPauseCalled())
        oldView.dispose()
        newView.dispose()
        shadowOf(Looper.getMainLooper()).idle()
    }
}
