package com.paulcarouge.komit

import org.testng.Assert.assertEquals
import org.testng.Assert.assertNull
import org.testng.annotations.Test

class LaunchDestinationTest {
    @Test
    fun `maps each shortcut destination to its Dart name`() {
        assertEquals(LaunchDestination.fromIntentAction(OPEN_DESTINATION_ACTION, "today"), LaunchDestination.TODAY)
        assertEquals(LaunchDestination.fromIntentAction(OPEN_DESTINATION_ACTION, "newHabit"), LaunchDestination.NEW_HABIT)
    }

    @Test
    fun `rejects other actions and unknown destinations`() {
        assertNull(LaunchDestination.fromIntentAction("android.intent.action.MAIN", "today"))
        assertNull(LaunchDestination.fromIntentAction(null, "today"))
        assertNull(LaunchDestination.fromIntentAction(OPEN_DESTINATION_ACTION, null))
        assertNull(LaunchDestination.fromIntentAction(OPEN_DESTINATION_ACTION, "TODAY"))
        assertNull(LaunchDestination.fromIntentAction(OPEN_DESTINATION_ACTION, "/habit/1/edit"))
    }
}
