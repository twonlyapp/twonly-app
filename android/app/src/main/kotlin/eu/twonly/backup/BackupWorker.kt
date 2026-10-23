package eu.twonly.backup

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import eu.twonly.NativeErrorReporting
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/** OS-owned backups run without an activity or Flutter engine. Rust checks
 * consent, recovery state and the daily/weekly due dates on every attempt. */
class BackupWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val runLock = Any()
    private var runId: Long? = null

    override fun doWork(): Result {
        val id = synchronized(runLock) {
            if (isStopped) return Result.retry()
            NativeBackupBridge.create().also { runId = it }
        }
        return try {
            val response = JSONObject(NativeBackupBridge.run(id, applicationContext.filesDir.absolutePath))
            if (response.optBoolean("ok") && !response.optBoolean("pending_uploads")) {
                Result.success()
            } else {
                Result.retry()
            }
        } catch (error: Throwable) {
            NativeErrorReporting.failure(applicationContext, "backup", error)
            Result.retry()
        } finally {
            synchronized(runLock) {
                NativeBackupBridge.dispose(id)
                runId = null
            }
        }
    }

    override fun onStopped() {
        synchronized(runLock) { runId?.let { NativeBackupBridge.cancel(it) } }
        super.onStopped()
    }

    companion object {
        const val UNIQUE_WORK_NAME = "twonly-backup"

        fun ensureScheduled(context: Context) {
            val request = PeriodicWorkRequestBuilder<BackupWorker>(12, TimeUnit.HOURS)
                // Registering on process launch only reserves work. It never
                // starts a backup as part of opening the app.
                .setInitialDelay(1, TimeUnit.HOURS)
                .setConstraints(Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .setRequiresBatteryNotLow(true)
                    .build())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 15, TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request,
            )
        }
    }
}

internal object NativeBackupBridge {
    init { System.loadLibrary("rust_lib_twonly") }
    @JvmStatic external fun create(): Long
    @JvmStatic external fun run(id: Long, directory: String): String
    @JvmStatic external fun cancel(id: Long)
    @JvmStatic external fun dispose(id: Long)
}
