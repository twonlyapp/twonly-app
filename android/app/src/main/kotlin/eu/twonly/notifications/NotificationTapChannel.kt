package eu.twonly.notifications

import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

internal fun nativeNotificationId(value: String): Int = value.hashCode() and Int.MAX_VALUE

/**
 * Forwards taps on natively rendered notifications into Flutter.
 *
 * Only the opaque conversation identifier travels across this channel; the
 * route itself is built in Dart so Kotlin never duplicates Flutter routing.
 */
object NotificationTapChannel {
    private const val CHANNEL = "eu.twonly/notificationTap"
    const val EXTRA_CONVERSATION_ID = "conversation_id"

    private var channel: MethodChannel? = null
    private var pendingConversationId: String? = null
    private var pendingLaunch = false

    fun configure(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeInitialNotification" -> {
                    val launched = pendingLaunch
                    val conversationId = pendingConversationId
                    pendingLaunch = false
                    pendingConversationId = null
                    result.success(
                        if (launched) {
                            mapOf(EXTRA_CONVERSATION_ID to conversationId)
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
        // A tap must only route once, even if the activity is recreated with
        // the same intent after a configuration change.
        intent.removeExtra(EXTRA_CONVERSATION_ID)

        val channel = this.channel
        if (channel == null) {
            pendingLaunch = true
            pendingConversationId = conversationId
            return
        }
        channel.invokeMethod(
            "onNotificationTapped",
            mapOf(EXTRA_CONVERSATION_ID to conversationId),
        )
    }
}
