package eu.twonly.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import eu.twonly.R
import java.io.File
import org.json.JSONObject

class TwonlyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val preferences = preferences(context)
        appWidgetIds.forEach { id -> preferences.edit().remove(groupsKey(id)).apply() }
        TwonlyWidgetConfigureActivity.persistNativeConfiguration(context)
    }

    companion object {
        private const val PREFERENCES = "twonly_home_widgets"

        fun preferences(context: Context) = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        fun groupsKey(widgetId: Int) = "groups_$widgetId"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TwonlyWidgetProvider::class.java))
            ids.forEach { update(context, manager, it) }
        }

        /**
         * Draws the one image this widget has: the most recent one the app
         * published for any of its contact groups. The app keeps a single image
         * per group and deletes the one it replaces, so the manifest — written
         * newest first — offers nothing else to fall back on.
         */
        fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.twonly_widget)
            val selected = preferences(context).getStringSet(groupsKey(widgetId), emptySet()).orEmpty()
            val manifestFile = File(context.filesDir, "widget/manifest.json")
            val image = runCatching {
                val images = JSONObject(manifestFile.readText()).getJSONArray("images")
                (0 until images.length())
                    .map { images.getJSONObject(it) }
                    .firstOrNull { candidate ->
                        val groups = candidate.getJSONArray("group_ids")
                        (0 until groups.length()).any { selected.contains(groups.getLong(it).toString()) }
                    }
            }.getOrNull()

            val bitmap = image?.let { BitmapFactory.decodeFile(it.getString("path")) }
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

            // Nothing to rotate through any more, so a tap opens twonly.
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                views.setOnClickPendingIntent(
                    R.id.twonly_widget_root,
                    PendingIntent.getActivity(
                        context,
                        widgetId,
                        launch,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
            }
            manager.updateAppWidget(widgetId, views)
        }
    }
}
