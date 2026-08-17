package com.example.rainy.widget.providers

import android.content.Context
import android.widget.RemoteViews
import com.example.rainy.widget.RainHomeWidgetProvider
import com.example.rainy.widget.WidgetBinders
import com.example.rainy.widget.WidgetBundle

/** Thin [RainHomeWidgetProvider] subclasses mapped to [WidgetBinders]. */
class WidgetMaterialYouForecast1x1Provider : RainHomeWidgetProvider() {
    override fun buildViews(context: Context, bundle: WidgetBundle): RemoteViews =
        WidgetBinders.materialYouForecast1x1(context, bundle)
}

class WidgetMaterialYouCurrentProvider : RainHomeWidgetProvider() {
    override fun buildViews(context: Context, bundle: WidgetBundle): RemoteViews =
        WidgetBinders.materialYouCurrent(context, bundle)
}

class WidgetClockDayHorizontalProvider : RainHomeWidgetProvider() {
    override fun buildViews(context: Context, bundle: WidgetBundle): RemoteViews =
        WidgetBinders.clockHorizontal(context, bundle)
}
