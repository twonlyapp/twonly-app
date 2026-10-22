package eu.twonly

import android.app.Application
import android.content.Context
import io.sentry.Sentry
import io.sentry.SentryEvent
import io.sentry.SentryOptions
import io.sentry.transport.NoOpTransport
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], application = Application::class)
class NativeErrorReportingTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private val events = mutableListOf<SentryEvent>()

    @Before
    fun setUp() {
        context.getSharedPreferences("error_reporting", Context.MODE_PRIVATE).edit().clear().commit()
        Sentry.close()
        // No network, files or native crash handlers: inspect events at the
        // SDK boundary before they go into the no-op transport.
        Sentry.init { options ->
            options.dsn = "https://public@example.com/1"
            options.setTransportFactory(io.sentry.ITransportFactory { _, _ -> NoOpTransport.getInstance() })
            options.beforeSend = SentryOptions.BeforeSendCallback { event, _ ->
                NativeErrorReporting.filterEvent(context, event)?.also(events::add)
            }
        }
    }

    @After
    fun tearDown() {
        Sentry.close()
        context.getSharedPreferences("error_reporting", Context.MODE_PRIVATE).edit().clear().commit()
    }

    @Test
    fun missingConsentDisablesEvenAnAlreadyRunningSdk() {
        assertFalse(NativeErrorReporting.isAllowed(context))
        NativeErrorReporting.startIfAllowed(context)
        assertFalse(Sentry.isEnabled())
    }

    @Test
    fun malformedConsentDoesNotStartCrashHandling() {
        context.getSharedPreferences("error_reporting", Context.MODE_PRIVATE)
            .edit().putString("enabled", "true").commit()
        NativeErrorReporting.startIfAllowed(context)
        assertFalse(NativeErrorReporting.isAllowed(context))
        assertFalse(Sentry.isEnabled())
    }

    @Test
    fun handledWorkerFailuresRequireConsentAndKeepTheirOperationAndStack() {
        val error = IllegalStateException("test failure")
        NativeErrorReporting.failure(context, "media_preparation", error)
        assertTrue(events.isEmpty())

        NativeErrorReporting.setEnabled(context, true)
        NativeErrorReporting.failure(context, "media_preparation", error)
        assertEquals(1, events.size)
        assertEquals("media_preparation", events.single().getTag("native_operation"))
        assertEquals("IllegalStateException", events.single().exceptions!!.last().type)
        assertNull(events.single().exceptions!!.last().value)
        assertFalse(events.single().exceptions!!.last().stacktrace!!.frames!!.isEmpty())

        NativeErrorReporting.setEnabled(context, false)
        assertFalse(Sentry.isEnabled())
        assertFalse(NativeErrorReporting.isAllowed(context))
        NativeErrorReporting.failure(context, "notification_processing", error)
        assertEquals(1, events.size)
    }

    @Test
    fun rustFailureReportsOnlyTheOperation() {
        NativeErrorReporting.setEnabled(context, true)
        NativeErrorReporting.failure(context, "notification_processing")
        assertEquals("Native background operation failed: notification_processing", events.single().message!!.formatted)
        assertEquals("notification_processing", events.single().getTag("native_operation"))
    }
}
