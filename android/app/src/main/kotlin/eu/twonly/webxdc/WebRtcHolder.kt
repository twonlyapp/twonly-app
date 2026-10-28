package eu.twonly.webxdc

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import java.io.ByteArrayInputStream

/**
 * Keeps WebRTC out of reach of every webxdc app by holding all the
 * RTCPeerConnections this process may create.
 *
 * A webxdc app must not reach the network, and WebRTC is the one way out that
 * neither request interception nor CSP covers: ICE sends STUN packets and DNS
 * lookups to any host a page names. Android WebView has no switch to turn it
 * off, and the CSP `webrtc` directive is not enforced. What Chromium does
 * enforce is a limit of [CONNECTION_LIMIT] RTCPeerConnections per renderer
 * process, and all WebViews of an app share one renderer. A hidden WebView that
 * takes every slot leaves `new RTCPeerConnection()` throwing in every other
 * page, including the frames a page creates for itself, which a script that
 * merely deletes the constructor could not cover.
 *
 * The technique is Delta Chat's, which holds the budget the same way for its
 * webxdc apps.
 *
 * Everything here runs on the main thread.
 */
object WebRtcHolder {
    private const val TAG = "WebRtcHolder"

    /**
     * Chromium's per-renderer limit. Should it ever be raised, the check after
     * the fill finds a free slot and the holder reports failure, so apps stop
     * opening rather than opening with WebRTC available.
     */
    private const val CONNECTION_LIMIT = 500

    /** RTCPeerConnection exists only in secure contexts. Never fetched. */
    private const val HOLDER_URL = "https://webrtc-holder.localhost/"

    private const val WAIT_TIMEOUT_MS = 15_000L

    private enum class State { IDLE, FILLING, HOLDING, FAILED }

    private val main = Handler(Looper.getMainLooper())
    private var state = State.IDLE
    private var webView: WebView? = null
    private val waiters = mutableListOf<(Boolean) -> Unit>()

    /**
     * Calls [done] with `true` once every slot is held, or with `false` if that
     * could not be achieved in time. Starts the fill on first use; after that
     * the hold lasts as long as the process.
     */
    fun awaitHolding(context: Context, done: (Boolean) -> Unit) {
        when (state) {
            State.HOLDING -> return done(true)
            State.FAILED -> return done(false)
            State.IDLE -> start(context.applicationContext)
            State.FILLING -> {}
        }

        var called = false
        val once: (Boolean) -> Unit = { holding ->
            if (!called) {
                called = true
                done(holding)
            }
        }
        waiters.add(once)
        main.postDelayed({
            if (!called) Log.w(TAG, "timed out waiting for the WebRTC hold")
            waiters.remove(once)
            once(false)
        }, WAIT_TIMEOUT_MS)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun start(context: Context) {
        state = State.FILLING
        val view = WebView(context)
        view.settings.apply {
            javaScriptEnabled = true
            blockNetworkLoads = true
            allowFileAccess = false
            allowContentAccess = false
            setGeolocationEnabled(false)
        }
        // Only this hidden page gets the callback; no webxdc page can see it.
        view.addJavascriptInterface(Callback(), "__twonlyRtcHolder")
        view.webViewClient = Client()
        webView = view
        view.loadUrl(HOLDER_URL)
    }

    private fun finish(holding: Boolean, reason: String) {
        if (state != State.FILLING) return
        if (holding) {
            state = State.HOLDING
            Log.i(TAG, "holding all $CONNECTION_LIMIT RTCPeerConnection slots")
        } else {
            state = State.FAILED
            Log.e(TAG, "could not hold the RTCPeerConnection slots: $reason")
            webView?.destroy()
            webView = null
        }
        val pending = waiters.toList()
        waiters.clear()
        pending.forEach { it(holding) }
    }

    private class Callback {
        @JavascriptInterface
        fun done(holding: Boolean, reason: String) {
            main.post { finish(holding, reason) }
        }
    }

    private class Client : WebViewClient() {
        override fun shouldInterceptRequest(
            view: WebView,
            request: WebResourceRequest,
        ): WebResourceResponse = if (request.url.toString() == HOLDER_URL) {
            WebResourceResponse(
                "text/html",
                "utf-8",
                ByteArrayInputStream(HOLDER_PAGE.toByteArray()),
            )
        } else {
            WebResourceResponse(
                "text/plain",
                "utf-8",
                403,
                "Forbidden",
                emptyMap(),
                ByteArrayInputStream(ByteArray(0)),
            )
        }

        /**
         * The renderer, and every slot with it, is gone; so is every webxdc
         * page it ran. The next app to open fills the budget again.
         */
        @TargetApi(Build.VERSION_CODES.O)
        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
            Log.w(TAG, "renderer gone (crashed: ${detail.didCrash()})")
            if (webView === view) {
                webView = null
                view.destroy()
                if (state == State.FILLING) {
                    finish(false, "renderer gone while filling")
                }
                state = State.IDLE
            }
            return true
        }
    }

    /**
     * Closing a connection frees most of its memory but not its slot: the slot
     * is released when the object is destroyed, so every connection stays
     * referenced from `held` for as long as the page lives. One certificate is
     * shared, since generating 500 would take seconds.
     */
    private val HOLDER_PAGE = """
        <!doctype html>
        <meta charset="utf-8">
        <script>
        const held = [];
        const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
        (async () => {
          try {
            const certificates = [await RTCPeerConnection.generateCertificate({
              name: "ECDSA",
              namedCurve: "P-256",
            })];
            let retries = 0;
            while (held.length < $CONNECTION_LIMIT) {
              try {
                const connection = new RTCPeerConnection({ certificates });
                connection.close();
                held.push(connection);
                if (held.length % 50 === 0) await pause(0);
              } catch (error) {
                // Slots still taken by closed connections nobody holds any
                // more come back once they are collected.
                if (++retries > 40) throw error;
                new Array(1024 * 1024).fill(0);
                await pause(250);
              }
            }
            try {
              held.push(new RTCPeerConnection({ certificates }));
              __twonlyRtcHolder.done(false, "a slot beyond $CONNECTION_LIMIT is still free");
            } catch (error) {
              __twonlyRtcHolder.done(true, "");
            }
          } catch (error) {
            __twonlyRtcHolder.done(false, String(error));
          }
        })();
        </script>
    """.trimIndent()
}
