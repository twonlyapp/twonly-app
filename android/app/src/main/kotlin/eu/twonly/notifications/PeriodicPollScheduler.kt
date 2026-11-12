package eu.twonly.notifications

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.Operation
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/** Device-local opt-in, readable when Android starts the process without Flutter. */
object PeriodicPollScheduler {
    const val UNIQUE_WORK_NAME = "twonly-periodic-poll"
    const val INTERVAL_MINUTES = 15L
    private const val PREFERENCES = "twonly_periodic_poll"
    private const val ENABLED = "enabled"

    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getBoolean(ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean): Operation {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit().putBoolean(ENABLED, enabled).apply()
        return ensureScheduled(context)
    }

    fun ensureScheduled(context: Context): Operation {
        val manager = WorkManager.getInstance(context)
        if (!isEnabled(context)) return manager.cancelUniqueWork(UNIQUE_WORK_NAME)
        val request = PeriodicWorkRequestBuilder<TwonlyNotificationWorker>(INTERVAL_MINUTES, TimeUnit.MINUTES)
            .setInitialDelay(INTERVAL_MINUTES, TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build())
            .build()
        // UPDATE preserves the original enqueue time when the process restarts.
        return manager.enqueueUniquePeriodicWork(UNIQUE_WORK_NAME, ExistingPeriodicWorkPolicy.UPDATE, request)
    }
}
