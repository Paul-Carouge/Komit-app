package com.paulcarouge.komit

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.ZoneId

const val HOME_WIDGET_CHANNEL = "com.paulcarouge.komit/home_widget"
const val SAVE_SNAPSHOT_METHOD = "saveSnapshot"

private const val HOME_WIDGET_LIBRARY = "package:komit/services/reminder_background_work.dart"
private const val HOME_WIDGET_FUNCTION = "updateHomeWidgetInBackground"
private const val LOG_HABIT_ACTION = "com.paulcarouge.komit.action.LOG_HABIT_FROM_WIDGET"
private const val HABIT_ID_EXTRA = "com.paulcarouge.komit.extra.HABIT_ID"
private const val NO_HABIT_ID = -1L

/** Rows beyond this would be cut off on a typical 4x3 widget; the rest are summed up below. */
private const val MAXIMUM_VISIBLE_HABIT_ROWS = 6

/** Request codes of the widget's own pending intents; row buttons use the habit id. */
private const val OPEN_TODAY_REQUEST_CODE = 0
private const val MIDNIGHT_REFRESH_REQUEST_CODE = 1

/** Above this relative luminance the check mark is dark, so it stays readable on any habit color. */
private const val LIGHT_HABIT_COLOR_LUMINANCE_THRESHOLD = 0.5f

/** Set while a headless refresh runs, so a burst of updates starts a single engine. */
private var isStaleSnapshotRefreshRunning = false

/**
 * The "Today" home-screen widget: the habits scheduled today, each with a round button that logs
 * its first objective in a headless Dart engine, through the same repository as the app.
 */
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action == LOG_HABIT_ACTION) {
            val habitId = intent.getLongExtra(HABIT_ID_EXTRA, NO_HABIT_ID)
            if (habitId > 0) logHabitToday(context, habitId)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val snapshot = TodayWidgetSnapshotStore.read(context)
        renderTodayWidgets(context, snapshot)
        if (snapshot?.daysSinceEpoch != todayDaysSinceEpoch() && !isStaleSnapshotRefreshRunning) {
            // A new day began since Dart last wrote: ask it for today's checklist.
            isStaleSnapshotRefreshRunning = true
            runHomeWidgetDart(context, entrypointArguments = emptyList()) { isStaleSnapshotRefreshRunning = false }
        }
    }

    override fun onDisabled(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(midnightRefreshPendingIntent(context))
    }

    private fun logHabitToday(
        context: Context,
        habitId: Long,
    ) {
        // Shows the tap at once; the headless engine takes a moment to start and then writes the truth.
        TodayWidgetSnapshotStore.read(context)?.let { renderTodayWidgets(context, it.withHabitLoggedToday(habitId)) }
        runHomeWidgetDart(context, entrypointArguments = listOf(habitId.toString())) {}
    }

    private fun runHomeWidgetDart(
        context: Context,
        entrypointArguments: List<String>,
        onFinished: () -> Unit,
    ) {
        runDartInHeadlessEngine(
            context,
            libraryUri = HOME_WIDGET_LIBRARY,
            functionName = HOME_WIDGET_FUNCTION,
            channelName = HOME_WIDGET_CHANNEL,
            logTag = "KomitWidget",
            entrypointArguments = entrypointArguments,
            onMethodCall = { applicationContext, call, result ->
                if (call.method == SAVE_SNAPSHOT_METHOD) {
                    result.success(TodayWidgetSnapshotStore.save(applicationContext, call.arguments as? String ?: ""))
                } else {
                    result.notImplemented()
                }
            },
            onFinished = { applicationContext ->
                onFinished()
                // Renders what Dart saved, or the real state again if logging failed.
                renderTodayWidgets(applicationContext, TodayWidgetSnapshotStore.read(applicationContext))
            },
        )
    }
}

/** Redraws every "Today" widget from the saved snapshot; called by the app after each save. */
fun refreshTodayWidgets(context: Context) = renderTodayWidgets(context, TodayWidgetSnapshotStore.read(context))

private fun renderTodayWidgets(
    context: Context,
    snapshot: TodayWidgetSnapshot?,
) {
    val appWidgetManager = AppWidgetManager.getInstance(context)
    val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java))
    if (appWidgetIds.isEmpty()) return
    val views = todayWidgetViews(context, snapshot?.takeIf { it.daysSinceEpoch == todayDaysSinceEpoch() })
    appWidgetManager.updateAppWidget(appWidgetIds, views)
    scheduleMidnightRefresh(context)
}

