package eu.twonly.widget

import io.flutter.embedding.engine.plugins.FlutterPlugin
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
class WidgetRuntimeChannel : FlutterPlugin {
    companion object {
        private const val CHANNEL = "eu.twonly/runtime_storage"
    }

    private var channel: MethodChannel? = null

    // Refreshes can finish after the activity detaches. Keep the handler alive
    // until its engine goes away, with a separate channel for each engine.
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val channel = MethodChannel(binding.binaryMessenger, CHANNEL)
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
