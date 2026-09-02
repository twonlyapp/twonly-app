package eu.twonly.notifications

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import eu.twonly.MainActivity
import eu.twonly.R
import eu.twonly.widget.TwonlyWidgetProvider
import java.util.Locale
import org.json.JSONArray

class TwonlyNotificationWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
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
                // Rust could not reach the mailbox. Show the generic alert so a
                // high-priority wake-up still produces a notification, and retry.
                response.fallback?.let(::showFallback)
                return settle(retry = true)
            }

            val manager = NotificationManagerCompat.from(applicationContext)
            batch.removals.forEach { manager.cancel(nativeNotificationId(it)) }
            val delivered = batch.additions.filter { addition ->
                showAddition(manager, addition)
            }.map(NativeNotificationAddition::eventId)
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
            Log.w(TAG, "Deferred notification maintenance failed", error)
        }
        return Result.success()
    }

    private fun showAddition(
        manager: NotificationManagerCompat,
        addition: NativeNotificationAddition,
    ): Boolean {
        val avatarBitmap = addition.avatarPath?.let(BitmapFactory::decodeFile)
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            // Only opaque identifiers cross into the activity; Dart owns routing.
            putExtra(
                NotificationTapChannel.EXTRA_CONVERSATION_ID,
                addition.conversationId.orEmpty(),
            )
            putExtra(NotificationTapChannel.EXTRA_NOTIFICATION_KIND, addition.kind)
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            nativeNotificationId(addition.notificationId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(addition.title)
            .setContentText(addition.body)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setGroup(addition.conversationId ?: addition.senderId.toString())
            .apply { avatarBitmap?.let(::setLargeIcon) }
            .build()
        return try {
            manager.notify(nativeNotificationId(addition.notificationId), notification)
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
