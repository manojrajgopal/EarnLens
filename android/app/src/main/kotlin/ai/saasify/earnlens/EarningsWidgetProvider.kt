package ai.saasify.earnlens

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.text.format.DateFormat
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Date

/**
 * Home-screen widget showing money earned this month.
 *
 * The widget cannot run the Dart calculation engine, so the app stores exact
 * values for 30-minute checkpoints over the next 24 hours. Each refresh picks
 * the latest checkpoint at or before now and shows its time, so the widget is
 * honest about when the value applies. Android limits widget refreshes to
 * about every 30 minutes; the in-app counter updates every second.
 */
class EarningsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        val title = widgetData.getString("el_title", null) ?: "EarnLens"
        val hidden = widgetData.getBoolean("el_hidden", false)
        val rate = widgetData.getString("el_rate", null)
        val checkpoint = latestCheckpoint(widgetData.getString("el_checkpoints", null), now)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.earnings_widget)
            views.setTextViewText(R.id.widget_title, title)
            when {
                checkpoint == null -> {
                    views.setTextViewText(R.id.widget_value, "—")
                    views.setTextViewText(R.id.widget_caption, "Open EarnLens to refresh")
                    views.setTextViewText(R.id.widget_rate, "")
                }
                hidden -> {
                    views.setTextViewText(R.id.widget_value, "••••••")
                    views.setTextViewText(R.id.widget_caption, "Amounts hidden")
                    views.setTextViewText(R.id.widget_rate, "")
                }
                else -> {
                    val time = DateFormat.getTimeFormat(context).format(Date(checkpoint.first))
                    views.setTextViewText(R.id.widget_value, checkpoint.second)
                    views.setTextViewText(R.id.widget_caption, "Estimate as of $time")
                    views.setTextViewText(R.id.widget_rate, rate ?: "")
                }
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun latestCheckpoint(json: String?, now: Long): Pair<Long, String>? {
        if (json == null) return null
        return try {
            val arr = JSONArray(json)
            var best: Pair<Long, String>? = null
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val t = o.getLong("t")
                if (t <= now) best = Pair(t, o.getString("v"))
            }
            best
        } catch (e: Exception) {
            null
        }
    }
}
