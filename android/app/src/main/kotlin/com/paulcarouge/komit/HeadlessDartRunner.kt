package com.paulcarouge.komit

import android.content.BroadcastReceiver
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** A receiver has about ten seconds; Komit's background work normally takes well under one. */
private const val HEADLESS_DART_TIMEOUT_MILLISECONDS = 9_000L

/** The method Dart calls on [channelName] once its work is done, so the engine can stop. */
private const val FINISHED_METHOD = "finished"

/**
 * Runs the Dart function [functionName] of [libraryUri] in a headless engine on behalf of a
 * receiver, keeping the receiver alive with goAsync until Dart calls "finished" on
 * [channelName] or the timeout expires. Other calls on that channel go to [onMethodCall].
 * [onFinished] runs on the main thread once, after the engine stopped.
 */
fun BroadcastReceiver.runDartInHeadlessEngine(
    context: Context,
    libraryUri: String,
    functionName: String,
    channelName: String,
    logTag: String,
    entrypointArguments: List<String> = emptyList(),
    onMethodCall: (Context, MethodCall, MethodChannel.Result) -> Unit = { _, _, result -> result.notImplemented() },
    onFinished: (Context) -> Unit = {},
) {
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
                onFinished(applicationContext)
                pendingResult.finish()
            }
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == FINISHED_METHOD) {
                result.success(null)
                mainHandler.post(finish)
            } else {
                onMethodCall(applicationContext, call, result)
            }
        }
        mainHandler.postDelayed({
            if (!isFinished) Log.w(logTag, "Background Dart work timed out")
            finish()
        }, HEADLESS_DART_TIMEOUT_MILLISECONDS)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(flutterLoader.findAppBundlePath(), libraryUri, functionName),
            entrypointArguments,
        )
    }
}
