package eu.twonly.widget

import android.app.Application
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.nio.ByteBuffer

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
class WidgetRuntimeChannelTest {
    @Test
    fun reloadHandlerLivesUntilItsEngineDetaches() {
        val messenger = TestMessenger()
        val binding = binding(messenger)
        val plugin = WidgetRuntimeChannel()

        plugin.onAttachedToEngine(binding)
        messenger.reloadWidgets()
        plugin.onDetachedFromEngine(binding)

        assertFalse(messenger.handlers.containsKey(CHANNEL))
    }

    @Test
    fun detachingAnOldEngineKeepsTheNewEnginesHandler() {
        val oldMessenger = TestMessenger()
        val newMessenger = TestMessenger()
        val oldBinding = binding(oldMessenger)
        val newBinding = binding(newMessenger)
        val oldPlugin = WidgetRuntimeChannel()
        val newPlugin = WidgetRuntimeChannel()

        oldPlugin.onAttachedToEngine(oldBinding)
        newPlugin.onAttachedToEngine(newBinding)
        oldPlugin.onDetachedFromEngine(oldBinding)

        assertFalse(oldMessenger.handlers.containsKey(CHANNEL))
        newMessenger.reloadWidgets()
        newPlugin.onDetachedFromEngine(newBinding)
    }

    // Only the application context and messenger are used by this plugin.
    // Avoid starting a real Flutter engine (and loading its native library).
    private fun binding(messenger: BinaryMessenger) =
        FlutterPlugin.FlutterPluginBinding::class.java.constructors.single().newInstance(
            RuntimeEnvironment.getApplication(), null, messenger, null, null, null, null,
        ) as FlutterPlugin.FlutterPluginBinding

    private class TestMessenger : BinaryMessenger {
        val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler>()

        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
            if (handler == null) handlers.remove(channel) else handlers[channel] = handler
        }

        override fun send(channel: String, message: ByteBuffer?) = error("Unexpected outbound message")

        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) =
            error("Unexpected outbound message")

        fun reloadWidgets() {
            val codec = StandardMethodCodec.INSTANCE
            val message = codec.encodeMethodCall(MethodCall("reloadWidgets", null))
            message.flip()
            var replied = false
            handlers.getValue(CHANNEL).onMessage(message) { reply ->
                replied = true
                // A null reply means MissingPluginException on the Dart side.
                requireNotNull(reply)
                reply.flip()
                assertNull(codec.decodeEnvelope(reply))
            }
            assertTrue(replied)
        }
    }

    companion object {
        private const val CHANNEL = "eu.twonly/runtime_storage"
    }
}
