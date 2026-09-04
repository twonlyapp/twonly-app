package eu.twonly.webxdc

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.ByteArrayInputStream
import org.json.JSONArray
import org.json.JSONObject

class WebxdcViewFactory(private val activity: Activity) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        const val VIEW_TYPE = "eu.twonly/webxdc_webview"
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?> ?: emptyMap()
        return WebxdcView(
            activity,
            instanceId = params["instanceId"] as? String ?: "",
            origin = params["origin"] as? String ?: "",
        )
    }
}

/**
 * The one WebView twonly ever creates, embedded in a Flutter route.
 *
 * A webxdc app is third-party code, so this view is built around denying it
 * things:
 *
 *  - every request is answered from the bundle or refused; nothing reaches the
 *    network, because [WebViewClient.shouldInterceptRequest] never returns null
 *    for a request it did not serve itself,
 *  - the origin is unique per instance, so the browser's own origin model keeps
 *    one app's storage out of reach of every other app,
 *  - every permission the page can ask for is denied without a prompt,
 *  - navigation away from the app's own origin is cancelled, and a link the
 *    user taps goes to Dart for confirmation before it reaches a browser.
 *
 * The bundle is read in Rust and arrives here as bytes with the headers already
 * attached; nothing here parses a zip or decides a policy.
 */
