package eu.twonly.webxdc

import android.app.Activity
import android.app.Application
import android.os.Looper
import android.webkit.WebView
import android.widget.FrameLayout
import org.junit.Assert.assertFalse
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
