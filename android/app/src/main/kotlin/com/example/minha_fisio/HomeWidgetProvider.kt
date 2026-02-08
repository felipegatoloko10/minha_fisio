package com.example.minha_fisio

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Mapeia os dados salvos no Flutter para os IDs do XML
                setTextViewText(R.id.widget_treatment, widgetData.getString("widget_treatment", "Tudo em dia!"))
                setTextViewText(R.id.widget_date_time, widgetData.getString("widget_date_time", "Nenhuma sessão pendente ✨"))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
