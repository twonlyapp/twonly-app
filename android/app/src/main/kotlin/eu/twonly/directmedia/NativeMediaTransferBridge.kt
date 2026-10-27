package eu.twonly.directmedia

import android.util.Log

/** Records transport timings in the exported Rust log and wakes foreground
 * reconciliation. The callback is a hint; server state still decides success. */
internal object NativeMediaTransferBridge {
    fun finished(
        directory: String, attachmentId: String, role: String,
        queuedMs: Long, workerMs: Long, httpMs: Long, status: Int, attempt: Int,
    ) {
        try {
            System.loadLibrary("rust_lib_twonly")
            report(directory, attachmentId, role, queuedMs, workerMs, httpMs, status, attempt)
        } catch (error: LinkageError) {
            // Logging must never turn an accepted upload into a retry.
            Log.w("TwonlyMediaTransfer", "Native transfer callback unavailable", error)
        }
    }

    @JvmStatic
    private external fun report(
        directory: String, attachmentId: String, role: String,
        queuedMs: Long, workerMs: Long, httpMs: Long, status: Int, attempt: Int,
    )
}
