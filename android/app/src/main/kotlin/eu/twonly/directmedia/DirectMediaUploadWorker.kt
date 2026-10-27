package eu.twonly.directmedia

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.ForegroundInfo
import androidx.work.Data
import androidx.work.Worker
import androidx.work.WorkerParameters
import eu.twonly.R
import eu.twonly.NativeErrorReporting
import java.io.File
import java.util.concurrent.TimeUnit
import org.json.JSONObject

/** Transport-only worker: request construction, protobufs, encryption and
 * policy decisions have already been completed and persisted by Rust. */
class DirectMediaUploadWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    private val transfer = DirectMediaHttpTransfer()
    private var lastActivity = -10_000L

    override fun onStopped() {
        transfer.cancel()
        super.onStopped()
    }

    override fun getForegroundInfo(): ForegroundInfo =
        foregroundInfo(inputData.getString(ATTACHMENT_ID).orEmpty())

    override fun doWork(): Result {
        NativeErrorReporting.breadcrumb(applicationContext, "media_upload_started")
        val attachmentId = inputData.getString(ATTACHMENT_ID) ?: return Result.failure()
        val role = inputData.getString(ROLE) ?: return Result.failure()
        val expiresAt = inputData.getLong(EXPIRES_AT, 0)
        if (expiresAt <= System.currentTimeMillis() / 1_000) return Result.failure()
        val started = SystemClock.elapsedRealtime()
        val queuedMs = (System.currentTimeMillis() -
            inputData.getLong(QUEUED_AT_MS, System.currentTimeMillis())).coerceAtLeast(0)
        var httpMs = 0L
        var status = 0
        return try {
            recordActivity()
            // Extend the execution budget for long uploads when permitted.
            // Background retries must also be able to run without a service.
            setForegroundWhenAllowed(foregroundInfo(attachmentId))
            if (isStopped) return Result.retry()
            val path = inputData.getString(DESCRIPTOR_PATH) ?: return Result.failure()
            val descriptor = JSONObject(File(path).readText(Charsets.UTF_8))
            val request = descriptor.getJSONObject(role)
            val httpStarted = SystemClock.elapsedRealtime()
            try {
                status = transfer.upload(request, ::recordActivity)
            } finally {
                httpMs = SystemClock.elapsedRealtime() - httpStarted
            }
            Log.i(TAG, "Transfer $attachmentId/$role attempt=$runAttemptCount HTTP=$status")
            if (status in 200..299) {
                // Completion owns its own durable retry, so a failed completion
                // request never forces the already accepted object to upload again.
                if (role == "media" && descriptor.has("complete")) {
                    DirectMediaTransfer.enqueueCompletion(
                        applicationContext, attachmentId, File(path), expiresAt,
                    ).result.get(10, TimeUnit.SECONDS)
                }
                Result.success()
            } else if (retryable(status) && expiresAt > System.currentTimeMillis() / 1_000) {
                Result.retry()
            } else {
                Result.failure()
            }
        } catch (error: Exception) {
            // Connectivity errors and stopped workers are ordinary retries.
            if (!isStopped && error !is java.io.IOException) {
                NativeErrorReporting.failure(applicationContext, "media_upload", error)
            }
            Log.w(TAG, "Transfer $attachmentId/$role attempt=$runAttemptCount failed", error)
            if (expiresAt > System.currentTimeMillis() / 1_000) Result.retry() else Result.failure()
        } finally {
            // Enqueue completion before waking Rust: a Ready status may cause
            // reconciliation to remove the immutable request files.
            NativeMediaTransferBridge.finished(
                applicationContext.filesDir.absolutePath, attachmentId, role,
                queuedMs, SystemClock.elapsedRealtime() - started, httpMs, status, runAttemptCount,
            )
        }
    }

    private fun recordActivity() {
        val now = SystemClock.elapsedRealtime()
        if (now - lastActivity >= 10_000) {
            lastActivity = now
            setProgressAsync(Data.Builder()
                .putLong(LAST_ACTIVITY_MS, System.currentTimeMillis())
                .build())
        }
    }

    private fun retryable(status: Int): Boolean =
        status == 0 || status == 408 || status == 429 || status >= 500

    private fun foregroundInfo(attachmentId: String): ForegroundInfo {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Media uploads", NotificationManager.IMPORTANCE_LOW),
            )
        }
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Uploading encrypted media")
            .setContentText("twonly will finish this upload in the background")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
        val id = attachmentId.hashCode() and 0x7fffffff
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(id, notification)
        }
    }

    companion object {
        const val ATTACHMENT_ID = "attachment_id"
        const val ROLE = "role"
        const val DESCRIPTOR_PATH = "descriptor_path"
        const val EXPIRES_AT = "expires_at"
        const val LAST_ACTIVITY_MS = "last_activity_ms"
        const val QUEUED_AT_MS = "queued_at_ms"
        private const val TAG = "TwonlyMediaTransfer"
        private const val CHANNEL_ID = "twonly_direct_media_upload"
    }
}
