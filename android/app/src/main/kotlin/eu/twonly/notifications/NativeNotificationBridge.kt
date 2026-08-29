package eu.twonly.notifications

internal object NativeNotificationBridge {
    init {
        System.loadLibrary("rust_lib_twonly")
    }

    @JvmStatic
    external fun process(
        databaseDirectory: String,
        dataDirectory: String,
        locale: String,
        deadlineMs: Long,
    ): String

    @JvmStatic
    external fun acknowledge(eventIdsJson: String): String

    @JvmStatic
    external fun storeFcmToken(
        databaseDirectory: String,
        dataDirectory: String,
        token: String,
    ): String
}
