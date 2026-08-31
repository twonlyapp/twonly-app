package eu.twonly.notifications

import org.json.JSONObject

internal data class NativeNotificationPresentation(
    val title: String,
    val body: String,
)

internal data class NativeNotificationAddition(
    val eventId: String,
    val notificationId: String,
    val conversationId: String?,
    val kind: String,
    val senderId: Long,
    val senderName: String,
    val title: String,
    val body: String,
    val createdAt: Long,
    val avatarPath: String?,
)

internal data class NativeNotificationBatch(
    val additions: List<NativeNotificationAddition>,
    val removals: List<String>,
    val badgeCount: Long,
    val completed: Boolean,
)

internal data class NativeNotificationResponse(
    val ok: Boolean,
    val batch: NativeNotificationBatch?,
    val fallback: NativeNotificationPresentation?,
) {
    companion object {
        fun parse(json: String): NativeNotificationResponse {
            val root = JSONObject(json)
            val batchJson = root.optJSONObject("batch")
            val additions = batchJson?.optJSONArray("additions")?.let { array ->
                List(array.length()) { index ->
                    val item = array.getJSONObject(index)
                    NativeNotificationAddition(
                        eventId = item.getString("event_id"),
                        notificationId = item.getString("notification_id"),
                        conversationId = item.nullableString("conversation_id"),
                        kind = item.getString("kind"),
                        senderId = item.getLong("sender_id"),
                        senderName = item.getString("sender_name"),
                        title = item.getString("title"),
                        body = item.getString("body"),
                        createdAt = item.getLong("created_at"),
                        avatarPath = item.nullableString("avatar_path"),
                    )
                }
            }.orEmpty()
            val removals = batchJson?.optJSONArray("removals")?.let { array ->
                List(array.length()) { index -> array.getString(index) }
            }.orEmpty()
            val batch = batchJson?.let {
                NativeNotificationBatch(
                    additions = additions,
                    removals = removals,
                    badgeCount = it.optLong("badge_count"),
                    completed = it.optBoolean("completed"),
                )
            }
            val fallback = root.optJSONObject("fallback")?.let {
                NativeNotificationPresentation(
                    title = it.getString("title"),
                    body = it.getString("body"),
                )
            }
            return NativeNotificationResponse(root.optBoolean("ok"), batch, fallback)
        }
    }
}

private fun JSONObject.nullableString(key: String): String? =
    if (isNull(key)) null else optString(key).takeIf(String::isNotEmpty)
