package eu.twonly

import io.flutter.embedding.android.FlutterFragmentActivity
import android.view.KeyEvent
import dev.darttools.flutter_android_volume_keydown.FlutterAndroidVolumeKeydownPlugin.eventSink
import android.view.KeyEvent.KEYCODE_VOLUME_DOWN
import android.view.KeyEvent.KEYCODE_VOLUME_UP
import io.flutter.embedding.engine.FlutterEngine
import android.content.Context
import android.content.Intent
import io.crates.keyring.Keyring
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import android.os.Bundle
import android.net.Uri
import java.io.InputStream
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.PickVisualMediaRequest
import io.flutter.plugin.common.MethodChannel
import eu.twonly.notifications.NotificationTapChannel
import eu.twonly.webxdc.WebxdcChannel
import eu.twonly.widget.WidgetRuntimeChannel
import android.Manifest
import android.content.pm.PackageManager

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "eu.twonly/photo_picker"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingLocationPermissionResult: MethodChannel.Result? = null
    
    private lateinit var pickMultipleMedia: ActivityResultLauncher<PickVisualMediaRequest>
    private lateinit var requestLocationPermissions: ActivityResultLauncher<Array<String>>

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()

        // Buffer a notification tap before the Flutter engine exists so the
        // cold-start route is not lost.
        NotificationTapChannel.handleIntent(intent)
        
        pickMultipleMedia = registerForActivityResult(ActivityResultContracts.PickMultipleVisualMedia()) { uris ->
            if (uris.isNotEmpty()) {
                val uriStrings = uris.map { it.toString() }
                pendingResult?.success(uriStrings)
            } else {
                pendingResult?.success(emptyList<String>())
            }
            pendingResult = null
        }
        requestLocationPermissions = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions(),
        ) {
            pendingLocationPermissionResult?.success(
                checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED,
            )
            pendingLocationPermissionResult = null
        }
        
        super.onCreate(savedInstanceState)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // A running webxdc app is the only thing that opens a picker from here.
        if (eu.twonly.webxdc.WebxdcView.handleActivityResult(requestCode, resultCode, data)) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        NotificationTapChannel.handleIntent(intent)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (keyCode == KEYCODE_VOLUME_DOWN && eventSink != null) {
            eventSink!!.success(true)
            return true
        }
        if (keyCode == KEYCODE_VOLUME_UP && eventSink != null) {
            eventSink!!.success(false)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Keyring.initializeNdkContext(applicationContext)


        NotificationTapChannel.configure(flutterEngine, applicationContext)
        WidgetRuntimeChannel.configure(flutterEngine, applicationContext)
        WebxdcChannel.configure(flutterEngine, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImages" -> {
                    pendingResult = result
                    pickMultipleMedia.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
                "getUriBytes" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            val inputStream: InputStream? = contentResolver.openInputStream(uri)
                            if (inputStream != null) {
                                val bytes = inputStream.readBytes()
                                inputStream.close()
                                result.success(bytes)
                            } else {
                                result.error("UNAVAILABLE", "Could not open InputStream", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI string is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "eu.twonly/location_metadata",
        ).setMethodCallHandler { call, result ->
            if (call.method != "requestPrecisePermission") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                result.success(true)
            } else if (pendingLocationPermissionResult != null) {
                result.error("request_in_progress", "A location permission request is already open.", null)
            } else {
                pendingLocationPermissionResult = result
                requestLocationPermissions.launch(
                    arrayOf(
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                        Manifest.permission.ACCESS_FINE_LOCATION,
                    ),
                )
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        NotificationTapChannel.detach()
        WidgetRuntimeChannel.detach()
        WebxdcChannel.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
