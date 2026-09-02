package eu.twonly.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import eu.twonly.R
import java.io.File
import org.json.JSONObject

class TwonlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it, advance = true) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_ADVANCE) return
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            update(context, AppWidgetManager.getInstance(context), widgetId, advance = true)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val preferences = preferences(context)
        appWidgetIds.forEach { id ->
            preferences.edit().remove(groupsKey(id)).remove(indexKey(id)).remove(newestKey(id)).apply()
        }
        TwonlyWidgetConfigureActivity.persistNativeConfiguration(context)
    }

    companion object {
        const val ACTION_ADVANCE = "eu.twonly.widget.ADVANCE"
        private const val PREFERENCES = "twonly_home_widgets"

        fun preferences(context: Context) = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        fun groupsKey(widgetId: Int) = "groups_$widgetId"
        private fun indexKey(widgetId: Int) = "index_$widgetId"

        /** The newest image this widget has already drawn. */
        private fun newestKey(widgetId: Int) = "newest_$widgetId"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TwonlyWidgetProvider::class.java))
            ids.forEach { update(context, manager, it, advance = false) }
        }

        fun update(context: Context, manager: AppWidgetManager, widgetId: Int, advance: Boolean) {
            val views = RemoteViews(context.packageName, R.layout.twonly_widget)
            val selected = preferences(context).getStringSet(groupsKey(widgetId), emptySet()).orEmpty()
            val manifestFile = File(context.filesDir, "widget/manifest.json")
            val matching = runCatching {
                val images = JSONObject(manifestFile.readText()).getJSONArray("images")
                buildList {
                    for (index in 0 until images.length()) {
                        val image = images.getJSONObject(index)
                        val groups = image.getJSONArray("group_ids")
                        val visible = (0 until groups.length()).any { selected.contains(groups.getLong(it).toString()) }
                        if (visible && image.optLong("expires_at") > System.currentTimeMillis() / 1000) add(image)
                    }
                }
            }.getOrDefault(emptyList())

            if (matching.isEmpty()) {
                views.setImageViewResource(R.id.twonly_widget_image, R.drawable.logo)
                views.setInt(R.id.twonly_widget_image, "setImageAlpha", 110)
                views.setViewVisibility(R.id.twonly_widget_sender, View.GONE)
            } else {
                // The manifest is newest first, so an arriving image is prepended
                // and the stored index keeps pointing at an older one: a redraw
                // alone would never show what just came in. Remembering which
                // image was newest last time is what separates an arrival from
                // every other reason this widget is asked to redraw, and an
                // arrival outranks the rotation — including a tap that has not
                // seen the new image yet.
                val preferences = preferences(context)
                val newest = matching[0].optString("media_id")
                val hasArrived = preferences.getString(newestKey(widgetId), null) != newest
                val oldIndex = preferences.getInt(indexKey(widgetId), -1)
                val index = when {
                    hasArrived -> 0
                    advance -> (oldIndex + 1).mod(matching.size)
                    else -> oldIndex.coerceAtLeast(0).mod(matching.size)
                }
                preferences.edit().putInt(indexKey(widgetId), index).putString(newestKey(widgetId), newest).apply()
                val image = matching[index]
                val bitmap = BitmapFactory.decodeFile(image.getString("path"))
                if (bitmap == null) {
                    views.setImageViewResource(R.id.twonly_widget_image, R.drawable.logo)
                    views.setInt(R.id.twonly_widget_image, "setImageAlpha", 110)
                    views.setViewVisibility(R.id.twonly_widget_sender, View.GONE)
                } else {
                    views.setImageViewBitmap(R.id.twonly_widget_image, bitmap)
                    views.setInt(R.id.twonly_widget_image, "setImageAlpha", 255)
                    views.setTextViewText(R.id.twonly_widget_sender, image.optString("sender"))
                    views.setViewVisibility(R.id.twonly_widget_sender, View.VISIBLE)
                }
            }

            val intent = Intent(context, TwonlyWidgetProvider::class.java).apply {
                action = ACTION_ADVANCE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            views.setOnClickPendingIntent(
                R.id.twonly_widget_root,
                PendingIntent.getBroadcast(
                    context,
                    widgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            manager.updateAppWidget(widgetId, views)
        }
    }
}
