package eu.twonly.directmedia

/** Rust entry point for work the platform's schedulers drive: preparing one
 * media file for upload, or flushing everything a terminated process left
 * behind. Neither needs a Flutter engine. */
internal object NativeMediaPrepareBridge {
    init {
        System.loadLibrary("rust_lib_twonly")
    }

    /** A null [mediaId] runs the full flush instead of one preparation.
     * Returns `{"ok":bool,"error":string?}`. */
    @JvmStatic
    external fun run(
        databaseDirectory: String,
        dataDirectory: String,
        mediaId: String?,
    ): String
}
