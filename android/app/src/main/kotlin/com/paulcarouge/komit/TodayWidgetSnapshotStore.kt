package com.paulcarouge.komit

import android.content.Context
import android.util.AtomicFile
import android.util.Log
import java.io.File
import java.io.IOException

/** In the app's private files: no other app, and no backup outside Komit's own, can read it. */
private const val SNAPSHOT_FILE_NAME = "today_widget_snapshot.json"

/** The widget's copy of today's checklist, written by Dart after every change. */
object TodayWidgetSnapshotStore {
    private fun snapshotFile(context: Context) = AtomicFile(File(context.filesDir, SNAPSHOT_FILE_NAME))

    /** Refuses a malformed snapshot, so the widget never reads back what it cannot show. */
    fun save(
        context: Context,
        json: String,
    ): Boolean {
        if (parseTodayWidgetSnapshot(json) == null) return false
        val file = snapshotFile(context)
        val output = file.startWrite()
        try {
            output.write(json.toByteArray(Charsets.UTF_8))
            file.finishWrite(output)
            return true
        } catch (exception: IOException) {
            file.failWrite(output)
            Log.w("KomitWidget", "Could not save the widget snapshot", exception)
            return false
        }
    }

    /** Null before the app first wrote one, or when it is unreadable. */
    fun read(context: Context): TodayWidgetSnapshot? {
        val file = snapshotFile(context)
        if (!file.baseFile.exists()) return null
        return try {
            parseTodayWidgetSnapshot(file.readFully().toString(Charsets.UTF_8))
        } catch (exception: IOException) {
            Log.w("KomitWidget", "Could not read the widget snapshot", exception)
            null
        }
    }
}
