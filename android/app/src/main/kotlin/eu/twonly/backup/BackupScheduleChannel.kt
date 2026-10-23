package eu.twonly.backup

import android.app.ActivityManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.work.WorkInfo
import androidx.work.WorkManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/** Read the actual WorkManager reservation, including retry backoff. */
class BackupScheduleChannel : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "eu.twonly/backup_schedule").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "getSchedule") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val pending = WorkManager.getInstance(context)
                        .getWorkInfosForUniqueWork(BackupWorker.UNIQUE_WORK_NAME)
                    pending.addListener({
                        try {
                            val work = pending.get().filter { !it.state.isFinished }
                            val running = work.any { it.state == WorkInfo.State.RUNNING }
                            val next = work.filter { it.state == WorkInfo.State.ENQUEUED }
                                .map { it.nextScheduleTimeMillis }
                                .filter { it > 0 && it != Long.MAX_VALUE }
                                .minOrNull()
                            result.success(mapOf(
                                "executionAllowed" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.P ||
                                    !context.getSystemService(ActivityManager::class.java).isBackgroundRestricted),
                                "state" to when {
                                    running -> "running"
                                    work.isEmpty() -> "notScheduled"
                                    else -> "scheduled"
                                },
                                "earliestStartMillis" to next,
                            ))
                        } catch (error: Exception) {
                            result.error("schedule_unavailable", error.message, null)
                        }
                    }, ContextCompat.getMainExecutor(context))
                } catch (error: Exception) {
                    result.error("schedule_unavailable", error.message, null)
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }
}
