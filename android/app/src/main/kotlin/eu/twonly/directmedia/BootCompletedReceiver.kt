package eu.twonly.directmedia

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * A reboot clears the periodic flush, and a phone that was rebooted with unsent
 * messages would otherwise wait for the user to open the app. Registering again
 * here is what makes "it sends as soon as you are online" true across a
 * restart.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        DirectMediaPrepare.ensurePeriodicFlush()
        DirectMediaPrepare.flushNow()
    }
}
