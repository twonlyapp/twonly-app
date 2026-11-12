package eu.twonly.notifications

import android.app.ActivityManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class PeriodicPollChannel : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "eu.twonly/periodic_poll").also { channel ->
            channel.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getStatus" -> result.success(status(context))
                        "setEnabled" -> {
                            val enabled = call.arguments as? Boolean
                            if (enabled == null) {
                                result.error("invalid_argument", "Expected a boolean", null)
                            } else if (enabled && PlayServicesChannel.isAvailable(context)) {
                                result.error("fcm_available", "FCM is available on this device", null)
                            } else {
                                val pending = PeriodicPollScheduler.setEnabled(context, enabled).result
                                pending.addListener({
                                    try {
                                        pending.get()
                                        result.success(status(context))
                                    } catch (error: Exception) {
                                        result.error("poll_unavailable", error.message, null)
                                    }
                                }, ContextCompat.getMainExecutor(context))
                            }
                        }
                        "openBatterySettings" -> {
                            openBatterySettings(context)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("poll_unavailable", error.message, null)
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    private fun status(context: Context): Map<String, Any> = mapOf(
        "hasPlayServices" to PlayServicesChannel.isAvailable(context),
        "enabled" to PeriodicPollScheduler.isEnabled(context),
        "intervalMinutes" to PeriodicPollScheduler.INTERVAL_MINUTES,
        "ignoringBatteryOptimizations" to context.getSystemService(PowerManager::class.java)
            .isIgnoringBatteryOptimizations(context.packageName),
        "backgroundRestricted" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            context.getSystemService(ActivityManager::class.java).isBackgroundRestricted),
    )

    private fun openBatterySettings(context: Context) {
        try {
            // Opens the system list; never requests the battery exemption permission.
            context.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: ActivityNotFoundException) {
            context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }
}
