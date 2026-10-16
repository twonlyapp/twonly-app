package eu.twonly.notifications

import android.app.PendingIntent
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import eu.twonly.MainActivity
import eu.twonly.R

class TwonlyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        // Server side alerts (plan changes, passwordless recovery) carry a ready
        // made notification instead of the opaque wake-up envelope. Android only
        // presents those by itself while twonly is backgrounded, so dropping them
        // here loses every alert that arrives with the app open.
        message.notification?.let { notification ->
            showServerNotification(notification.title, notification.body)
            return
        }

        if (message.data["kind"] != "message_wakeup" || message.data["version"] != "1") {
            Log.w(TAG, "Ignoring unsupported opaque FCM payload")
            return
        }

        val request = OneTimeWorkRequestBuilder<TwonlyNotificationWorker>()
            .setInputData(Data.Builder().putString(INPUT_MESSAGE_ID, message.messageId).build())
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            UNIQUE_WORK,
            ExistingWorkPolicy.APPEND_OR_REPLACE,
            request,
        )
    }

    override fun onNewToken(token: String) {
        try {
            val directory = applicationContext.filesDir.absolutePath
            NativeNotificationBridge.storeFcmToken(directory, directory, token)
        } catch (error: Throwable) {
            Log.e(TAG, "Could not persist refreshed FCM token in Rust", error)
        }
    }

    private fun showServerNotification(title: String?, body: String?) {
        if (title.isNullOrEmpty() && body.isNullOrEmpty()) return
        ensureNotificationChannel(applicationContext)
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            SERVER_ALERT_ID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        try {
            NotificationManagerCompat.from(applicationContext)
                .notify(SERVER_ALERT_ID, notification)
        } catch (error: SecurityException) {
            Log.w(TAG, "Notification permission is unavailable", error)
        }
    }

    private companion object {
        const val TAG = "TwonlyFCM"
        const val UNIQUE_WORK = "twonly-native-notification-drain"
        const val INPUT_MESSAGE_ID = "fcm_message_id"
        const val SERVER_ALERT_ID = 0x74776F01
    }
}
