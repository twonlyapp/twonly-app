package eu.twonly.notifications

import android.app.Application
import android.content.Context
import androidx.work.Configuration
import androidx.work.NetworkType
import androidx.work.WorkInfo
import androidx.work.WorkManager
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
class PeriodicPollSchedulerTest {
    @Test
    fun optInPersistsAndReservesOneNetworkConstrainedJobUntilDisabled() {
        val context: Context = RuntimeEnvironment.getApplication()
        WorkManager.initialize(context, Configuration.Builder().build())
        val manager = WorkManager.getInstance(context)
        fun work() = manager.getWorkInfosForUniqueWork(PeriodicPollScheduler.UNIQUE_WORK_NAME)
            .get(5, TimeUnit.SECONDS).filter { !it.state.isFinished }

        assertFalse(PeriodicPollScheduler.isEnabled(context))
        PeriodicPollScheduler.ensureScheduled(context).result.get(5, TimeUnit.SECONDS)
        assertTrue(work().isEmpty())

        PeriodicPollScheduler.setEnabled(context, true).result.get(5, TimeUnit.SECONDS)
        val original = work().single()
        assertTrue(original.tags.contains(TwonlyNotificationWorker::class.java.name))
        assertEquals(TimeUnit.MINUTES.toMillis(15), original.periodicityInfo!!.repeatIntervalMillis)
        assertEquals(NetworkType.CONNECTED, original.constraints.requiredNetworkType)

        // A new Context represents startup reading the device preference again.
        val restarted = context.createPackageContext(context.packageName, 0)
        assertTrue(PeriodicPollScheduler.isEnabled(restarted))
        PeriodicPollScheduler.ensureScheduled(restarted).result.get(5, TimeUnit.SECONDS)
        val updated = work().single()
        assertEquals(original.id, updated.id)
        assertEquals(original.nextScheduleTimeMillis, updated.nextScheduleTimeMillis)

        PeriodicPollScheduler.setEnabled(context, false).result.get(5, TimeUnit.SECONDS)
        assertFalse(PeriodicPollScheduler.isEnabled(restarted))
        assertTrue(work().isEmpty())
        assertEquals(WorkInfo.State.CANCELLED,
            manager.getWorkInfoById(original.id).get(5, TimeUnit.SECONDS)!!.state)
        PeriodicPollScheduler.ensureScheduled(restarted).result.get(5, TimeUnit.SECONDS)
        assertTrue(work().isEmpty())
    }
}
