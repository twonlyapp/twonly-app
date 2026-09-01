package eu.twonly.directmedia

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.ForegroundInfo
import androidx.work.Worker
import androidx.work.WorkerParameters
import eu.twonly.R
import org.json.JSONObject

/**
 * Runs one Rust maintenance job.
 *
 * With no media id this is the flush: resume interrupted preparations, settle
 * transfers the OS finished while nothing was listening, and drain the message
 * outbox. With one, it prepares that single send.
 *
 * The Rust call is synchronous and owns its own runtime, so this worker only
 * has to hold a foreground service around it — without one, Android stops long
 * background work, which is the exact failure this whole path exists to fix.
 */
class MediaPrepareWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        val mediaId = inputData.getString(MEDIA_ID)
        return try {
            if (mediaId != null) {
                // Only a user-visible send justifies a foreground service; the
                // periodic flush runs as ordinary background work.
                setForegroundAsync(foregroundInfo()).get()
            }
            val directory = applicationContext.filesDir.absolutePath
            val response = JSONObject(
                NativeMediaPrepareBridge.run(directory, directory, mediaId),
            )
            if (response.optBoolean("ok", false)) {
                // Rust performed a synchronous status pass before returning.
                // Keep this WorkManager job as the durable owner until the
                // server says the attachment is terminal; a Tokio task created
                // inside NativeMediaPrepareBridge would die with that call.
                if (response.optBoolean("pending_uploads", false)) {
                    Result.retry()
                } else {
                    Result.success()
                }
            } else if (runAttemptCount < MAX_RETRIES) {
                Result.retry()
            } else {
                // Giving up here loses nothing: the media row still says the
                // send is unfinished, so the next flush picks it up again.
                Result.failure()
            }
        } catch (_: Throwable) {
            if (runAttemptCount < MAX_RETRIES) Result.retry() else Result.failure()
        }
    }

    private fun foregroundInfo(): ForegroundInfo {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "Media uploads",
                        NotificationManager.IMPORTANCE_LOW,
                    ),
                )
        }
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Preparing media")
            .setContentText("twonly will finish sending this in the background")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        const val MEDIA_ID = "media_id"
        private const val CHANNEL_ID = "twonly_direct_media_upload"
        private const val NOTIFICATION_ID = 0x7A01
        private const val MAX_RETRIES = 5
    }
}
