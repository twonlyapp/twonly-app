package eu.twonly.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.google.android.material.appbar.AppBarLayout
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.checkbox.MaterialCheckBox
import eu.twonly.R
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class TwonlyWidgetConfigureActivity : AppCompatActivity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        widgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.twonly_widget_configure)
        applySystemBarInsets()

        findViewById<MaterialToolbar>(R.id.toolbar).setNavigationOnClickListener { finish() }

        val groupCard = findViewById<MaterialCardView>(R.id.group_card)
        val groupList = findViewById<LinearLayout>(R.id.group_list)
        val emptyState = findViewById<View>(R.id.empty_state)
        val saveButton = findViewById<MaterialButton>(R.id.save_button)

        val preferences = TwonlyWidgetProvider.preferences(this)
        val selected = preferences
            .getStringSet(TwonlyWidgetProvider.groupsKey(widgetId), emptySet())
            .orEmpty()
            .toMutableSet()
        val selectedContacts = preferences
            .getStringSet(TwonlyWidgetProvider.contactsKey(widgetId), emptySet())
            .orEmpty().toMutableSet()
        val manifest = runCatching {
            JSONObject(File(filesDir, "widget/manifest.json").readText())
        }.getOrNull()
        val groups = manifest?.optJSONArray("groups") ?: JSONArray()
        val contacts = manifest?.optJSONArray("contacts") ?: JSONArray()

        if (groups.length() == 0 && contacts.length() == 0) {
            groupCard.visibility = View.GONE
            emptyState.visibility = View.VISIBLE
            saveButton.isEnabled = false
        } else {
            val inflater = LayoutInflater.from(this)
            fun addChoices(items: JSONArray, selection: MutableSet<String>, title: Int) {
                val available = (0 until items.length()).map { items.getJSONObject(it).getLong("id").toString() }.toSet()
                selection.retainAll(available)
                if (items.length() == 0) return
                val heading = inflater.inflate(R.layout.twonly_widget_configure_heading, groupList, false)
                    as android.widget.TextView
                heading.setText(title)
                groupList.addView(heading)
                for (index in 0 until items.length()) {
                    val item = items.getJSONObject(index)
                    val id = item.getLong("id").toString()
                    val checkBox = inflater.inflate(
                        R.layout.twonly_widget_configure_group, groupList, false,
                    ) as MaterialCheckBox
                    checkBox.text = item.getString("name")
                    checkBox.isChecked = selection.contains(id)
                    checkBox.setOnCheckedChangeListener { _, checked ->
                        if (checked) selection.add(id) else selection.remove(id)
                        saveButton.isEnabled = selected.isNotEmpty() || selectedContacts.isNotEmpty()
                    }
                    groupList.addView(checkBox)
                }
            }
            addChoices(contacts, selectedContacts, R.string.widget_people)
            addChoices(groups, selected, R.string.widget_contact_groups)
            saveButton.isEnabled = selected.isNotEmpty() || selectedContacts.isNotEmpty()
        }

        saveButton.setOnClickListener {
            preferences.edit()
                .putStringSet(TwonlyWidgetProvider.groupsKey(widgetId), selected)
                .putStringSet(TwonlyWidgetProvider.contactsKey(widgetId), selectedContacts)
                .apply()
            persistNativeConfiguration(this)
            TwonlyWidgetProvider.update(this, AppWidgetManager.getInstance(this), widgetId)
            setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
            finish()
        }
    }

    /**
     * The window draws edge to edge, so the system bars are kept clear by the
     * views that touch them: the top app bar and the bottom action bar.
     */
    private fun applySystemBarInsets() {
        val root = findViewById<ViewGroup>(R.id.root)
        val appBar = findViewById<AppBarLayout>(R.id.app_bar)
        val actionBar = findViewById<View>(R.id.action_bar)
        val appBarPaddingTop = appBar.paddingTop
        val actionBarPaddingBottom = actionBar.paddingBottom
        ViewCompat.setOnApplyWindowInsetsListener(root) { target, windowInsets ->
            val bars = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout(),
            )
            target.setPadding(bars.left, 0, bars.right, 0)
            appBar.updatePaddingTop(appBarPaddingTop + bars.top)
            actionBar.updatePaddingBottom(actionBarPaddingBottom + bars.bottom)
            windowInsets
        }
        ViewCompat.requestApplyInsets(root)
    }

    private fun View.updatePaddingTop(top: Int) =
        setPadding(paddingLeft, top, paddingRight, paddingBottom)

    private fun View.updatePaddingBottom(bottom: Int) =
        setPadding(paddingLeft, paddingTop, paddingRight, bottom)

    companion object {
        fun persistNativeConfiguration(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(android.content.ComponentName(context, TwonlyWidgetProvider::class.java))
            val widgets = JSONArray()
            val preferences = TwonlyWidgetProvider.preferences(context)
            ids.forEach { id ->
                val groups = JSONArray()
                preferences.getStringSet(TwonlyWidgetProvider.groupsKey(id), emptySet()).orEmpty()
                    .mapNotNull(String::toLongOrNull).forEach(groups::put)
                val contacts = JSONArray()
                preferences.getStringSet(TwonlyWidgetProvider.contactsKey(id), emptySet()).orEmpty()
                    .mapNotNull(String::toLongOrNull).forEach(contacts::put)
                widgets.put(JSONObject().put("id", "android:$id").put("platform", "android")
                    .put("group_ids", groups).put("contact_ids", contacts))
            }
            val directory = File(context.filesDir, "widget").apply { mkdirs() }
            val temporary = File(directory, "native-config.json.tmp")
            temporary.writeText(JSONObject().put("widgets", widgets).toString())
            temporary.renameTo(File(directory, "native-config.json"))
        }
    }
}
