package eu.twonly.notifications

import android.content.Context
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import eu.twonly.R
import eu.twonly.NativeErrorReporting
import eu.twonly.widget.TwonlyWidgetProvider
import java.util.Locale
import org.json.JSONArray

class TwonlyNotificationWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        NativeErrorReporting.breadcrumb(applicationContext, "notification_processing_started")
        return try {
            val directory = applicationContext.filesDir.absolutePath
            val response = NativeNotificationResponse.parse(
                NativeNotificationBridge.process(
                    directory,
                    directory,
                    Locale.getDefault().toLanguageTag(),
                    PROCESS_DEADLINE_MS,
                ),
            )
            if (response.widgetRefresh) TwonlyWidgetProvider.refreshAll(applicationContext)
            ensureNotificationChannel(applicationContext)
            val batch = response.batch
            if (!response.ok || batch == null) {
                if (runAttemptCount >= MAX_RETRIES) {
                    NativeErrorReporting.failure(applicationContext, "notification_processing")
                }
                // Rust could not reach the mailbox. Show the generic alert so a
                // high-priority wake-up still produces a notification, and retry.
                response.fallback?.let(::showFallback)
                return settle(retry = true)
            }

            val manager = NotificationManagerCompat.from(applicationContext)
            cancelNativeNotifications(applicationContext, batch.removals)
            val delivered = batch.additions.groupBy(::nativeNotificationKey).values.flatMap { additions ->
                if (showAdditions(manager, additions)) {
                    additions.map(NativeNotificationAddition::eventId)
                } else emptyList()
            }
            if (delivered.isNotEmpty()) {
                NativeNotificationBridge.acknowledge(JSONArray(delivered).toString())
                // Real notifications supersede a placeholder from an earlier attempt.
                manager.cancel(FALLBACK_ID)
            }

            // An empty batch is the normal outcome of a duplicate wake-up or of
            // traffic that is not user visible, so it must not retry. Only an
            // undrained mailbox is worth another attempt.
            settle(retry = !batch.completed)
        } catch (error: Throwable) {
            NativeErrorReporting.failure(applicationContext, "notification_processing", error)
            Log.e(TAG, "Native notification processing failed", error)
            if (runAttemptCount < MAX_RETRIES) Result.retry() else Result.failure()
        }
    }

    // Ends the attempt, running the deferred wake-up work first when no further
    // attempt is coming. The notification is already on screen by then, so media
    // downloads, widget upkeep, and the socket shutdown no longer sit between
    // the message and the alert. A retry skips it and keeps the connection for
    // the next attempt.
    private fun settle(retry: Boolean): Result {
        if (retry && runAttemptCount < MAX_RETRIES) return Result.retry()
        try {
            val finalized = NativeNotificationResponse.parse(
                NativeNotificationBridge.finalizeWakeup(FINALIZE_DEADLINE_MS),
            )
            if (finalized.widgetRefresh) TwonlyWidgetProvider.refreshAll(applicationContext)
        } catch (error: Throwable) {
            NativeErrorReporting.failure(applicationContext, "notification_finalize", error)
            Log.w(TAG, "Deferred notification maintenance failed", error)
        }
        return Result.success()
    }

    private fun showAdditions(
        manager: NotificationManagerCompat,
        additions: List<NativeNotificationAddition>,
    ): Boolean {
        val notificationId = nativeNotificationId(nativeNotificationKey(additions.last()))
        val notification = buildNativeChatNotification(applicationContext, additions)
        return try {
            manager.notify(notificationId, notification)
            true
        } catch (error: SecurityException) {
            Log.w(TAG, "Notification permission is unavailable", error)
            false
        }
    }

    private fun showFallback(presentation: NativeNotificationPresentation) {
        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(presentation.title)
            .setContentText(presentation.body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(applicationContext).notify(FALLBACK_ID, notification)
        } catch (error: SecurityException) {
            Log.w(TAG, "Notification permission is unavailable", error)
        }
    }

    private companion object {
        const val TAG = "TwonlyNotification"
        const val FALLBACK_ID = 0x74776F
        const val MAX_RETRIES = 2

        // Split from the old single 25s budget: the drain only has to produce
        // the batch, and everything deferred behind it gets its own window.
        const val PROCESS_DEADLINE_MS = 20_000L
        const val FINALIZE_DEADLINE_MS = 25_000L
    }
}
