package eu.twonly.notifications

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.content.FileProvider
import androidx.core.content.LocusIdCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import androidx.core.graphics.drawable.toBitmap
import eu.twonly.MainActivity
import eu.twonly.R
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest

/** Each sender and event kind has one replaceable alert in a conversation. */
internal fun nativeNotificationKey(addition: NativeNotificationAddition): String =
    "${nativeConversationKey(addition)}:sender:${addition.senderId}:kind:${addition.kind}"

private fun nativeConversationKey(addition: NativeNotificationAddition): String =
    addition.conversationId?.takeIf(String::isNotEmpty)?.let { "chat:$it" }
        ?: "sender:${addition.senderId}"

/** Long-lived shortcuts require resource or URI icons rather than inline bitmaps. */
private fun conversationShortcutIcon(context: Context, avatar: Bitmap): IconCompat {
    val bytes = ByteArrayOutputStream().use { output ->
        check(avatar.compress(Bitmap.CompressFormat.PNG, 100, output))
        output.toByteArray()
    }
    val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        .joinToString("") { "%02x".format(it) }
    val directory = File(context.filesDir, "notification_avatars").apply { mkdirs() }
    // Content-based names keep cached shortcut icons valid across avatar changes.
    val file = File(directory, "$digest.png")
    if (!file.exists()) file.writeBytes(bytes)
    return IconCompat.createWithContentUri(
        FileProvider.getUriForFile(context, "${context.packageName}.notification-avatars", file),
    )
}

internal fun buildNativeChatNotification(
    context: Context,
    additions: List<NativeNotificationAddition>,
): Notification {
    val ordered = additions.sortedBy(NativeNotificationAddition::createdAt)
    val latest = ordered.last()
    // Direct-chat names can lag behind profile or nickname changes. Android
    // also repeats the sender in the body when the shortcut title differs.
    val conversationTitle = if (latest.isGroup) {
        latest.conversationName?.takeIf(String::isNotEmpty) ?: latest.senderName
    } else {
        latest.senderName
    }
    val defaultAvatar = BitmapFactory.decodeResource(context.resources, R.drawable.logo)
    // A missing avatar means the contact has none; never retain a removed one.
    val senders = ordered.groupBy(NativeNotificationAddition::senderId).mapValues { (id, entries) ->
        val avatar = entries.last().avatarPath?.let(BitmapFactory::decodeFile)
        val icon = avatar?.let(IconCompat::createWithBitmap)
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
        latest.conversationAvatarPath?.let(BitmapFactory::decodeFile) ?: defaultAvatar
    } else {
        requireNotNull(senders.getValue(latest.senderId).icon?.loadDrawable(context)).toBitmap()
    }
    val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_launcher_foreground)
        .setContentTitle(conversationTitle)
        .setContentText(latest.body)
        // Give each type its own group as well as its own notification ID.
        .setGroup(nativeNotificationKey(latest))
        .addExtras(Bundle().apply { putString(TEXT_MESSAGE_ID, latest.notificationId) })
        .setLargeIcon(conversationAvatar)
        .setWhen(latest.createdAt * 1000)
        .setCategory(NotificationCompat.CATEGORY_MESSAGE)
        .setAutoCancel(true)
        .setContentIntent(pendingIntent)
        .setPriority(NotificationCompat.PRIORITY_HIGH)

    if (!latest.conversationId.isNullOrEmpty()) {
        // A new event replaces the previous body, including events in this batch.
        val messages = listOf(latest).map { entry ->
            NotificationCompat.MessagingStyle.Message(
                entry.body, entry.createdAt * 1000, senders.getValue(entry.senderId),
            ).apply { extras.putString(TEXT_MESSAGE_ID, entry.notificationId) }
        }
        val style = NotificationCompat.MessagingStyle(Person.Builder().setName("twonly").build())
            .setGroupConversation(latest.isGroup)
        if (latest.isGroup) style.setConversationTitle(conversationTitle)
        messages.sortedBy { it.timestamp }.forEach(style::addMessage)
        builder.setStyle(style).setNumber(style.messages.size)

        // Android's conversation layout displays the avatar with the app icon
        // badged at its bottom right. MessagingStyle alone doesn't enable it
        // for apps targeting Android 11+: it needs a published, long-lived shortcut.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val shortcut = ShortcutInfoCompat.Builder(context, nativeNotificationKey(latest))
                    .setShortLabel(conversationTitle)
                    .setIcon(conversationShortcutIcon(context, conversationAvatar))
                    .setPersons(messages.mapNotNull { it.person }.distinctBy { it.key }.toTypedArray())
                    .setLongLived(true)
                    .setLocusId(LocusIdCompat(nativeNotificationKey(latest)))
                    .setIntent(Intent(intent).setAction(Intent.ACTION_VIEW))
                    .build()
                if (ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)) {
                    builder.setShortcutInfo(shortcut)
                }
            } catch (error: Exception) {
                // Shortcut availability must never prevent delivering a message.
                Log.w("TwonlyNotifications", "Could not publish conversation shortcut", error)
            }
        }
    }
    return builder.build()
}
