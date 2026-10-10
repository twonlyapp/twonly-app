package eu.twonly.location

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import eu.twonly.MainActivity
import eu.twonly.R
import org.json.JSONObject
import org.json.JSONArray
import java.util.concurrent.Executors

internal object NativeLiveLocationBridge {
    init { System.loadLibrary("rust_lib_twonly") }
    @JvmStatic external fun run(directory: String, request: String): String
}

/** Location collection and encrypted delivery survive dismissal of the Flutter activity. */
class LiveLocationService : Service(), LocationListener {
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var manager: LocationManager? = null
    private var latest: Location? = null
    private var sessionId: String? = null
    private var expiresAt = 0L
    private var stopping = false
    private var busy = false
    private var lastTickAt = 0L
    private val tick = object : Runnable {
        override fun run() {
            if (stopping) return
            if (System.currentTimeMillis() >= expiresAt || !NativeLocation.hasPrecisePermission()) {
                finishSharing()
                return
            }
            if (!busy) {
                busy = true
                lastTickAt = System.currentTimeMillis()
                val id = sessionId
                val fix = latest?.takeIf {
                    System.currentTimeMillis() - it.time in 0..120_000 && it.hasAccuracy()
                }
                val request = JSONObject().put("action", "update").put("session_id", id)
                if (fix != null) request.put("fix", JSONArray(listOf(fix.latitude, fix.longitude, fix.accuracy.toDouble(), fix.time)))
                worker.execute {
                    val response = runCatching { JSONObject(NativeLiveLocationBridge.run(filesDir.absolutePath, request.toString())) }.getOrNull()
                    main.post {
                        busy = false
                        if (sessionId == id && !stopping && response?.optBoolean("ok") == true && response.isNull("session")) finishSharing()
                    }
                }
            }
            main.postDelayed(this, 30_000)
        }
    }
    private val expire = Runnable { finishSharing() }

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("MissingPermission")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val preferences = getSharedPreferences(PREFERENCES, MODE_PRIVATE)
        if (intent?.action == STOP) {
            val expected = intent.getStringExtra("session_id")
            if (sessionId == null) sessionId = preferences.getString("session_id", null)
            if (expected != null && expected == sessionId) finishSharing()
            else if (sessionId == null) stopSelf(startId)
            return START_NOT_STICKY
        }
        val id = intent?.getStringExtra("session_id") ?: preferences.getString("session_id", null)
        val deadline = intent?.getLongExtra("expires_at_ms", 0) ?: preferences.getLong("expires_at_ms", 0)
        if (id == null || deadline <= System.currentTimeMillis() || !NativeLocation.hasPrecisePermission()) {
            sessionId = id
            finishSharing()
            return START_NOT_STICKY
        }
        if (sessionId == id && expiresAt == deadline && !stopping) return START_STICKY
        runCatching { manager?.removeUpdates(this) }
        sessionId = id
        expiresAt = deadline
        stopping = false
        lastTickAt = 0
        val title = intent?.getStringExtra("title") ?: preferences.getString("title", "Sharing live location")!!
        val body = intent?.getStringExtra("body") ?: preferences.getString("body", "Your current location is being shared")!!
        val stop = intent?.getStringExtra("stop") ?: preferences.getString("stop", "Stop sharing")!!
        preferences.edit().putString("session_id", id).putLong("expires_at_ms", deadline)
            .putString("title", title).putString("body", body).putString("stop", stop).commit()
        val notifications = getSystemService(NotificationManager::class.java)
        notifications.createNotificationChannel(NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_LOW))
        val stopIntent = Intent(this, LiveLocationService::class.java).setAction(STOP).putExtra("session_id", id)
        val stopAction = PendingIntent.getService(this, 7301, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val open = PendingIntent.getActivity(this, 7302, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_launcher_foreground).setContentTitle(title).setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body)).setOngoing(true).setOnlyAlertOnce(true)
            .setContentIntent(open).addAction(0, stop, stopAction).build()
        ServiceCompat.startForeground(this, NOTIFICATION, notification,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else 0)
        manager = getSystemService(LocationManager::class.java)
        for (provider in NativeLocation.enabledProviders(manager!!)) {
            runCatching {
                manager?.getLastKnownLocation(provider)?.let(::onLocationChanged)
                manager?.requestLocationUpdates(provider, 30_000, 0f, this, Looper.getMainLooper())
            }
        }
        main.removeCallbacks(tick)
        main.post(tick)
        main.removeCallbacks(expire)
        main.postDelayed(expire, (deadline - System.currentTimeMillis()).coerceAtLeast(0))
        return START_STICKY
    }

    override fun onLocationChanged(location: Location) {
        if (!stopping && location.hasAccuracy() && location.accuracy.isFinite() && location.accuracy >= 0) {
            if (latest == null || location.time >= latest!!.time) latest = Location(location)
            // Location callbacks also drive the cadence while the display is
            // off, without holding a wake lock for the entire sharing period.
            if (!busy && System.currentTimeMillis() - lastTickAt >= 30_000) {
                main.removeCallbacks(tick)
                main.post(tick)
            }
        }
    }

    private fun finishSharing() {
        if (stopping) return
        stopping = true
        main.removeCallbacks(tick)
        main.removeCallbacks(expire)
        runCatching { manager?.removeUpdates(this) }
        latest = null
        getSharedPreferences(PREFERENCES, MODE_PRIVATE).edit().clear().commit()
        val id = sessionId
        worker.execute {
            if (id != null) runCatching {
                NativeLiveLocationBridge.run(filesDir.absolutePath,
                    JSONObject().put("action", "stop").put("session_id", id).toString())
            }
            main.post {
                // Starting a new session may overtake this asynchronous stop.
                if (sessionId == id && stopping) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
        }
    }

    override fun onDestroy() {
        main.removeCallbacksAndMessages(null)
        runCatching { manager?.removeUpdates(this) }
        latest = null
        worker.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "twonly_live_location"
        private const val NOTIFICATION = 0x747730
        private const val PREFERENCES = "live_location_service"
        private const val STOP = "eu.twonly.STOP_LIVE_LOCATION"
        fun start(context: Context, arguments: Map<*, *>) {
            check(NativeLocation.hasPrecisePermission()) { "Location permission is unavailable" }
            if (Build.VERSION.SDK_INT >= 33) check(context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
            val intent = Intent(context, LiveLocationService::class.java)
                .putExtra("session_id", arguments["session_id"] as String)
                .putExtra("expires_at_ms", (arguments["expires_at_ms"] as Number).toLong())
            for (key in listOf("title", "body", "stop")) intent.putExtra(key, arguments[key] as? String)
            context.startForegroundService(intent)
        }
        fun stop(context: Context, sessionId: String) {
            context.startService(Intent(context, LiveLocationService::class.java).setAction(STOP).putExtra("session_id", sessionId))
        }
    }
}
