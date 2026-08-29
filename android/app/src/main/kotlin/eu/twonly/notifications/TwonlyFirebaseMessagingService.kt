package eu.twonly.notifications

import android.util.Log
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class TwonlyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
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

    private companion object {
        const val TAG = "TwonlyFCM"
        const val UNIQUE_WORK = "twonly-native-notification-drain"
        const val INPUT_MESSAGE_ID = "fcm_message_id"
    }
}
