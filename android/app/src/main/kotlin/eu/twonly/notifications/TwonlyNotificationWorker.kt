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
import java.util.concurrent.atomic.AtomicLong
import org.json.JSONArray

class TwonlyNotificationWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    private val activeRun = AtomicLong(0)

    override fun onStopped() {
        NativeNotificationBridge.cancelRun(activeRun.get())
        super.onStopped()
    }

    override fun doWork(): Result {
        NativeErrorReporting.breadcrumb(applicationContext, "notification_processing_started")
        val run = NativeNotificationBridge.createRun(RUN_BUDGET_MS)
        if (run == 0L) return Result.retry()
        activeRun.set(run)
        // onStopped can race registration, before it can observe activeRun.
        if (isStopped) NativeNotificationBridge.cancelRun(run)
        return try {
            val directory = applicationContext.filesDir.absolutePath
            val response = NativeNotificationResponse.parse(
                NativeNotificationBridge.processWithId(
                    run,
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
                return settle(run, retry = true)
            }

            val manager = NotificationManagerCompat.from(applicationContext)
            cancelNativeNotifications(applicationContext, batch.removals)
            val delivered = batch.additions.groupBy(::nativeNotificationKey).values.flatMap { additions ->
                if (showAdditions(manager, additions)) {
                    additions.map(NativeNotificationAddition::eventId)
                } else emptyList()
            }
            if (delivered.isNotEmpty()) {
                NativeNotificationBridge.acknowledge(run, JSONArray(delivered).toString())
                NotificationTapChannel.notificationArrived()
                // Real notifications supersede a placeholder from an earlier attempt.
                manager.cancel(FALLBACK_ID)
            }

            // An empty batch is the normal outcome of a duplicate wake-up or of
            // traffic that is not user visible, so it must not retry. Only an
            // undrained mailbox is worth another attempt.
            settle(run, retry = !batch.completed)
        } catch (error: Throwable) {
            NativeErrorReporting.failure(applicationContext, "notification_processing", error)
            Log.e(TAG, "Native notification processing failed", error)
            if (runAttemptCount < MAX_RETRIES) Result.retry() else Result.failure()
        } finally {
            // Even retry and exception paths must stop the socket/tasks and
            // wait for SQLite cleanup before WorkManager sees completion.
            NativeNotificationBridge.finishRun(run)
            activeRun.compareAndSet(run, 0)
        }
    }

    // Ends the attempt, running the deferred wake-up work first when no further
    // attempt is coming. The notification is already on screen by then, so media
    // downloads and widget upkeep no longer delay rendering. Every attempt,
    // including a retry, closes its run in doWork's finally block.
    private fun settle(run: Long, retry: Boolean): Result {
        if (retry && runAttemptCount < MAX_RETRIES) return Result.retry()
        try {
            val finalized = NativeNotificationResponse.parse(
                NativeNotificationBridge.finalizeWakeup(run, FINALIZE_DEADLINE_MS),
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
        if (NotificationTapChannel.suppresses(additions.last())) {
            cancelNativeNotifications(applicationContext, additions.map { it.notificationId })
            return true
        }
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
        const val RUN_BUDGET_MS = 55_000L
    }
}
