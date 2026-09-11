package eu.twonly.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import eu.twonly.MyApplication
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** One-shot precise location lookup called synchronously by Rust/JNI. */
object NativeLocation {
    private const val TARGET_ACCURACY_METERS = 50f

    @JvmStatic
    @SuppressLint("MissingPermission")
    fun current(timeoutMillis: Long): String? {
        val context = MyApplication.instance
        if (context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return null
        }
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return null
        val finished = CountDownLatch(1)
        val best = AtomicReference<Location?>(null)
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                if (location.accuracy < 0) return
                val previous = best.get()
                if (previous == null || location.accuracy < previous.accuracy) best.set(location)
                if (location.accuracy <= TARGET_ACCURACY_METERS) finished.countDown()
            }

            @Deprecated("Deprecated in Android")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
        }
        val main = Handler(Looper.getMainLooper())
        main.post {
            var requested = false
            for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
                if (!runCatching { manager.isProviderEnabled(provider) }.getOrDefault(false)) continue
                runCatching {
                    manager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
                    requested = true
                }
            }
            if (!requested) finished.countDown()
        }
        finished.await(timeoutMillis.coerceAtLeast(0), TimeUnit.MILLISECONDS)
        main.post { runCatching { manager.removeUpdates(listener) } }
        val location = best.get() ?: return null
        return "[${location.latitude},${location.longitude},${location.accuracy}]"
    }
}
