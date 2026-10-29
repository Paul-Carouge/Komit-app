package com.paulcarouge.komit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

private const val REMINDER_REBUILD_CHANNEL = "com.paulcarouge.komit/reminder_rebuild"
private const val REMINDER_REBUILD_LIBRARY = "package:komit/services/reminder_background_work.dart"
private const val REMINDER_REBUILD_FUNCTION = "rebuildRemindersAfterSystemEvent"

/** A receiver has about ten seconds; the rebuild normally takes well under one. */
private const val REMINDER_REBUILD_TIMEOUT_MILLISECONDS = 9_000L

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
        val pendingResult = goAsync()
        val applicationContext = context.applicationContext
        val mainHandler = Handler(Looper.getMainLooper())
        val flutterLoader = FlutterInjector.instance().flutterLoader()
        flutterLoader.startInitialization(applicationContext)
        flutterLoader.ensureInitializationCompleteAsync(applicationContext, null, mainHandler) {
            val engine = FlutterEngine(applicationContext)
            var isFinished = false
            val finish = {
                if (!isFinished) {
                    isFinished = true
                    engine.destroy()
                    pendingResult.finish()
                }
            }
            MethodChannel(engine.dartExecutor.binaryMessenger, REMINDER_REBUILD_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "finished") {
                    result.success(null)
                    mainHandler.post(finish)
                } else {
                    result.notImplemented()
                }
            }
            mainHandler.postDelayed({
                if (!isFinished) Log.w("KomitReminders", "Reminder rebuild timed out")
                finish()
            }, REMINDER_REBUILD_TIMEOUT_MILLISECONDS)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    flutterLoader.findAppBundlePath(),
                    REMINDER_REBUILD_LIBRARY,
                    REMINDER_REBUILD_FUNCTION,
                ),
            )
        }
    }
}
