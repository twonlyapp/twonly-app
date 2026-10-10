package eu.twonly.directmedia

import android.content.Context
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.Operation
import androidx.work.WorkInfo
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
        enqueue(manager, attachmentId, "media", descriptorFile, expiresAt)
        if (descriptor.has("manifest")) {
            enqueue(manager, attachmentId, "manifest", descriptorFile, expiresAt)
        }
        true
    } catch (_: Throwable) {
        false
    }

    /** Called only while the server still reports Reserved/Uploading. Existing
     * attachments are replayable; recovery never creates new dispatch tokens. */
    @JvmStatic
    fun recover(descriptorJson: String, createdAt: Long): Boolean = try {
        val descriptor = JSONObject(descriptorJson)
        val attachmentId = descriptor.getString("attachment_id")
        val expiresAt = descriptor.getLong("expires_at")
        if (expiresAt <= System.currentTimeMillis() / 1_000) return false
        val context = MyApplication.instance
        val directory = File(context.noBackupFilesDir, "direct-media/$attachmentId")
        if (!directory.exists() && !directory.mkdirs()) return false
        val descriptorFile = File(directory, "descriptor.json")
        if (!descriptorFile.exists()) descriptorFile.writeText(descriptorJson, Charsets.UTF_8)
        val manager = WorkManager.getInstance(context)
        val now = System.currentTimeMillis()

        fun info(role: String) = manager.getWorkInfosForUniqueWork(workName(attachmentId, role))
            .get(10, TimeUnit.SECONDS).firstOrNull()
        fun recoverRole(role: String, work: WorkInfo?, retrySucceeded: Boolean = false) {
            val action = recoveryAction(
                work?.state,
                work?.progress?.getLong(DirectMediaUploadWorker.LAST_ACTIVITY_MS, createdAt * 1_000)
                    ?: createdAt * 1_000,
                now, retrySucceeded,
            )
            if (action != RecoveryAction.KEEP) {
                Log.i("TwonlyMediaTransfer", "Recovering $attachmentId/$role state=${work?.state} action=$action")
                enqueue(manager, attachmentId, role, descriptorFile, expiresAt,
                    if (action == RecoveryAction.REPLACE) ExistingWorkPolicy.REPLACE else ExistingWorkPolicy.KEEP)
                    .result.get(10, TimeUnit.SECONDS)
            }
        }

        val media = info("media")
        recoverRole("media", media)
        if (descriptor.has("manifest")) recoverRole("manifest", info("manifest"))
        if (descriptor.has("complete")) {
            val complete = info("complete")
            // Old workers completed without persisting a completion task. Also
            // repeat a successful completion while the manifest was still absent.
            if (media?.state == WorkInfo.State.SUCCEEDED || complete != null) {
                recoverRole("complete", complete, retrySucceeded = true)
            }
        }
        true
    } catch (error: Exception) {
        Log.w("TwonlyMediaTransfer", "Could not recover media transfer", error)
        false
    }

    internal fun enqueueCompletion(
        context: Context, attachmentId: String, descriptor: File, expiresAt: Long,
    ): Operation = enqueue(WorkManager.getInstance(context), attachmentId, "complete", descriptor, expiresAt)

    private fun workName(attachmentId: String, role: String) = "direct-media-$attachmentId-$role"

    private fun enqueue(
        manager: WorkManager, attachmentId: String, role: String, descriptor: File, expiresAt: Long,
        policy: ExistingWorkPolicy = ExistingWorkPolicy.KEEP,
    ): Operation = manager.enqueueUniqueWork(
        workName(attachmentId, role), policy, request(attachmentId, role, descriptor, expiresAt),
    )

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

internal enum class RecoveryAction { KEEP, ENQUEUE, REPLACE }

internal fun recoveryAction(
    state: WorkInfo.State?, lastActivityMs: Long, nowMs: Long, retrySucceeded: Boolean,
): RecoveryAction = when {
    state == null || state == WorkInfo.State.FAILED || state == WorkInfo.State.CANCELLED -> RecoveryAction.ENQUEUE
    state == WorkInfo.State.SUCCEEDED -> if (retrySucceeded) RecoveryAction.ENQUEUE else RecoveryAction.KEEP
    // Leave WorkManager's network constraints/backoff and progressing uploads
    // alone. Ten minutes also bounds workers left running by older app builds.
    state == WorkInfo.State.RUNNING && nowMs - lastActivityMs >= TimeUnit.MINUTES.toMillis(10) -> RecoveryAction.REPLACE
    else -> RecoveryAction.KEEP
}
