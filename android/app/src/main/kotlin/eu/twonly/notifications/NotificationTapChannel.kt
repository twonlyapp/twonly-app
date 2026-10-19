package eu.twonly.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

internal fun nativeNotificationId(value: String): Int = value.hashCode() and Int.MAX_VALUE

/** The single channel every twonly notification is posted on. */
internal const val NOTIFICATION_CHANNEL_ID = "twonly_messages_v2"
internal const val TEXT_MESSAGE_ID = "twonly_message_id"

internal fun suppressesConversationNotification(
    visibleConversationId: String?,
    addition: NativeNotificationAddition,
): Boolean = visibleConversationId != null && addition.conversationId == visibleConversationId &&
    addition.kind !in setOf("twonly", "image", "video", "audio", "story")

/** Retains unread entries when only part of a combined alert was opened. */
internal fun cancelNativeNotifications(context: Context, notificationIds: Collection<String>) {
    if (notificationIds.isEmpty()) return
    val ids = notificationIds.toSet()
    val manager = NotificationManagerCompat.from(context)
    val active = manager.activeNotifications
    ids.forEach { manager.cancel(nativeNotificationId(it)) }
    active.forEach { entry ->
        if (entry.notification.extras.getString(TEXT_MESSAGE_ID) in ids) {
            manager.cancel(entry.id)
            return@forEach
        }
        val style = NotificationCompat.MessagingStyle
            .extractMessagingStyleFromNotification(entry.notification) ?: return@forEach
        val remaining = style.messages.filter { it.extras.getString(TEXT_MESSAGE_ID) !in ids }
        if (remaining.size == style.messages.size) return@forEach
        if (remaining.isEmpty()) {
            manager.cancel(entry.id)
        } else {
            style.messages.clear()
            remaining.forEach(style::addMessage)
            val notification = NotificationCompat.Builder(context, entry.notification)
                .setStyle(style)
                .setNumber(remaining.size)
                .setOnlyAlertOnce(true)
                .build()
            manager.notify(entry.id, notification)
        }
    }
}

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
    @Volatile private var visibleConversationId: String? = null

    internal fun suppresses(addition: NativeNotificationAddition): Boolean =
        suppressesConversationNotification(visibleConversationId, addition)

    internal fun notificationArrived() {
        Handler(Looper.getMainLooper()).post {
            channel?.invokeMethod("onNotificationArrived", null)
        }
    }

    fun configure(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setVisibleConversation" -> {
                    visibleConversationId = call.argument<String>(EXTRA_CONVERSATION_ID)
                        ?.takeIf(String::isNotEmpty)
                    result.success(null)
                }
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
                    cancelNativeNotifications(context.applicationContext, notificationIds)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        this.channel = channel
    }

    fun detach() {
        visibleConversationId = null
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
