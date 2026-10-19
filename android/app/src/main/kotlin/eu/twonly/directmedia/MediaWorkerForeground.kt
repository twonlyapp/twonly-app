package eu.twonly.directmedia

import android.app.ForegroundServiceStartNotAllowedException
import android.os.Build
import android.util.Log
import androidx.work.ForegroundInfo
import androidx.work.Worker
import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit

/** Foreground execution extends the worker's budget when Android permits it.
 * A background retry may be allowed to run as a job but forbidden to start a
 * foreground service. In that case keep doing the work within the normal
 * WorkManager budget; stopped uploads are cancelled by onStopped(). */
internal fun Worker.setForegroundWhenAllowed(info: ForegroundInfo) {
    try {
        setForegroundAsync(info).get(10, TimeUnit.SECONDS)
    } catch (error: Exception) {
        val cause = if (error is ExecutionException) error.cause else error
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            cause !is ForegroundServiceStartNotAllowedException) {
            throw error
        }
        Log.i("TwonlyMediaTransfer", "Foreground start restricted; continuing as background work")
    }
}
