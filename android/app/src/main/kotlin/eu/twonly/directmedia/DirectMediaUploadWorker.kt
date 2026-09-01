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
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

/** Transport-only worker: request construction, protobufs, encryption and
 * policy decisions have already been completed and persisted by Rust. */
class DirectMediaUploadWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        val attachmentId = inputData.getString(ATTACHMENT_ID) ?: return Result.failure()
        val role = inputData.getString(ROLE) ?: return Result.failure()
        val expiresAt = inputData.getLong(EXPIRES_AT, 0)
        if (expiresAt <= System.currentTimeMillis() / 1_000) return Result.failure()
        return try {
            // Become a data-sync foreground service before opening the file/network
            // streams, otherwise Android may stop long uploads in the background.
            setForegroundAsync(foregroundInfo(attachmentId)).get()
            val path = inputData.getString(DESCRIPTOR_PATH) ?: return Result.failure()
            val descriptor = JSONObject(File(path).readText(Charsets.UTF_8))
            val request = descriptor.getJSONObject(role)
            val status = upload(request)
            if (status in 200..299) {
                // Best effort only. A 202 is success because server reconciliation
                // owns completion when the manifest has not arrived yet. A
                // descriptor with no completion step — a queued message envelope —
                // is finished as soon as its POST is accepted.
                if (role == "media" && descriptor.has("complete")) {
                    upload(descriptor.getJSONObject("complete"))
                }
                Result.success()
            } else if (retryable(status) && expiresAt > System.currentTimeMillis() / 1_000) {
                Result.retry()
            } else {
                Result.failure()
            }
        } catch (_: Throwable) {
            if (expiresAt > System.currentTimeMillis() / 1_000) Result.retry() else Result.failure()
        }
    }

    private fun upload(request: JSONObject): Int {
        val file = File(request.getString("body_path"))
        if (!file.isFile) return 0
        val connection = (URL(request.getString("url")).openConnection() as HttpURLConnection).apply {
            requestMethod = request.optString("method", "POST")
            connectTimeout = 30_000
            readTimeout = 60_000
            doOutput = true
            instanceFollowRedirects = false
            val headers = request.getJSONObject("headers")
            for (name in headers.keys()) setRequestProperty(name, headers.getString(name))
            setFixedLengthStreamingMode(file.length())
        }
        connection.outputStream.use { output ->
            file.inputStream().use { input -> input.copyTo(output, DEFAULT_BUFFER_SIZE) }
        }
        val status = connection.responseCode
        try {
            (if (status >= 400) connection.errorStream else connection.inputStream)?.close()
        } finally {
            connection.disconnect()
        }
        return status
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
        private const val CHANNEL_ID = "twonly_direct_media_upload"
    }
}
