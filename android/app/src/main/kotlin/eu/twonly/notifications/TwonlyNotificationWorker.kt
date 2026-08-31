package eu.twonly.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import eu.twonly.MainActivity
import eu.twonly.R
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
                    RUST_DEADLINE_MS,
                ),
            )
            ensureChannel()
            val batch = response.batch
            if (!response.ok || batch == null) {
                // Rust could not reach the mailbox. Show the generic alert so a
                // high-priority wake-up still produces a notification, and retry.
                response.fallback?.let(::showFallback)
                return if (runAttemptCount < MAX_RETRIES) Result.retry() else Result.success()
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
            if (!batch.completed && runAttemptCount < MAX_RETRIES) {
                Result.retry()
            } else {
                Result.success()
            }
        } catch (error: Throwable) {
            Log.e(TAG, "Native notification processing failed", error)
            if (runAttemptCount < MAX_RETRIES) Result.retry() else Result.failure()
        }
    }

    private fun showAddition(
        manager: NotificationManagerCompat,
        addition: NativeNotificationAddition,
    ): Boolean {
        val avatarBitmap = addition.avatarPath?.let(BitmapFactory::decodeFile)
        val avatar = avatarBitmap?.let(IconCompat::createWithBitmap)
        val sender = Person.Builder()
            .setName(addition.senderName)
            .setKey(addition.senderId.toString())
            .setIcon(avatar)
            .build()
        val user = Person.Builder().setName(applicationLabel()).setKey("twonly-user").build()
        val style = NotificationCompat.MessagingStyle(user)
            .addMessage(addition.body, addition.createdAt * 1_000, sender)
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            // Only opaque identifiers cross into the activity; Dart owns routing.
            putExtra(
                NotificationTapChannel.EXTRA_CONVERSATION_ID,
                addition.conversationId.orEmpty(),
            )
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            nativeNotificationId(addition.notificationId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(addition.title)
            .setContentText(addition.body)
            .setStyle(style)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setGroup(addition.conversationId ?: addition.senderId.toString())
            // Android only draws the MessagingStyle person icon for conversation
            // notifications, which require a long-lived shortcut. Without one the
            // standard template is used, where the large icon is the only place
            // the sender's avatar can appear.
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
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
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

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            applicationLabel(),
            NotificationManager.IMPORTANCE_HIGH,
        )
        applicationContext.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun applicationLabel(): String =
        applicationContext.applicationInfo.loadLabel(applicationContext.packageManager).toString()

    private companion object {
        const val TAG = "TwonlyNotification"
        const val CHANNEL_ID = "twonly_messages_v2"
        const val FALLBACK_ID = 0x74776F
        const val MAX_RETRIES = 2
        const val RUST_DEADLINE_MS = 25_000L
    }
}
