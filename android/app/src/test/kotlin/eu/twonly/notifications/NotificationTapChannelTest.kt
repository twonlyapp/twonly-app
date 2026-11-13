package eu.twonly.notifications

import android.app.Application
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import java.nio.ByteBuffer
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
class NotificationTapChannelTest {
    @Test
    fun retiringActivityCannotRemoveReplacementHandler() {
        val messenger = RecordingMessenger()
        val context = RuntimeEnvironment.getApplication()
        val detachOld = NotificationTapChannel.configure(messenger, context)
        val detachNew = NotificationTapChannel.configure(messenger, context)
        try {
            detachOld()
            for ((method, args) in listOf(
                "setVisibleConversation" to mapOf("conversation_id" to "chat"),
                "cancelNotifications" to mapOf("notification_ids" to emptyList<String>()),
            )) {
                val message = StandardMethodCodec.INSTANCE.encodeMethodCall(MethodCall(method, args))
                message.flip()
                var replied = false
                requireNotNull(messenger.handler).onMessage(message) { envelope ->
                    requireNotNull(envelope).flip()
                    assertNull(StandardMethodCodec.INSTANCE.decodeEnvelope(envelope))
                    replied = true
                }
                assertTrue(replied)
            }
        } finally {
            detachNew()
        }
        assertNull(messenger.handler)
    }
}

private class RecordingMessenger : BinaryMessenger {
    var handler: BinaryMessenger.BinaryMessageHandler? = null
    override fun send(channel: String, message: ByteBuffer?) {}
    override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {}
    override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
        this.handler = handler
    }
}
