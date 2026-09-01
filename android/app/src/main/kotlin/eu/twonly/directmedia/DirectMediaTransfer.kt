package eu.twonly.directmedia

import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import eu.twonly.MyApplication
import java.io.File
import java.util.concurrent.TimeUnit
import org.json.JSONObject

/** Called directly from Rust/JNI. It persists the descriptor in app-private
 * storage and enqueues every OS-owned transfer it names before reporting
 * success.
 *
 * A descriptor carries a `media` request and, for a media upload, a `manifest`
 * alongside it. A queued message envelope is the single-request form: there is
 * nothing to describe beyond the POST itself. */
object DirectMediaTransfer {
    @JvmStatic
    fun schedule(descriptorJson: String): Boolean = try {
        val descriptor = JSONObject(descriptorJson)
        val attachmentId = descriptor.getString("attachment_id")
        val expiresAt = descriptor.getLong("expires_at")
        if (expiresAt <= System.currentTimeMillis() / 1_000) return false
        val directory = File(MyApplication.instance.noBackupFilesDir, "direct-media/$attachmentId")
        if (!directory.exists() && !directory.mkdirs()) return false
        val descriptorFile = File(directory, "descriptor.json")
        descriptorFile.writeText(descriptorJson, Charsets.UTF_8)

        val manager = WorkManager.getInstance(MyApplication.instance)
        val media = request(attachmentId, "media", descriptorFile, expiresAt)
        manager.enqueueUniqueWork("direct-media-$attachmentId-media", ExistingWorkPolicy.KEEP, media)
        if (descriptor.has("manifest")) {
            val manifest = request(attachmentId, "manifest", descriptorFile, expiresAt)
            manager.enqueueUniqueWork(
                "direct-media-$attachmentId-manifest",
                ExistingWorkPolicy.KEEP,
                manifest,
            )
        }
        true
    } catch (_: Throwable) {
        false
    }

    private fun request(
        attachmentId: String,
        role: String,
        descriptorFile: File,
        expiresAt: Long,
    ): OneTimeWorkRequest {
        val data = Data.Builder()
            .putString(DirectMediaUploadWorker.ATTACHMENT_ID, attachmentId)
            .putString(DirectMediaUploadWorker.ROLE, role)
            .putString(DirectMediaUploadWorker.DESCRIPTOR_PATH, descriptorFile.absolutePath)
            .putLong(DirectMediaUploadWorker.EXPIRES_AT, expiresAt)
            .build()
        return OneTimeWorkRequest.Builder(DirectMediaUploadWorker::class.java)
            .setInputData(data)
            .setConstraints(
                Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build(),
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 15, TimeUnit.SECONDS)
            .addTag("direct-media-$attachmentId")
            .build()
    }
}
