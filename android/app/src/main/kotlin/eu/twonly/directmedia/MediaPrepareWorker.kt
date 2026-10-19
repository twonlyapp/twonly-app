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
import eu.twonly.NativeErrorReporting
import org.json.JSONObject

/**
 * Runs one Rust maintenance job.
 *
 * With no media id this is the flush: resume interrupted preparations, settle
 * transfers the OS finished while nothing was listening, and drain the message
 * outbox. With one, it prepares that single send.
 *
 * The Rust call is synchronous and owns its own runtime. Foreground execution
 * extends its budget when permitted; background retries can still run as
 * ordinary WorkManager jobs when Android disallows starting the service.
 */
class MediaPrepareWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        NativeErrorReporting.breadcrumb(applicationContext, "media_preparation_started")
        val mediaId = inputData.getString(MEDIA_ID)
        return try {
            if (mediaId != null) {
                // Only a user-visible send justifies a foreground service; the
                // periodic flush runs as ordinary background work.
                setForegroundWhenAllowed(foregroundInfo())
            }
            if (isStopped) return Result.retry()
            val directory = applicationContext.filesDir.absolutePath
            val response = JSONObject(
                NativeMediaPrepareBridge.run(directory, directory, mediaId),
            )
            if (response.optBoolean("ok", false)) {
                // A bounded mailbox/outbox drain can also leave work behind.
                // Its Tokio runtime ends with this call, so WorkManager owns
                // the retry for messages as well as native media transfers.
                if (response.optBoolean("pending_uploads", false) ||
                    response.optBoolean("pending_messages", false)) {
                    Result.retry()
                } else {
                    Result.success()
                }
            } else if (runAttemptCount < MAX_RETRIES) {
                Result.retry()
            } else {
                NativeErrorReporting.failure(applicationContext, "media_preparation")
                // Giving up here loses nothing: the media row still says the
                // send is unfinished, so the next flush picks it up again.
                Result.failure()
            }
        } catch (error: Throwable) {
            NativeErrorReporting.failure(applicationContext, "media_preparation", error)
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
