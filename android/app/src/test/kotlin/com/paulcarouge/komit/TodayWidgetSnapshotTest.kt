package com.paulcarouge.komit

import org.testng.Assert.assertEquals
import org.testng.Assert.assertNull
import org.testng.annotations.Test

class TodayWidgetSnapshotTest {
    private fun snapshotJson(habitsJson: String, version: Int = TODAY_WIDGET_SNAPSHOT_FORMAT_VERSION) =
        """{"version":$version,"day":20755,"habits":[$habitsJson]}"""

    @Test
    fun `parses the habits Dart writes, keeping their order and the ARGB bits of unsigned colors`() {
        val snapshot =
            parseTodayWidgetSnapshot(
                snapshotJson(
                    """{"id":3,"title":"Read","colorArgb":4294937626,"isLoggedToday":true},""" +
                        """{"id":1,"title":"Run","colorArgb":4278190335,"isLoggedToday":false}""",
                ),
            )

        assertEquals(
            snapshot,
            TodayWidgetSnapshot(
                daysSinceEpoch = 20755,
                habits =
                    listOf(
                        TodayWidgetHabit(habitId = 3, title = "Read", colorArgb = 0xFFFF8C1A.toInt(), isLoggedToday = true),
                        TodayWidgetHabit(habitId = 1, title = "Run", colorArgb = 0xFF0000FF.toInt(), isLoggedToday = false),
                    ),
            ),
        )
    }

    @Test
    fun `reads the locked flag, absent from snapshots written before the app lock`() {
        val lockedJson = """{"version":$TODAY_WIDGET_SNAPSHOT_FORMAT_VERSION,"day":20755,"isLocked":true,"habits":[]}"""
        assertEquals(parseTodayWidgetSnapshot(lockedJson)?.isLocked, true)
        assertEquals(parseTodayWidgetSnapshot(snapshotJson(""))?.isLocked, false)
    }

    @Test
    fun `parses a day with nothing scheduled`() {
        assertEquals(parseTodayWidgetSnapshot(snapshotJson(""))?.habits, emptyList<TodayWidgetHabit>())
    }

    @Test
    fun `rejects truncated, foreign-version and invalid snapshots instead of crashing`() {
        val validHabit = """{"id":1,"title":"Run","colorArgb":4278190335,"isLoggedToday":false}"""
        val rejectedSnapshots =
            listOf(
                "",
                snapshotJson(validHabit).dropLast(3),
                snapshotJson(validHabit, version = TODAY_WIDGET_SNAPSHOT_FORMAT_VERSION + 1),
                snapshotJson("""{"id":0,"title":"Run","colorArgb":1,"isLoggedToday":false}"""),
                snapshotJson("""{"id":1,"title":" ","colorArgb":1,"isLoggedToday":false}"""),
                snapshotJson("""{"id":1,"title":"${"x".repeat(201)}","colorArgb":1,"isLoggedToday":false}"""),
                snapshotJson("""{"id":1,"title":"Run","isLoggedToday":false}"""),
            )

        for (json in rejectedSnapshots) assertNull(parseTodayWidgetSnapshot(json), json)
    }

    @Test
    fun `marks only the tapped habit as logged`() {
        val snapshot =
            TodayWidgetSnapshot(
                daysSinceEpoch = 1,
                habits =
                    listOf(
                        TodayWidgetHabit(habitId = 1, title = "Run", colorArgb = 0, isLoggedToday = false),
                        TodayWidgetHabit(habitId = 2, title = "Read", colorArgb = 0, isLoggedToday = false),
                    ),
            )

        assertEquals(snapshot.withHabitLoggedToday(2).habits.map { it.isLoggedToday }, listOf(false, true))
    }
}
