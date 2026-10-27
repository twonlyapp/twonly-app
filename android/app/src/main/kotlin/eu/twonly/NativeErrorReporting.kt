package eu.twonly

import android.content.Context
import io.sentry.Breadcrumb
import io.sentry.Sentry
import io.sentry.SentryEvent
import io.sentry.SentryLevel
import io.sentry.SentryOptions
import io.sentry.android.core.SentryAndroid

/** Application startup also runs for FCM, WorkManager and location services. */
object NativeErrorReporting {
    private const val PREFERENCES = "error_reporting"
    private const val CONSENT = "enabled"
    private const val DSN = "https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4"

    fun isAllowed(context: Context): Boolean = try {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getBoolean(CONSENT, false)
    } catch (_: Exception) {
        false
    }

    @Synchronized
    fun setEnabled(context: Context, enabled: Boolean) {
        check(context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit().putBoolean(CONSENT, enabled).commit()) { "Could not save error reporting preference" }
        startIfAllowed(context)
    }

    @Synchronized
    fun startIfAllowed(context: Context) {
        val app = context.applicationContext
        if (!isAllowed(app)) {
            if (Sentry.isEnabled()) Sentry.close()
            return
        }
        if (Sentry.isEnabled()) return
        SentryAndroid.init(app) { options ->
            options.dsn = DSN
            options.environment = BuildConfig.BUILD_TYPE
            @Suppress("DEPRECATION")
            val info = app.packageManager.getPackageInfo(app.packageName, 0)
            options.release = "${app.packageName}@${info.versionName}+${androidx.core.content.pm.PackageInfoCompat.getLongVersionCode(info)}"
            options.dist = androidx.core.content.pm.PackageInfoCompat.getLongVersionCode(info).toString()
            options.isSendDefaultPii = false
            options.isEnableAutoSessionTracking = false
            options.isEnableNdk = true
            options.isEnableScopeSync = true
            options.setTag("native_component", "application")
            options.beforeSend = SentryOptions.BeforeSendCallback { event, _ ->
                filterEvent(app, event)
            }
        }
    }

    internal fun filterEvent(context: Context, event: SentryEvent): SentryEvent? {
        if (!isAllowed(context)) return null
        // Run after the SDK has extracted the throwable's exception chain.
        // JSONObject/SQLite messages can embed decrypted user data.
        if (event.getTag("native_operation") != null) {
            event.exceptions?.forEach { it.value = null }
        }
        return event
    }

    fun breadcrumb(context: Context, operation: String) {
        if (!isAllowed(context)) return
        Sentry.addBreadcrumb(Breadcrumb().apply {
            category = "native.background"
            message = operation
            level = SentryLevel.INFO
        })
    }

    fun failure(context: Context, operation: String, error: Throwable? = null) {
        if (!isAllowed(context)) return
        Sentry.withScope { scope ->
            scope.setTag("native_operation", operation)
            if (error != null) Sentry.captureException(error)
            else Sentry.captureMessage("Native background operation failed: $operation", SentryLevel.ERROR)
        }
    }

    /** Rust responses may contain SQL, paths or user data. Report only a fixed
     * category, and keep lifecycle cancellation as an ordinary retry. */
    fun rustFailure(context: Context, operation: String, error: String?) {
        if (!isAllowed(context)) return
        val reason = when (error) {
            "Database operation cancelled; retry when active",
            "Native database admission cancelled",
            "Notification run cancelled",
            "Notification run is closing" -> "cancelled"
            "attempted to acquire a connection on a closed pool" -> "database_pool_closed"
            "pool timed out while waiting for an open connection" -> "database_pool_timeout"
            "main_key could not be loaded from the key_chain",
            "Storage error: database exists but master key could not be loaded from secure storage" -> "secure_storage"
            "background maintenance panicked",
            "notification worker panicked",
            "notification finalization panicked" -> "panic"
            else -> "unknown"
        }
        if (reason == "cancelled") {
            breadcrumb(context, "${operation}_cancelled")
            return
        }
        Sentry.withScope { scope ->
            scope.setTag("native_operation", operation)
            scope.setTag("native_failure_reason", reason)
            scope.setFingerprint(listOf("native-background", operation, reason))
            Sentry.captureMessage("Native background operation failed: $operation ($reason)", SentryLevel.ERROR)
        }
    }
}
