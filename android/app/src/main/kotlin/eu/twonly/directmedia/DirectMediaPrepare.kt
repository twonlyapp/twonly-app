package eu.twonly.directmedia

import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.OutOfQuotaPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import eu.twonly.MyApplication
import java.util.concurrent.TimeUnit

/**
 * Owns the window between the send button and the point where a transfer
 * belongs to the OS.
 *
 * Compressing, encrypting and encrypting-for-each-recipient all run in the app
 * process, so swiping the app away mid-send used to strand the message until
 * the next launch. Running that work inside WorkManager instead means the
 * system restarts it: a job survives the task being removed from recents and is
 * re-run after a reboot.
 *
 * [schedule] is called directly from Rust over JNI.
 */
object DirectMediaPrepare {
    /** Prepares one media file. Unique per media id, so a send that is already
     * being prepared is never started twice. */
    @JvmStatic
    fun schedule(mediaId: String): Boolean = try {
        val data = Data.Builder()
            .putString(MediaPrepareWorker.MEDIA_ID, mediaId)
            .build()
        val request = OneTimeWorkRequest.Builder(MediaPrepareWorker::class.java)
            .setInputData(data)
            // Preparation is what the user is waiting on, and it is short, so it
            // asks for an expedited slot and settles for a normal one.
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .addTag(TAG)
            .build()
        WorkManager.getInstance(MyApplication.instance).enqueueUniqueWork(
            "$UNIQUE_PREFIX$mediaId",
            ExistingWorkPolicy.KEEP,
            request,
        )
        true
    } catch (_: Throwable) {
        false
    }

    /**
     * Keeps a periodic flush registered.
     *
     * Preparation and the message outbox are both resumed by a connection that
     * only exists while something is running. This is what gives a device that
     * regained a network hours after the app was closed somewhere to resume
     * from. Registered from [eu.twonly.MyApplication] and after a reboot.
     */
    @JvmStatic
    fun ensurePeriodicFlush() {
        try {
            val request = PeriodicWorkRequestBuilder<MediaPrepareWorker>(
                FLUSH_INTERVAL_MINUTES,
                TimeUnit.MINUTES,
            )
                .setConstraints(
                    Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build(),
                )
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 5, TimeUnit.MINUTES)
                .addTag(TAG)
                .build()
            WorkManager.getInstance(MyApplication.instance).enqueueUniquePeriodicWork(
                UNIQUE_FLUSH,
                // KEEP would silently ignore a changed interval or constraint.
                ExistingPeriodicWorkPolicy.UPDATE,
                request,
            )
        } catch (_: Throwable) {
            // A device that will not schedule the flush still resumes on the
            // next launch, which is where this behaviour was before.
        }
    }

    /** Runs the flush once, now. Used after a reboot and on connectivity
     * changes, where waiting for the periodic slot would be pointless. */
    @JvmStatic
    fun flushNow() {
        try {
            val request = OneTimeWorkRequest.Builder(MediaPrepareWorker::class.java)
                .setConstraints(
                    Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build(),
                )
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
                .addTag(TAG)
                .build()
            WorkManager.getInstance(MyApplication.instance).enqueueUniqueWork(
                UNIQUE_FLUSH_NOW,
                ExistingWorkPolicy.KEEP,
                request,
            )
        } catch (_: Throwable) {
        }
    }

    const val TAG = "twonly-media-prepare"
    private const val UNIQUE_PREFIX = "media-prepare-"
    private const val UNIQUE_FLUSH = "twonly-outbox-flush"
    private const val UNIQUE_FLUSH_NOW = "twonly-outbox-flush-now"
    private const val FLUSH_INTERVAL_MINUTES = 30L
}
