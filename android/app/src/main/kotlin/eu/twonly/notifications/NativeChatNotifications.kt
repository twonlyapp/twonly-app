package eu.twonly.notifications

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
import androidx.core.graphics.drawable.toBitmap
import eu.twonly.MainActivity
import eu.twonly.R

/** All event kinds and senders in a chat update the same alert. */
internal fun nativeNotificationKey(addition: NativeNotificationAddition): String =
    addition.conversationId?.takeIf(String::isNotEmpty)?.let { "chat:$it" }
        ?: addition.notificationId

internal fun buildNativeChatNotification(
    context: Context,
    additions: List<NativeNotificationAddition>,
    previous: Notification? = null,
): Notification {
    val ordered = additions.sortedBy(NativeNotificationAddition::createdAt)
    val latest = ordered.last()
    val previousStyle = previous?.let(
        NotificationCompat.MessagingStyle::extractMessagingStyleFromNotification,
    )
    val defaultAvatar = BitmapFactory.decodeResource(context.resources, R.drawable.notification_default_avatar)
    // A later event may arrive while an avatar is unavailable. Retain a known
    // sender icon from this batch or the existing alert before using the default.
    val senders = ordered.groupBy(NativeNotificationAddition::senderId).mapValues { (id, entries) ->
        val avatar = entries.asReversed().firstNotNullOfOrNull { entry ->
            entry.avatarPath?.let(BitmapFactory::decodeFile)
        }
        val icon = avatar?.let(IconCompat::createWithBitmap)
            ?: previousStyle?.messages?.asReversed()?.firstNotNullOfOrNull { message ->
                message.person?.takeIf { it.key == id.toString() }?.icon
            }
            ?: IconCompat.createWithBitmap(defaultAvatar)
        Person.Builder().setName(entries.last().senderName).setKey(id.toString())
            .setIcon(icon).build()
    }
    val notificationId = nativeNotificationId(nativeNotificationKey(latest))
    val intent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        // Only opaque identifiers cross into the activity; Dart owns routing.
        putExtra(NotificationTapChannel.EXTRA_CONVERSATION_ID, latest.conversationId.orEmpty())
        putExtra(NotificationTapChannel.EXTRA_NOTIFICATION_KIND, latest.kind)
    }
    val pendingIntent = PendingIntent.getActivity(
        context, notificationId, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val conversationAvatar = if (latest.isGroup) {
        requireNotNull(ContextCompat.getDrawable(context, R.drawable.notification_group_avatar))
            .toBitmap(128, 128)
    } else {
        requireNotNull(senders.getValue(latest.senderId).icon?.loadDrawable(context)).toBitmap()
    }
    val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_launcher_foreground)
        .setContentTitle(if (latest.isGroup) latest.conversationName else latest.senderName)
        .setContentText(latest.body)
        .setLargeIcon(conversationAvatar)
        .setWhen(latest.createdAt * 1000)
        .setCategory(NotificationCompat.CATEGORY_MESSAGE)
        .setAutoCancel(true)
        .setContentIntent(pendingIntent)
        .setPriority(NotificationCompat.PRIORITY_HIGH)

    if (!latest.conversationId.isNullOrEmpty()) {
        val replacing = ordered.map(NativeNotificationAddition::notificationId).toSet()
        val messages = previousStyle?.messages.orEmpty().filter {
            it.extras.getString(TEXT_MESSAGE_ID) !in replacing
        } + ordered.distinctBy(NativeNotificationAddition::notificationId).map { entry ->
            NotificationCompat.MessagingStyle.Message(
                entry.body, entry.createdAt * 1000, senders.getValue(entry.senderId),
            ).apply { extras.putString(TEXT_MESSAGE_ID, entry.notificationId) }
        }
        val style = NotificationCompat.MessagingStyle(Person.Builder().setName("twonly").build())
            .setGroupConversation(latest.isGroup)
        if (latest.isGroup) style.setConversationTitle(latest.conversationName)
        messages.sortedBy { it.timestamp }.forEach(style::addMessage)
        builder.setStyle(style).setNumber(style.messages.size)
    }
    return builder.build()
}
