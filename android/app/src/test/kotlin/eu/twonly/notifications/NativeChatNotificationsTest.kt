package eu.twonly.notifications

import android.app.Notification
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.toBitmap
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class NativeChatNotificationsTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()

    @Before
    fun setUp() {
        ensureNotificationChannel(context)
    }

    private fun event(
        id: String,
        kind: String = "text",
        chat: String? = "direct",
        sender: Long = 7,
        group: Boolean = false,
        time: Long = 1,
        avatar: String? = null,
    ) = NativeNotificationAddition(
        eventId = id, notificationId = id, conversationId = chat,
        conversationName = if (group) "Friends" else "Alice", isGroup = group,
        kind = kind, senderId = sender, senderName = if (sender == 7L) "Alice" else "Bob",
        title = "title", body = "$kind body", createdAt = time, avatarPath = avatar,
    )

    private fun style(notification: Notification) = requireNotNull(
        NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification),
    )

    private fun post(vararg events: NativeNotificationAddition): Notification {
        val manager = NotificationManagerCompat.from(context)
        val id = nativeNotificationId(nativeNotificationKey(events.last()))
        val previous = manager.activeNotifications.firstOrNull { it.id == id }?.notification
        return buildNativeChatNotification(context, events.toList(), previous).also {
            manager.notify(id, it)
        }
    }

    @Test
    fun reactionsRepliesAndMediaShareOneChatAcrossWakeups() {
        post(event("reply", "response"))
        post(event("reaction", "reaction", time = 2))
        val notification = post(event("image", "image", time = 3))
        assertEquals(1, NotificationManagerCompat.from(context).activeNotifications.size)
        assertEquals(listOf("reply", "reaction", "image"),
            style(notification).messages.map { it.extras.getString(TEXT_MESSAGE_ID) })
        assertEquals(3, notification.number)
        assertNotNull(notification.getLargeIcon())
        assertTrue(style(notification).messages.all { it.person?.icon != null })
    }

    @Test
    fun differentChatsAndEventsWithoutAChatStaySeparate() {
        post(event("one", chat = "one"))
        post(event("two", chat = "two"))
        post(event("request", "contact_request", chat = null))
        assertEquals(3, NotificationManagerCompat.from(context).activeNotifications.size)
    }

    @Test
    fun groupMembersKeepTheirOwnAvatarsInOneGroupNotification() {
        val avatar = File(context.cacheDir, "alice.png").apply {
            outputStream().use {
                Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.RED) }
                    .compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        val notification = post(
            event("alice", chat = "group", group = true, avatar = avatar.path),
            event("bob", "response", chat = "group", sender = 8, group = true, time = 2),
        )
        val style = style(notification)
        assertTrue(style.isGroupConversation)
        assertEquals("Friends", style.conversationTitle.toString())
        assertEquals(listOf("7", "8"), style.messages.map { it.person?.key })
        assertEquals(listOf("Alice", "Bob"), style.messages.map { it.person?.name.toString() })
        assertTrue(style.messages.all { it.person?.icon != null })
        assertNotNull(notification.getLargeIcon())
        assertEquals(1, NotificationManagerCompat.from(context).activeNotifications.size)
    }

    @Test
    fun duplicateDeliveryReplacesAnEntryAndMissingAvatarsHaveAFallback() {
        post(event("message", avatar = "/missing/avatar.png"))
        val notification = post(event("message", time = 2))
        assertEquals(1, style(notification).messages.size)
        assertNotNull(style(notification).messages.single().person?.icon)
        assertNotNull(notification.getLargeIcon())
    }

    @Test
    fun aLaterEventWithoutAnAvatarRetainsTheKnownSenderAvatar() {
        val avatar = File(context.cacheDir, "known-avatar.png").apply {
            outputStream().use {
                Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.RED) }
                    .compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        post(event("first", avatar = avatar.path))
        val notification = post(event("second", "reaction", time = 2))
        val sender = requireNotNull(style(notification).messages.last().person)
        val bitmap = requireNotNull(sender.icon?.loadDrawable(context)).toBitmap()
        assertEquals(Color.RED, bitmap.getPixel(0, 0))
    }

    @Test
    fun clearingPartOfAChatRetainsOtherEventsAndTheirAvatars() {
        post(event("reply", "response"), event("reaction", "reaction", time = 2))
        cancelNativeNotifications(context, listOf("reply"))
        val remaining = NotificationManagerCompat.from(context).activeNotifications.single().notification
        assertEquals("reaction", style(remaining).messages.single().extras.getString(TEXT_MESSAGE_ID))
        assertNotNull(style(remaining).messages.single().person?.icon)
        assertNotNull(remaining.getLargeIcon())
        assertEquals(1, remaining.number)
        cancelNativeNotifications(context, listOf("reaction"))
        assertTrue(NotificationManagerCompat.from(context).activeNotifications.isEmpty())
    }

    @Test
    fun tappingACombinedAlertPreservesTheLatestRoutingMetadata() {
        val notification = post(event("text"), event("reaction", "reaction", time = 2))
        val intent = shadowOf(notification.contentIntent).savedIntent
        assertEquals("direct", intent.getStringExtra(NotificationTapChannel.EXTRA_CONVERSATION_ID))
        assertEquals("reaction", intent.getStringExtra(NotificationTapChannel.EXTRA_NOTIFICATION_KIND))
    }
}
