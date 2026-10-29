package com.paulcarouge.komit

/** The only action Komit's own shortcuts and widget use to open a screen; see res/xml/shortcuts.xml. */
const val OPEN_DESTINATION_ACTION = "com.paulcarouge.komit.action.OPEN_DESTINATION"

/** Holds a [LaunchDestination.dartName]; the launcher may pass anything, so it is validated. */
const val DESTINATION_EXTRA = "com.paulcarouge.komit.extra.DESTINATION"

/**
 * The screens a shortcut or the widget may open. The names are the Dart `LaunchDestination`
 * values, which Dart maps to a route; Flutter deep links stay disabled.
 */
enum class LaunchDestination(
    val dartName: String,
) {
    TODAY("today"),
    NEW_HABIT("newHabit"),
    ;

    companion object {
        /** Null unless [action] is [OPEN_DESTINATION_ACTION] and [destinationExtra] a known name. */
        fun fromIntentAction(
            action: String?,
            destinationExtra: String?,
        ): LaunchDestination? {
            if (action != OPEN_DESTINATION_ACTION) return null
            return entries.firstOrNull { it.dartName == destinationExtra }
        }
    }
}
