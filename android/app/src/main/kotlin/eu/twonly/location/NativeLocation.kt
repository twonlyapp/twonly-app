package eu.twonly.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import eu.twonly.MyApplication
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/** One-shot precise location lookup called synchronously by Rust/JNI. */
object NativeLocation {
    private const val TAG = "TwonlyLocation"
    private const val TARGET_ACCURACY_METERS = 50f
    private const val MAX_FIX_AGE_NANOS = 180_000_000_000L

    @JvmStatic
    @SuppressLint("MissingPermission")
    fun current(timeoutMillis: Long): String? {
        val context = MyApplication.instance
        if (context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "Memory location skipped: precise location permission is missing")
            return null
        }
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return null
        val finished = CountDownLatch(1)
        val best = AtomicReference<Location?>(null)
        val stopped = AtomicBoolean(false)
        fun accept(location: Location) {
            val age = SystemClock.elapsedRealtimeNanos() - location.elapsedRealtimeNanos
            if (stopped.get() || !location.hasAccuracy() || !location.accuracy.isFinite() ||
                location.accuracy < 0 || age !in 0..MAX_FIX_AGE_NANOS) return
            val previous = best.get()
            if (previous == null || location.accuracy < previous.accuracy) best.set(Location(location))
            if (location.accuracy <= TARGET_ACCURACY_METERS) finished.countDown()
        }
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                accept(location)
            }

            @Deprecated("Deprecated in Android")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
        }
        val main = Handler(Looper.getMainLooper())
        val start = Runnable {
            if (stopped.get()) return@Runnable
            val providers = buildList {
                // The fused provider may have a fix even when GPS cannot get
                // a signal and the separate network provider is unavailable.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
                add(LocationManager.GPS_PROVIDER)
                add(LocationManager.NETWORK_PROVIDER)
            }.filter { runCatching { manager.isProviderEnabled(it) }.getOrDefault(false) }
            for (provider in providers) {
                runCatching { manager.getLastKnownLocation(provider) }
                    .onSuccess { location -> location?.let(::accept) }
                    .onFailure { Log.w(TAG, "Could not read cached $provider location", it) }
            }
            if (finished.count == 0L) return@Runnable
            var requested = false
            for (provider in providers) {
                runCatching {
                    manager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
                    requested = true
                    Log.d(TAG, "Requested Memory location from $provider")
                }.onFailure { Log.w(TAG, "Could not request $provider location", it) }
            }
            if (!requested) {
                Log.w(TAG, "Memory location unavailable: no provider accepted the request")
                finished.countDown()
            }
        }
        main.post(start)
        try {
            finished.await(timeoutMillis.coerceAtLeast(0), TimeUnit.MILLISECONDS)
        } finally {
            stopped.set(true)
            main.removeCallbacks(start)
            main.post { runCatching { manager.removeUpdates(listener) } }
        }
        val location = best.get() ?: return null
        return "[${location.latitude},${location.longitude},${location.accuracy}]"
    }
}