class WebxdcView(
    private val activity: Activity,
    private val instanceId: String,
    private val origin: String,
) : PlatformView {

    companion object {
        private const val IMPORT_REQUEST = 4711

        /** Refuses to read more than this in one import, however many files. */
        private const val MAX_IMPORT_BYTES = 32 * 1024 * 1024

        private var current: WebxdcView? = null

        /**
         * `https` rather than a custom scheme, so the page is a secure context
         * and `crypto.subtle`, IndexedDB and workers behave as apps expect.
         * `.localhost` can never resolve, and nothing is ever fetched anyway.
         */
        fun originUrl(origin: String): String = "https://$origin.webxdc.localhost"

        fun deliver(instanceId: String, message: String) {
            val view = current ?: return
            if (view.instanceId != instanceId) return
            view.webView.post { view.deliverToPage(message) }
        }

        /** Stops or restarts the app while its screen is animating. */
        fun setPaused(instanceId: String, paused: Boolean) {
            val view = current ?: return
            if (view.instanceId != instanceId) return
            view.webView.post { view.setPaused(paused) }
        }

        /**
         * Routes a picker result back to the view that opened it. Called by the
         * activity, which is the only thing that receives one.
         */
        fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
            if (requestCode != IMPORT_REQUEST) return false
            current?.finishImport(resultCode, data)
            return true
        }
    }

    private val webView: WebView
    /** The `importFiles` call waiting on the picker, if one is open. */
    private var importCallId: Int? = null
    private var importExtensions: List<String> = emptyList()

    init {
        current = this
        webView = WebView(activity)

        @SuppressLint("SetJavaScriptEnabled")
        webView.settings.apply {
            javaScriptEnabled = true
            // Apps keep their state here, and the unique origin is what keeps
            // it to themselves.
            domStorageEnabled = true

            // No path a page could use to read the device's files.
            allowFileAccess = false
            allowContentAccess = false
            @Suppress("DEPRECATION")
            allowFileAccessFromFileURLs = false
            @Suppress("DEPRECATION")
            allowUniversalAccessFromFileURLs = false

            setGeolocationEnabled(false)
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
            mediaPlaybackRequiresUserGesture = true
            cacheMode = WebSettings.LOAD_NO_CACHE
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            builtInZoomControls = false
            displayZoomControls = false
        }

        // A remote debugger attached to a page running somebody else's code is
        // not something a release build should offer.
        WebView.setWebContentsDebuggingEnabled(
            (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0,
        )

        webView.addJavascriptInterface(Bridge(), "__twonlyWebxdcBridge")
        webView.webViewClient = Client()
        webView.webChromeClient = ChromeClient()

        // Nothing is injected into the document. `webxdc.js` is served with its
        // values already in it, and `__twonlyWebxdcBridge` exists before any
        // page script runs, so there is no window in which app code could
        // observe or race the setup.
        webView.loadUrl("${originUrl(origin)}/index.html")
    }

    override fun getView(): View = webView

    override fun dispose() {
        if (current === this) {
            current = null
        }
        // Stopped now, destroyed on the next turn of the main loop. A
        // synchronous destroy spends its milliseconds on the frame that removes
        // the view, which is the last frame of the closing animation and the
        // one place the cost is visible.
        webView.onPause()
        webView.post {
            // Timers are a process-wide setting, so they are handed back before
            // this view goes: the next app opened must not start frozen.
            webView.resumeTimers()
            webView.destroy()
        }
    }

    /**
     * Rendering and timers, stopped while the route is animating away.
     *
     * A game redraws every frame it is given, and those are exactly the frames
     * the transition needs. Nothing is lost by this: the page keeps its state,
     * it is the webview's own pause rather than a reload.
     */
    private fun setPaused(paused: Boolean) {
        if (paused) {
            webView.onPause()
            webView.pauseTimers()
        } else {
            webView.onResume()
            webView.resumeTimers()
        }
    }

    private fun quote(value: String): String = JSONObject.quote(value)

    private fun deliverToPage(message: String) {
        webView.evaluateJavascript(
            "window.__twonlyWebxdcDeliver(JSON.parse(${quote(message)}))",
            null,
        )
    }

    /** The single entry point from the page into twonly. */
    private inner class Bridge {
        @JavascriptInterface
        fun call(message: String): String {
            // `importFiles` is answered here rather than in Dart: the picker
            // is an activity result, and the bytes the user chose have no
            // reason to travel any further than the page that asked for them.
            val parsed = try {
                JSONObject(message)
            } catch (error: Exception) {
                null
            }
            if (parsed != null && parsed.optString("method") == "importFiles") {
                webView.post { startImport(parsed) }
                // Empty means "answered later"; the page keeps waiting for a
                // delivery rather than treating this as the reply.
                return ""
            }

            // The instance is the one this view was created for. A page cannot
            // name a different one, whatever it puts in the message.
            return WebxdcChannel.bridge(instanceId, message)
        }
    }

    private fun startImport(call: JSONObject) {
        if (importCallId != null) {
            // One picker at a time; a second request while one is open is
            // answered empty rather than queued.
            deliverImportResult(call.optInt("id"), JSONArray())
            return
        }
        importCallId = call.optInt("id")

        val params = call.optJSONObject("params") ?: JSONObject()
        importExtensions = params.optJSONArray("extensions").toStringList()
            .map { it.lowercase().removePrefix(".") }
        val mimeTypes = params.optJSONArray("mimeTypes").toStringList()

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            if (mimeTypes.isNotEmpty()) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            }
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, params.optBoolean("multiple", false))
        }
        try {
            activity.startActivityForResult(intent, IMPORT_REQUEST)
        } catch (error: Exception) {
            deliverImportResult(importCallId ?: 0, JSONArray())
            importCallId = null
        }
    }

    private fun finishImport(resultCode: Int, data: Intent?) {
        val callId = importCallId ?: return
        importCallId = null

        val files = JSONArray()
        if (resultCode == Activity.RESULT_OK && data != null) {
            var budget = MAX_IMPORT_BYTES
            for (uri in data.selectedUris()) {
                val entry = readImportedFile(uri, budget) ?: continue
                budget -= entry.second
                files.put(entry.first)
                if (budget <= 0) break
            }
        }
        // A cancelled picker resolves with nothing rather than rejecting: the
        // app asked to import, the user declined, and that is not an error.
        deliverImportResult(callId, files)
    }

    private fun Intent.selectedUris(): List<Uri> {
        val clip = clipData
        if (clip != null) {
            return (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
        }
        return listOfNotNull(data)
    }

    /** Returns the JSON for one file and how many bytes it cost. */
    private fun readImportedFile(uri: Uri, budget: Int): Pair<JSONObject, Int>? {
        val resolver = activity.contentResolver
        val name = displayName(uri) ?: return null
        if (importExtensions.isNotEmpty() &&
            !importExtensions.contains(name.substringAfterLast('.', "").lowercase())
        ) {
            return null
        }
        // Grown as the file is read rather than allocated at the ceiling: the
        // budget is what a file may not exceed, not what every file costs.
        val bytes = try {
            resolver.openInputStream(uri)?.use { stream ->
                val collected = java.io.ByteArrayOutputStream()
                val chunk = ByteArray(64 * 1024)
                while (true) {
                    val read = stream.read(chunk)
                    if (read <= 0) break
                    if (collected.size() + read > budget) return null
                    collected.write(chunk, 0, read)
                }
                collected.toByteArray()
            }
        } catch (error: Exception) {
            null
        } ?: return null

        val entry = JSONObject()
            .put("name", name)
            .put("type", resolver.getType(uri) ?: "")
            .put("base64", android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP))
        return entry to bytes.size
    }

    private fun displayName(uri: Uri): String? {
        activity.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                // Only the file's own name; a document provider is free to put
                // anything in here, and it must not read as a path.
                return cursor.getString(index)?.substringAfterLast('/')
            }
        }
        return uri.lastPathSegment?.substringAfterLast('/')
    }

    private fun deliverImportResult(callId: Int, files: JSONArray) {
        deliverToPage(JSONObject().put("id", callId).put("result", files).toString())
    }

    private fun JSONArray?.toStringList(): List<String> {
        if (this == null) return emptyList()
        return (0 until length()).mapNotNull { optString(it).takeIf { value -> value.isNotEmpty() } }
    }

    private inner class Client : WebViewClient() {
        override fun shouldInterceptRequest(
            view: WebView,
            request: WebResourceRequest,
        ): WebResourceResponse? {
            val url = request.url
            if (!isOwnOrigin(url)) {
                // Every other host, including the ones a CSS `url()` or an
                // injected script might reach for. Refused here rather than by
                // CSP, which has too much history of gaps to be the only
                // control.
                return refused()
            }

            val served = WebxdcChannel.serve(instanceId, url.encodedPath ?: "/")
                ?: return refused()

            val headers = LinkedHashMap<String, String>()
            served.headerNames.forEachIndexed { index, name ->
                served.headerValues.getOrNull(index)?.let { headers[name] = it }
            }

            return WebResourceResponse(
                served.mime.substringBefore(';'),
                "utf-8",
                served.status,
                if (served.status == 200) "OK" else "Error",
                headers,
                ByteArrayInputStream(served.body),
            )
        }

        override fun shouldOverrideUrlLoading(
            view: WebView,
            request: WebResourceRequest,
        ): Boolean {
            if (isOwnOrigin(request.url)) {
                return false
            }
            // A link out of the app. Never followed here: Dart shows the whole
            // URL and says it leaves twonly before anything opens.
            if (request.hasGesture()) {
                WebxdcChannel.openLink(request.url.toString())
            }
            return true
        }

        private fun refused(): WebResourceResponse = WebResourceResponse(
            "text/plain",
            "utf-8",
            403,
            "Forbidden",
            emptyMap(),
            ByteArrayInputStream(ByteArray(0)),
        )

        private fun isOwnOrigin(url: Uri): Boolean =
            url.scheme == "https" && url.host == "$origin.webxdc.localhost"
    }

    private inner class ChromeClient : WebChromeClient() {
        /** Camera, microphone, midi, protected media: all of it, denied. */
        override fun onPermissionRequest(request: PermissionRequest) = request.deny()

        override fun onGeolocationPermissionsShowPrompt(
            origin: String,
            callback: android.webkit.GeolocationPermissions.Callback,
        ) = callback.invoke(origin, false, false)

        override fun onCreateWindow(
            view: WebView,
            isDialog: Boolean,
            isUserGesture: Boolean,
            resultMsg: android.os.Message,
        ): Boolean = false

        /** No file chooser: files cross the boundary only through importFiles. */
        override fun onShowFileChooser(
            webView: WebView,
            filePathCallback: android.webkit.ValueCallback<Array<Uri>>,
            fileChooserParams: FileChooserParams,
        ): Boolean {
            filePathCallback.onReceiveValue(null)
            return true
        }
    }
}
