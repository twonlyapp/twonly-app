package eu.twonly.webxdc

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.webkit.WebStorage
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The Dart side of the webxdc runtime.
 *
 * The webview is a platform view embedded in an ordinary Flutter route, so the
 * app runs inside twonly rather than on a screen of its own. Everything the
 * page asks for is answered by Dart, which asks Rust: nothing here reads a
 * bundle, decides a limit, or trusts a value the page produced.
 *
 * Shares its channel name with the iOS implementation, so Dart talks to one
 * channel on both platforms.
 */
object WebxdcChannel {
    private const val CHANNEL = "eu.twonly/webxdc"

    private var channel: MethodChannel? = null
    private val main = Handler(Looper.getMainLooper())

    fun configure(flutterEngine: FlutterEngine, activity: Activity) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result -> handle(call, result) }
        this.channel = channel

        flutterEngine.platformViewsController.registry.registerViewFactory(
            WebxdcViewFactory.VIEW_TYPE,
            WebxdcViewFactory(activity),
        )
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "deliver" -> {
                val instanceId = call.argument<String>("instanceId")
                val message = call.argument<String>("message")
                if (instanceId != null && message != null) {
                    WebxdcView.deliver(instanceId, message)
                }
                result.success(null)
            }

            "setPaused" -> {
                // The screen showing the app is animating in or out, and a page
                // that keeps drawing competes with the animation for the very
                // frames it needs.
                val instanceId = call.argument<String>("instanceId")
                val paused = call.argument<Boolean>("paused")
                if (instanceId != null && paused != null) {
                    WebxdcView.setPaused(instanceId, paused)
                }
                result.success(null)
            }

            "clearOrigin" -> {
                // The update log is only half an app's state; the rest is
                // whatever it put in localStorage or IndexedDB, which only the
                // WebView can delete.
                val origin = call.argument<String>("origin")
                if (origin != null) {
                    WebStorage.getInstance().deleteOrigin(WebxdcView.originUrl(origin))
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Asks Dart for one file out of the bundle.
     *
     * Called on the WebView's background thread, which needs an answer before
     * it returns, so the caller blocks while the channel call runs on the main
     * thread. Different threads, so the wait cannot deadlock; the timeout
     * covers an engine that has gone away.
     */
    fun serve(instanceId: String, path: String): ServedResponse? {
        var response: ServedResponse? = null
        awaitReply("serve", mapOf("instanceId" to instanceId, "path" to path), 10) { value ->
            @Suppress("UNCHECKED_CAST")
            val map = value as? Map<String, Any?> ?: return@awaitReply
            response = ServedResponse(
                status = (map["status"] as? Number)?.toInt() ?: 500,
                mime = map["mime"] as? String ?: "application/octet-stream",
                headerNames = (map["headerNames"] as? List<*>)?.map { it.toString() } ?: emptyList(),
                headerValues = (map["headerValues"] as? List<*>)?.map { it.toString() } ?: emptyList(),
                body = map["body"] as? ByteArray ?: ByteArray(0),
            )
        }
        return response
    }

    /** Forwards one `webxdc.js` call and returns the JSON reply for the page. */
    fun bridge(instanceId: String, message: String): String {
        var reply = "{\"error\":\"unavailable\"}"
        awaitReply(
            "bridge",
            mapOf("instanceId" to instanceId, "message" to message),
            30,
        ) { value ->
            reply = value as? String ?: reply
        }
        return reply
    }

    /**
     * Hands a link the user tapped to Dart, which shows the whole URL and asks
     * before anything opens. Fire and forget: the page is not told.
     */
    fun openLink(url: String) {
        main.post { channel?.invokeMethod("openLink", mapOf("url" to url)) }
    }

    private fun awaitReply(
        method: String,
        arguments: Map<String, Any?>,
        timeoutSeconds: Long,
        onSuccess: (Any?) -> Unit,
    ) {
        val channel = this.channel ?: return
        val latch = java.util.concurrent.CountDownLatch(1)
        main.post {
            channel.invokeMethod(
                method,
                arguments,
                object : MethodChannel.Result {
                    override fun success(value: Any?) {
                        onSuccess(value)
                        latch.countDown()
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        latch.countDown()
                    }

                    override fun notImplemented() {
                        latch.countDown()
                    }
                },
            )
        }
        latch.await(timeoutSeconds, java.util.concurrent.TimeUnit.SECONDS)
    }

    data class ServedResponse(
        val status: Int,
        val mime: String,
        val headerNames: List<String>,
        val headerValues: List<String>,
        val body: ByteArray,
    )
}
