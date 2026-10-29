package com.paulcarouge.komit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

private const val REMINDER_REBUILD_CHANNEL = "com.paulcarouge.komit/reminder_rebuild"
private const val REMINDER_REBUILD_LIBRARY = "package:komit/services/reminder_background_work.dart"
private const val REMINDER_REBUILD_FUNCTION = "rebuildRemindersAfterSystemEvent"

private val HANDLED_ACTIONS =
    setOf(
        Intent.ACTION_BOOT_COMPLETED,
        Intent.ACTION_MY_PACKAGE_REPLACED,
        Intent.ACTION_TIMEZONE_CHANGED,
    )

/**
 * Reminders are one-shot notifications planned a week ahead, at wall-clock times of the current
 * time zone. After a reboot, an update or a time-zone change, this runs the Dart rebuild in a
 * headless engine so they stay right without the user opening the app.
 */
class ReminderRebuildReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action !in HANDLED_ACTIONS) return
        runDartInHeadlessEngine(
            context,
            libraryUri = REMINDER_REBUILD_LIBRARY,
            functionName = REMINDER_REBUILD_FUNCTION,
            channelName = REMINDER_REBUILD_CHANNEL,
            logTag = "KomitReminders",
        )
    }
}
