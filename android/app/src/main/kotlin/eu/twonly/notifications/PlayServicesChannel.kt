package eu.twonly.notifications

import android.content.Context
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/**
 * Tells Dart whether FCM can work on this device. Without Google Play Services
 * (or microG, which reports itself as available) every token read fails, so
 * registering and health-checking FCM there only produces errors.
 */
class PlayServicesChannel : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "eu.twonly/play_services").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(isAvailable(context))
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    companion object {
        /**
         * Only a missing or disabled installation counts as unavailable. An
         * outdated Play Services still delivers FCM after it updates itself, so
         * treating it as missing would drop the registration for no reason.
         */
        @JvmStatic
        fun isAvailable(context: Context): Boolean = try {
            when (GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context)) {
                ConnectionResult.SERVICE_MISSING,
                ConnectionResult.SERVICE_DISABLED,
                ConnectionResult.SERVICE_INVALID -> false
                else -> true
            }
        } catch (_: Throwable) {
            // Fall back to the previous behaviour: try FCM.
            true
        }
    }
}
