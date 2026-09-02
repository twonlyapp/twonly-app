package eu.twonly.widget

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Lets the running app redraw its home-screen widgets.
 *
 * Rust rewrites the widget manifest from inside this process, but an AppWidget
 * only redraws when its provider is asked to, so nothing on the home screen
 * changes until this runs. The notification worker covers pushes that arrive
 * while the app is gone; this covers everything the running app changes.
 *
 * Shares its name with the iOS channel of the same purpose, so Dart talks to
 * one channel on both platforms.
 */
object WidgetRuntimeChannel {
    private const val CHANNEL = "eu.twonly/runtime_storage"

    private var channel: MethodChannel? = null

    fun configure(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "reloadWidgets" -> {
                    TwonlyWidgetProvider.refreshAll(context.applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        this.channel = channel
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
