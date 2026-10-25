package eu.twonly.notifications

import android.app.Application
import android.app.Notification
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.Icon
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import androidx.core.graphics.drawable.toBitmap
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog
import org.robolectric.util.ReflectionHelpers
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
class NativeChatNotificationsTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()

    @Test
    fun rustFailureReasonSurvivesParsingWithoutChangingLegacyResponses() {
        val cancelled = NativeNotificationResponse.parse(
            """{"ok":false,"batch":null,"error":"Notification run cancelled"}""",
        )
        assertFalse(cancelled.ok)
        assertNull(cancelled.batch)
        assertEquals("Notification run cancelled", cancelled.error)
        for (json in listOf("""{"ok":true}""", """{"ok":false,"error":null}""")) {
            assertNull(NativeNotificationResponse.parse(json).error)
        }
    }

    @Before
    fun setUp() {
        // Robolectric gives each test a different data directory, while
        // FileProvider caches its resolved roots for the lifetime of the JVM.
        ReflectionHelpers.getStaticField<MutableMap<String, Any>>(FileProvider::class.java, "sCache")
            .clear()
        ensureNotificationChannel(context)
        shadowOf(context.getSystemService(ShortcutManager::class.java)).setMaxShortcutCountPerActivity(5)
    }

    private fun event(
        id: String,
        kind: String = "text",
        chat: String? = "direct",
        sender: Long = 7,
        group: Boolean = false,
        time: Long = 1,
        avatar: String? = null,
        groupAvatar: String? = null,
    ) = NativeNotificationAddition(
        eventId = id, notificationId = id, conversationId = chat,
        conversationName = if (group) "Friends" else "Alice", isGroup = group,
        kind = kind, senderId = sender, senderName = if (sender == 7L) "Alice" else "Bob",
        title = "title", body = "$kind body", createdAt = time, avatarPath = avatar, conversationAvatarPath = groupAvatar,
    )

    private fun style(notification: Notification) = requireNotNull(
        NotificationCompat.MessagingStyle.extractMessagingStyleFromNotification(notification),
    )

    @Test
    fun visibleConversationSuppressesActivityAndPreservesMediaAlerts() {
        for (chat in listOf("direct", "group")) {
            for (kind in listOf("text", "reaction", "stored_media", "reopened_media", "webxdc", "added_to_group", "future_activity")) {
                val addition = event("activity", kind = kind, chat = chat)
                assertTrue(suppressesConversationNotification(chat, addition))
                assertFalse(suppressesConversationNotification(null, addition))
                assertFalse(suppressesConversationNotification("other", addition))
            }
            for (kind in listOf("twonly", "image", "video", "audio", "story")) {
                assertFalse(suppressesConversationNotification(chat, event("media", kind = kind, chat = chat)))
            }
        }
    }

    @Test
    fun backgroundedActivityDoesNotSuppressNotificationsForItsLastOpenChat() {
        NotificationTapChannel.setVisibleConversation("direct")
        try {
            NotificationTapChannel.setApplicationActive(true)
            assertTrue(NotificationTapChannel.suppresses(event("message")))
            // Native onStop must take effect even if Dart has not yet cleared
            // its visible conversation through the platform channel.
            NotificationTapChannel.setApplicationActive(false)
            assertFalse(NotificationTapChannel.suppresses(event("message")))
            NotificationTapChannel.setApplicationActive(true)
            assertTrue(NotificationTapChannel.suppresses(event("message")))
        } finally {
            NotificationTapChannel.setVisibleConversation(null)
            NotificationTapChannel.setApplicationActive(false)
        }
    }

    private fun shortcut(notification: Notification): android.content.pm.ShortcutInfo {
        assertNotNull(ShadowLog.getLogsForTag("TwonlyNotifications").toString(), notification.shortcutId)
        return context.getSystemService(ShortcutManager::class.java)
            .dynamicShortcuts.single { it.id == notification.shortcutId }
    }

    private fun shortcutAvatar(notification: Notification): Bitmap {
        val icon = ReflectionHelpers.callInstanceMethod<Icon>(shortcut(notification), "getIcon")
        assertEquals(Icon.TYPE_URI, icon.type)
        return context.contentResolver.openInputStream(icon.uri)!!.use {
            requireNotNull(BitmapFactory.decodeStream(it))
        }
    }

    private fun post(vararg events: NativeNotificationAddition): Notification {
        val manager = NotificationManagerCompat.from(context)
        return events.groupBy(::nativeNotificationKey).values.map { additions ->
            val id = nativeNotificationId(nativeNotificationKey(additions.last()))
            buildNativeChatNotification(context, additions).also {
                manager.notify(id, it)
            }
        }.last()
    }

    @Test
    fun flameCountersFollowTheDisplayNameInTitlesPeopleAndShortcuts() {
        for (name in listOf("Alice 12🔥", "Alice 12🔥⌛", "Alice 12❤️‍🔥", "Alice 💯", "Alice 365🎂⌛", "Alice")) {
            for (kind in listOf("text", "image", "story")) {
                val addition = event("flames-$kind", kind).copy(senderName = name, conversationName = name)
                val notification = post(addition)
                assertEquals(name, notification.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
                assertEquals(name, style(notification).messages.single().person?.name.toString())
                assertEquals(name, shortcut(notification).shortLabel.toString())
                assertEquals(addition.body, notification.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
            }
        }
        assertEquals(3, NotificationManagerCompat.from(context).activeNotifications.size)
    }

    @Test
    fun renamedContactsUseTheCurrentNameOnceAcrossAllDirectChatTypes() {
        for (kind in listOf("text", "image", "live_location")) {
            post(event("old-$kind", kind).copy(
                senderName = "Tobi ✌", conversationName = "Tobi ✌",
            ))
            val renamed = event("new-$kind", kind, time = 2).copy(
                senderName = "Tobi", conversationName = "Tobi ✌",
            )
            val notification = post(renamed)
            val style = style(notification)
            assertEquals("Tobi", notification.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
            assertEquals("Tobi", shortcut(notification).shortLabel.toString())
            assertEquals("Tobi", style.messages.single().person?.name.toString())
            assertEquals(renamed.body, style.messages.single().text.toString())
            assertEquals(renamed.body, notification.extras.getCharSequence(Notification.EXTRA_TEXT).toString())
            assertFalse(style.isGroupConversation)
            assertNull(style.conversationTitle)
        }
        assertEquals(3, NotificationManagerCompat.from(context).activeNotifications.size)
    }

    @Test
    fun differentKindsKeepSeparateAlertsAcrossWakeups() {
        post(event("reply", "response"))
        post(event("reaction", "reaction", time = 2))
        val notification = post(event("image", "image", time = 3))
        assertEquals(3, NotificationManagerCompat.from(context).activeNotifications.size)
        assertEquals(listOf("image"),
            style(notification).messages.map { it.extras.getString(TEXT_MESSAGE_ID) })
        assertEquals(1, notification.number)
        assertNotNull(notification.getLargeIcon())
        assertTrue(style(notification).messages.all { it.person?.icon != null })
    }

    @Test
    fun twoTextsAndTwoImagesProduceOneLatestAlertPerKind() {
        post(event("text-one"), event("image-one", "image"))
        post(event("text-two", time = 2), event("image-two", "image", time = 2))
        val active = NotificationManagerCompat.from(context).activeNotifications
        assertEquals(2, active.size)
        assertEquals(setOf("text-two", "image-two"), active.map {
            style(it.notification).messages.single().extras.getString(TEXT_MESSAGE_ID)
        }.toSet())
        assertTrue(active.all { it.notification.number == 1 })
        // System UI can merge notifications that share a conversation identity
        // even when the application posts them under distinct numeric IDs.
        assertEquals(2, active.map { it.notification.shortcutId }.toSet().size)
        assertEquals(2, active.map { it.notification.locusId?.id }.toSet().size)
        assertEquals(2, active.map { it.notification.group }.toSet().size)
        assertTrue(active.all { it.notification.group == it.notification.shortcutId })
    }

    @Test
    fun aBatchUsesOnlyTheLatestEventOfEachKind() {
        val notification = post(event("image-two", "image", time = 2), event("image-one", "image"))
        assertEquals(1, NotificationManagerCompat.from(context).activeNotifications.size)
        assertEquals("image-two", style(notification).messages.single().extras.getString(TEXT_MESSAGE_ID))
    }

    @Test
    fun clearingAnOverwrittenEventKeepsTheLatestAlert() {
        post(event("image-one", "image"))
        post(event("image-two", "image", time = 2))
        cancelNativeNotifications(context, listOf("image-one"))
        assertEquals(1, NotificationManagerCompat.from(context).activeNotifications.size)
        cancelNativeNotifications(context, listOf("image-two"))
        assertTrue(NotificationManagerCompat.from(context).activeNotifications.isEmpty())
    }

    @Test
    fun eventsWithoutAChatReplaceBySenderAndKindAndCanBeCleared() {
        post(event("request-one", "contact_request", chat = null))
        post(event("request-two", "contact_request", chat = null, time = 2))
        post(event("other-request", "contact_request", chat = null, sender = 8))
        assertEquals(2, NotificationManagerCompat.from(context).activeNotifications.size)
        cancelNativeNotifications(context, listOf("request-one"))
        assertEquals(2, NotificationManagerCompat.from(context).activeNotifications.size)
        cancelNativeNotifications(context, listOf("request-two", "other-request"))
        assertTrue(NotificationManagerCompat.from(context).activeNotifications.isEmpty())
    }

    @Test
    fun differentChatsAndEventsWithoutAChatStaySeparate() {
        post(event("one", chat = "one"))
        post(event("two", chat = "two"))
        post(event("request", "contact_request", chat = null))
        assertEquals(3, NotificationManagerCompat.from(context).activeNotifications.size)
        assertEquals(setOf("chat:one:sender:7:kind:text", "chat:two:sender:7:kind:text"),
            context.getSystemService(ShortcutManager::class.java).dynamicShortcuts.map { it.id }.toSet())
    }

    @Test
    fun groupMembersKeepTheirOwnAlertsAndAvatars() {
        val avatar = File(context.cacheDir, "alice.png").apply {
            outputStream().use {
                Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.RED) }
                    .compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        val groupAvatar = File(context.cacheDir, "group.png").apply {
            outputStream().use {
                Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.BLUE) }
                    .compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        val notification = post(
            event("alice", chat = "group", group = true, avatar = avatar.path, groupAvatar = groupAvatar.path),
            event("bob", chat = "group", sender = 8, group = true, time = 2, groupAvatar = groupAvatar.path),
        )
        val style = style(notification)
        assertTrue(style.isGroupConversation)
        assertEquals("Friends", style.conversationTitle.toString())
        assertEquals(listOf("8"), style.messages.map { it.person?.key })
        assertEquals(listOf("Bob"), style.messages.map { it.person?.name.toString() })
        assertTrue(style.messages.all { it.person?.icon != null })
        assertNotNull(notification.getLargeIcon())
        val active = NotificationManagerCompat.from(context).activeNotifications
        assertEquals(2, active.size)
        val alice = active.single {
            style(it.notification).messages.single().person?.key == "7"
        }.notification
        val aliceIcon = requireNotNull(style(alice).messages.single().person?.icon)
        assertEquals(Color.RED, requireNotNull(aliceIcon.loadDrawable(context)).toBitmap().getPixel(0, 0))
        assertEquals("Friends", shortcut(notification).shortLabel.toString())
        val people = ReflectionHelpers.callInstanceMethod<Array<android.app.Person>>(
            shortcut(notification), "getPersons",
        )
        assertEquals(listOf("8"), people.map { it.key })
        assertEquals(Color.BLUE, shortcutAvatar(notification).getPixel(0, 0))
        val largeIcon = ReflectionHelpers.callInstanceMethod<Bitmap>(notification.getLargeIcon(), "getBitmap")
        assertEquals(Color.BLUE, largeIcon.getPixel(0, 0))
    }

    @Test
    fun duplicateDeliveryReplacesAnEntryAndMissingAvatarsHaveAFallback() {
        post(event("message", avatar = "/missing/avatar.png"))
        val notification = post(event("message", time = 2))
        assertEquals(1, style(notification).messages.size)
        assertNotNull(style(notification).messages.single().person?.icon)
        assertNotNull(notification.getLargeIcon())
        assertNotNull(shortcutAvatar(notification))
    }

    @Test
    fun aRemovedAvatarUsesTheTwonlyLogo() {
        val avatar = File(context.cacheDir, "known-avatar.png").apply {
            outputStream().use {
                Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.RED) }
                    .compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        }
        post(event("first", avatar = avatar.path))
        val notification = post(event("second", time = 2))
        val sender = requireNotNull(style(notification).messages.last().person)
        val bitmap = requireNotNull(sender.icon?.loadDrawable(context)).toBitmap()
        val logo = BitmapFactory.decodeResource(context.resources, eu.twonly.R.drawable.logo)
        assertTrue(logo.sameAs(bitmap))
        assertTrue(logo.sameAs(shortcutAvatar(notification)))
        assertEquals(1, context.getSystemService(ShortcutManager::class.java).dynamicShortcuts.size)
    }

    @Test
    fun clearingOneKindRetainsOtherKindsAndTheirAvatars() {
        post(event("reply", "response"), event("reaction", "reaction", time = 2))
        cancelNativeNotifications(context, listOf("reply"))
        val remaining = NotificationManagerCompat.from(context).activeNotifications.single().notification
        assertEquals("reaction", style(remaining).messages.single().extras.getString(TEXT_MESSAGE_ID))
        assertNotNull(style(remaining).messages.single().person?.icon)
        assertNotNull(remaining.getLargeIcon())
        assertEquals(1, remaining.number)
        assertEquals("chat:direct:sender:7:kind:reaction", remaining.shortcutId)
        cancelNativeNotifications(context, listOf("reaction"))
        assertTrue(NotificationManagerCompat.from(context).activeNotifications.isEmpty())
    }

    @Test
    fun tappingEachKindPreservesItsOwnRoutingMetadata() {
        val notification = post(event("text"), event("reaction", "reaction", time = 2))
        val text = NotificationManagerCompat.from(context).activeNotifications.single {
            it.id == nativeNotificationId(nativeNotificationKey(event("text")))
        }.notification
        assertEquals("text", shadowOf(text.contentIntent).savedIntent
            .getStringExtra(NotificationTapChannel.EXTRA_NOTIFICATION_KIND))
        assertNotEquals(text.contentIntent, notification.contentIntent)
        val intent = shadowOf(notification.contentIntent).savedIntent
        assertEquals("direct", intent.getStringExtra(NotificationTapChannel.EXTRA_CONVERSATION_ID))
        assertEquals("reaction", intent.getStringExtra(NotificationTapChannel.EXTRA_NOTIFICATION_KIND))
        val shortcut = shortcut(notification)
        assertEquals("chat:direct:sender:7:kind:reaction", notification.shortcutId)
        assertEquals(notification.shortcutId, notification.locusId?.id)
        assertTrue(ReflectionHelpers.callInstanceMethod<Boolean>(shortcut, "isLongLived"))
        val shortcutIntent = requireNotNull(shortcut.intent)
        assertEquals(Intent.ACTION_VIEW, shortcutIntent.action)
        assertEquals(intent.component, shortcutIntent.component)
        assertEquals("direct", shortcutIntent.getStringExtra(NotificationTapChannel.EXTRA_CONVERSATION_ID))
        assertEquals("reaction", shortcutIntent.getStringExtra(NotificationTapChannel.EXTRA_NOTIFICATION_KIND))
    }

    @Test
    fun unavailableShortcutsStillDeliverTheMessage() {
        shadowOf(context.getSystemService(ShortcutManager::class.java)).setMaxShortcutCountPerActivity(0)
        val notification = post(event("text"))
        assertEquals(1, style(notification).messages.size)
        assertNotNull(notification.getLargeIcon())
        assertNull(notification.shortcutId)
        assertEquals(1, NotificationManagerCompat.from(context).activeNotifications.size)
    }

    @Test
    @Config(sdk = [29])
    fun olderAndroidKeepsMessagingStyleWithoutAConversationShortcut() {
        val notification = post(event("text"))
        assertEquals(1, style(notification).messages.size)
        assertNotNull(notification.getLargeIcon())
        assertNull(notification.shortcutId)
        assertTrue(context.getSystemService(ShortcutManager::class.java).dynamicShortcuts.isEmpty())
    }
}
