package eu.twonly

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class ErrorReportingChannel : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "eu.twonly/error_reporting").apply {
            setMethodCallHandler { call, result ->
                if (call.method != "setEnabled") {
                    result.notImplemented()
                } else {
                    val enabled = call.arguments as? Boolean
                    if (enabled == null) {
                        result.error("invalid_consent", "Expected a boolean", null)
                    } else {
                        try {
                            NativeErrorReporting.setEnabled(binding.applicationContext, enabled)
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("consent_failed", "Could not save error reporting preference", null)
                        }
                    }
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