/** [snapshot] is null when there is nothing current to show: never written yet, or of another day. */
private fun todayWidgetViews(
    context: Context,
    snapshot: TodayWidgetSnapshot?,
): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_today)
    views.setOnClickPendingIntent(R.id.widget_header, openTodayPendingIntent(context))
    views.setOnClickPendingIntent(R.id.widget_message, openTodayPendingIntent(context))
    views.removeAllViews(R.id.widget_habit_rows)
    val habits = snapshot?.habits.orEmpty()
    val message =
        when {
            snapshot == null -> {
                context.getString(R.string.widget_open_komit_to_refresh)
            }

            snapshot.isLocked -> {
                context.getString(R.string.widget_unlock_komit)
            }

            habits.isEmpty() -> {
                context.getString(R.string.widget_nothing_planned_today)
            }

            habits.size > MAXIMUM_VISIBLE_HABIT_ROWS -> {
                context.getString(R.string.widget_more_habits, habits.size - MAXIMUM_VISIBLE_HABIT_ROWS)
            }

            else -> {
                null
            }
        }
    views.setTextViewText(R.id.widget_message, message.orEmpty())
    views.setViewVisibility(R.id.widget_message, if (message == null) View.GONE else View.VISIBLE)
    if (snapshot == null || snapshot.isLocked) {
        views.setViewVisibility(R.id.widget_progress, View.GONE)
    } else {
        val doneCount = habits.count { it.isLoggedToday }
        views.setViewVisibility(R.id.widget_progress, if (habits.isEmpty()) View.GONE else View.VISIBLE)
        views.setTextViewText(R.id.widget_progress, context.getString(R.string.widget_progress, doneCount, habits.size))
        views.setContentDescription(
            R.id.widget_progress,
            context.resources.getQuantityString(R.plurals.widget_progress_description, habits.size, doneCount, habits.size),
        )
    }
    for (habit in habits.take(MAXIMUM_VISIBLE_HABIT_ROWS)) {
        views.addView(R.id.widget_habit_rows, habitRowViews(context, habit))
    }
    return views
}

private fun habitRowViews(
    context: Context,
    habit: TodayWidgetHabit,
): RemoteViews {
    val row = RemoteViews(context.packageName, R.layout.widget_today_row)
    row.setTextViewText(R.id.widget_habit_title, habit.title)
    row.setImageViewResource(
        R.id.widget_log_circle,
        if (habit.isLoggedToday) R.drawable.widget_log_filled else R.drawable.widget_log_ring,
    )
    row.setInt(R.id.widget_log_circle, "setColorFilter", habit.colorArgb)
    row.setViewVisibility(R.id.widget_log_check, if (habit.isLoggedToday) View.VISIBLE else View.GONE)
    row.setInt(R.id.widget_log_check, "setColorFilter", checkColorOn(habit.colorArgb))
    if (habit.isLoggedToday) {
        row.setContentDescription(R.id.widget_log_button, context.getString(R.string.widget_habit_done, habit.title))
        // A logged habit is changed in the app, where the log sheet shows every objective.
        row.setOnClickPendingIntent(R.id.widget_log_button, openTodayPendingIntent(context))
    } else {
        row.setContentDescription(R.id.widget_log_button, context.getString(R.string.widget_log_habit, habit.title))
        row.setOnClickPendingIntent(R.id.widget_log_button, logHabitPendingIntent(context, habit.habitId))
    }
    return row
}

private fun checkColorOn(habitColorArgb: Int): Int =
    if (Color.luminance(habitColorArgb) > LIGHT_HABIT_COLOR_LUMINANCE_THRESHOLD) Color.BLACK else Color.WHITE

private fun todayDaysSinceEpoch(): Long = LocalDate.now(ZoneId.systemDefault()).toEpochDay()

private fun openTodayPendingIntent(context: Context): PendingIntent {
    val intent =
        Intent(context, MainActivity::class.java)
            .setAction(OPEN_DESTINATION_ACTION)
            .putExtra(DESTINATION_EXTRA, LaunchDestination.TODAY.dartName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    return PendingIntent.getActivity(
        context,
        OPEN_TODAY_REQUEST_CODE,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

private fun logHabitPendingIntent(
    context: Context,
    habitId: Long,
): PendingIntent {
    val intent =
        Intent(context, TodayWidgetProvider::class.java)
            .setAction(LOG_HABIT_ACTION)
            .putExtra(HABIT_ID_EXTRA, habitId)
    // One request code per habit, or every row's intent would be the same one with the last extra.
    return PendingIntent.getBroadcast(
        context,
        habitId.toInt(),
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

private fun midnightRefreshPendingIntent(context: Context): PendingIntent {
    val intent = Intent(context, TodayWidgetProvider::class.java).setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
    val appWidgetIds =
        AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java))
    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
    return PendingIntent.getBroadcast(
        context,
        MIDNIGHT_REFRESH_REQUEST_CODE,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

/**
 * Inexact and non-waking on purpose: the widget only needs to be right when someone looks at it,
 * which wakes the phone and delivers the alarm, and Komit asks for no exact-alarm permission.
 */
private fun scheduleMidnightRefresh(context: Context) {
    val nextMidnightMillis =
        LocalDate
            .now(ZoneId.systemDefault())
            .plusDays(1)
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()
    context
        .getSystemService(AlarmManager::class.java)
        .set(AlarmManager.RTC, nextMidnightMillis, midnightRefreshPendingIntent(context))
}
