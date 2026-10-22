package eu.twonly.notifications

internal object NativeNotificationBridge {
    init {
        System.loadLibrary("rust_lib_twonly")
    }

    @JvmStatic
    external fun logPushReceived(dataDirectory: String, messageId: String, sentAtMs: Long)

    @JvmStatic
    external fun setApplicationActive(active: Boolean)

    @JvmStatic
    external fun createRun(budgetMs: Long): Long

    @JvmStatic
    external fun cancelRun(run: Long)

    @JvmStatic
    external fun finishRun(run: Long)

    @JvmStatic
    external fun processWithId(
        run: Long,
        databaseDirectory: String,
        dataDirectory: String,
        locale: String,
        deadlineMs: Long,
    ): String

    @JvmStatic
    external fun acknowledge(run: Long, eventIdsJson: String): String

    @JvmStatic
    external fun finalizeWakeup(run: Long, deadlineMs: Long): String

    @JvmStatic
    external fun storeFcmToken(
        databaseDirectory: String,
        dataDirectory: String,
        token: String,
    ): String
}
