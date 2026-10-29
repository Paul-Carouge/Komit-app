package com.paulcarouge.komit

import org.json.JSONException
import org.json.JSONObject

/** Bumped with lib/services/home_widget_service.dart whenever the snapshot shape changes. */
const val TODAY_WIDGET_SNAPSHOT_FORMAT_VERSION = 1

/** Longer titles are cut by the layout anyway; the cap bounds what a corrupted file can cost. */
private const val MAXIMUM_HABIT_TITLE_LENGTH = 200

data class TodayWidgetHabit(
    val habitId: Long,
    val title: String,
    val colorArgb: Int,
    val isLoggedToday: Boolean,
)

/**
 * What Dart last wrote for the widget: the habits scheduled on [daysSinceEpoch], in order.
 * [isLocked] is true while the app lock is on; Dart then writes no habit at all.
 */
data class TodayWidgetSnapshot(
    val daysSinceEpoch: Long,
    val habits: List<TodayWidgetHabit>,
    val isLocked: Boolean = false,
) {
    fun withHabitLoggedToday(habitId: Long): TodayWidgetSnapshot =
        copy(habits = habits.map { if (it.habitId == habitId) it.copy(isLoggedToday = true) else it })
}

/**
 * Null for anything that is not a well-formed snapshot of the current format: the file is
 * written by Komit, but a half-written or older file must show the "open Komit" state, not crash.
 */
fun parseTodayWidgetSnapshot(json: String): TodayWidgetSnapshot? =
    try {
        val root = JSONObject(json)
        if (root.getInt("version") != TODAY_WIDGET_SNAPSHOT_FORMAT_VERSION) {
            null
        } else {
            val habitsJson = root.getJSONArray("habits")
            val habits =
                (0 until habitsJson.length()).map { index ->
                    val habitJson = habitsJson.getJSONObject(index)
                    val habitId = habitJson.getLong("id")
                    val title = habitJson.getString("title")
                    if (habitId <= 0 || title.isBlank() || title.length > MAXIMUM_HABIT_TITLE_LENGTH) return null
                    TodayWidgetHabit(
                        habitId = habitId,
                        title = title,
                        // Dart writes the ARGB value unsigned, which overflows Int; the bits are what matter.
                        colorArgb = habitJson.getLong("colorArgb").toInt(),
                        isLoggedToday = habitJson.getBoolean("isLoggedToday"),
                    )
                }
            TodayWidgetSnapshot(
                daysSinceEpoch = root.getLong("day"),
                habits = habits,
                isLocked = root.optBoolean("isLocked", false),
            )
        }
    } catch (exception: JSONException) {
        null
    }
