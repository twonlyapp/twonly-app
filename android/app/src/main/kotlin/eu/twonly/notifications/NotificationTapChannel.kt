package eu.twonly.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

internal fun nativeNotificationId(value: String): Int = value.hashCode() and Int.MAX_VALUE

/** The single channel every twonly notification is posted on. */
internal const val NOTIFICATION_CHANNEL_ID = "twonly_messages_v2"

internal fun ensureNotificationChannel(context: Context) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val label = context.applicationInfo.loadLabel(context.packageManager).toString()
    val channel = NotificationChannel(
        NOTIFICATION_CHANNEL_ID,
        label,
        NotificationManager.IMPORTANCE_HIGH,
    )
    context.getSystemService(NotificationManager::class.java)
        .createNotificationChannel(channel)
}

/**
 * Forwards taps on natively rendered notifications into Flutter.
 *
 * Only opaque notification metadata travels across this channel; the route
 * itself is built in Dart so Kotlin never duplicates Flutter routing.
 */
object NotificationTapChannel {
    private const val CHANNEL = "eu.twonly/notificationTap"
    const val EXTRA_CONVERSATION_ID = "conversation_id"
    const val EXTRA_NOTIFICATION_KIND = "notification_kind"

    private var channel: MethodChannel? = null
    private var pendingConversationId: String? = null
    private var pendingNotificationKind: String? = null
    private var pendingLaunch = false

    fun configure(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeInitialNotification" -> {
                    val launched = pendingLaunch
                    val conversationId = pendingConversationId
                    val notificationKind = pendingNotificationKind
                    pendingLaunch = false
                    pendingConversationId = null
                    pendingNotificationKind = null
                    result.success(
                        if (launched) {
                            mapOf(
                                EXTRA_CONVERSATION_ID to conversationId,
                                EXTRA_NOTIFICATION_KIND to notificationKind,
                            )
                        } else {
                            null
                        },
                    )
                }
                "cancelNotifications" -> {
                    val notificationIds = call.argument<List<String>>("notification_ids").orEmpty()
                    val manager = NotificationManagerCompat.from(context.applicationContext)
                    notificationIds.forEach { manager.cancel(nativeNotificationId(it)) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        this.channel = channel
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /**
     * Records the launch intent before Flutter attaches. Called for both the
     * cold-start intent and every `onNewIntent`; a live channel is notified
     * immediately, otherwise the tap is buffered for `consumeInitialNotification`.
     */
    fun handleIntent(intent: Intent?) {
        if (intent?.hasExtra(EXTRA_CONVERSATION_ID) != true) return
        val conversationId =
            intent.getStringExtra(EXTRA_CONVERSATION_ID)?.takeIf(String::isNotEmpty)
        val notificationKind =
            intent.getStringExtra(EXTRA_NOTIFICATION_KIND)?.takeIf(String::isNotEmpty)
        // A tap must only route once, even if the activity is recreated with
        // the same intent after a configuration change.
        intent.removeExtra(EXTRA_CONVERSATION_ID)
        intent.removeExtra(EXTRA_NOTIFICATION_KIND)

        val channel = this.channel
        if (channel == null) {
            pendingLaunch = true
            pendingConversationId = conversationId
            pendingNotificationKind = notificationKind
            return
        }
        channel.invokeMethod(
            "onNotificationTapped",
            mapOf(
                EXTRA_CONVERSATION_ID to conversationId,
                EXTRA_NOTIFICATION_KIND to notificationKind,
            ),
        )
    }
}
