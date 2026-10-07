package eu.twonly.location

import android.Manifest
import android.content.Context
import android.content.Intent
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.test.filters.SdkSuppress
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/** Run on an emulator: the mock providers are removed after every test. */
@SdkSuppress(minSdkVersion = 31)
class NativeLocationTest {
    companion object {
        private var activityStarted = false
    }
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val providers = listOf("fused", LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)

    @Before
    fun setUp() {
        instrumentation.uiAutomation.grantRuntimePermission(context.packageName, Manifest.permission.ACCESS_COARSE_LOCATION)
        instrumentation.uiAutomation.grantRuntimePermission(context.packageName, Manifest.permission.ACCESS_FINE_LOCATION)
        if (!activityStarted) {
            instrumentation.startActivitySync(
                Intent(context, LocationTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            activityStarted = true
        }
        instrumentation.uiAutomation.executeShellCommand(
            "appops set ${context.packageName} android:mock_location allow",
        ).use { android.os.ParcelFileDescriptor.AutoCloseInputStream(it).readBytes() }
        for (provider in providers) {
            @Suppress("DEPRECATION")
            manager.addTestProvider(provider, false, false, false, false, true, true, true,
                Criteria.POWER_LOW, Criteria.ACCURACY_FINE)
            manager.setTestProviderEnabled(provider, true)
        }
    }

    @After
    fun tearDown() {
        for (provider in providers) {
            runCatching { manager.removeTestProvider(provider) }
        }
        instrumentation.uiAutomation.executeShellCommand(
            "appops set ${context.packageName} android:mock_location default",
        ).use { android.os.ParcelFileDescriptor.AutoCloseInputStream(it).readBytes() }
    }

    private fun fix(provider: String, ageMillis: Long = 0, accuracyMeters: Float = 10f): Location =
        Location(provider).apply {
            latitude = 52.52
            longitude = 13.405
            accuracy = accuracyMeters
            time = System.currentTimeMillis() - ageMillis
            elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos() - ageMillis * 1_000_000
        }

    private fun assertFix(value: String?) {
        assertNotNull("A recent precise fix should be returned", value)
        val result = JSONArray(value!!)
        assertEquals(52.52, result.getDouble(0), 0.000001)
        assertEquals(13.405, result.getDouble(1), 0.000001)
        assertEquals(10.0, result.getDouble(2), 0.000001)
    }

    @Test
    fun recentGpsFixIsReturnedWithoutWaitingForAnUpdate() {
        manager.setTestProviderLocation(LocationManager.GPS_PROVIDER, fix(LocationManager.GPS_PROVIDER))
        assertFix(NativeLocation.current(500))
    }

    @Test
    fun recentFusedFixIsReturnedWithoutWaitingForGps() {
        manager.setTestProviderLocation("fused", fix("fused"))
        assertFix(NativeLocation.current(500))
    }

    @Test
    fun staleCachedFixIsNotStoredAsTheCaptureLocation() {
        manager.setTestProviderLocation(LocationManager.GPS_PROVIDER, fix(LocationManager.GPS_PROVIDER, 240_000))
        assertNull(NativeLocation.current(200))
    }

    @Test
    fun liveFusedUpdateIsUsedWhenThereIsNoCachedFix() {
        manager.setTestProviderEnabled(LocationManager.GPS_PROVIDER, false)
        manager.setTestProviderEnabled(LocationManager.NETWORK_PROVIDER, false)
        Handler(Looper.getMainLooper()).postDelayed({
            manager.setTestProviderLocation("fused", fix("fused"))
        }, 100)
        assertFix(NativeLocation.current(2_000))
    }

    @Test
    fun bestAvailableFixIsReturnedAtTheDeadline() {
        manager.setTestProviderLocation(LocationManager.NETWORK_PROVIDER,
            fix(LocationManager.NETWORK_PROVIDER, accuracyMeters = 100f))
        val value = NativeLocation.current(200)
        assertNotNull(value)
        assertEquals(100.0, JSONArray(value!!).getDouble(2), 0.000001)
    }

    @Test
    fun disabledProvidersReturnWithoutARequest() {
        for (provider in providers) manager.setTestProviderEnabled(provider, false)
        assertNull(NativeLocation.current(200))
    }
}
