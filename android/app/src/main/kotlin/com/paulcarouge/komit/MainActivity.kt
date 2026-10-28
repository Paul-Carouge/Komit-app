package com.paulcarouge.komit

import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

private const val APP_UPDATE_CHANNEL = "com.paulcarouge.komit/app_update"

class MainActivity : FlutterActivity() {
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "currentVersionName" -> {
                        result.success(currentVersionName())
                    }

                    "canInstallPackages" -> {
                        result.success(canInstallPackages())
                    }

                    "openInstallPermissionSettings" -> {
                        openInstallPermissionSettings()
                        result.success(null)
                    }

                    "installApk" -> {
                        installApk(call, result)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    override fun onDestroy() {
        backgroundExecutor.shutdown()
        super.onDestroy()
    }

    private fun currentVersionName(): String? = packageManager.getPackageInfo(packageName, 0).versionName

    private fun canInstallPackages(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        startActivity(
            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")),
        )
    }

    /** Verifies the downloaded APK against the release digest, then hands it to the system installer. */
    private fun installApk(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val apkPath = call.argument<String>("apkPath")
        val expectedSha256 = call.argument<String>("expectedSha256")?.lowercase()
        if (apkPath == null || expectedSha256 == null) {
            result.error("invalid_arguments", "apkPath and expectedSha256 are required", null)
            return
        }
        backgroundExecutor.execute {
            try {
                val apkFile = File(apkPath)
                val actualSha256 = sha256Of(apkFile)
                if (actualSha256 != expectedSha256) {
                    apkFile.delete()
                    runOnUiThread { result.error("checksum_mismatch", "Downloaded file is corrupted", null) }
                    return@execute
                }
                commitInstallSession(apkFile)
                runOnUiThread { result.success(null) }
            } catch (exception: Exception) {
                runOnUiThread { result.error("install_failed", exception.message, null) }
            }
        }
    }

    private fun sha256Of(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val readByteCount = input.read(buffer)
                if (readByteCount < 0) break
                digest.update(buffer, 0, readByteCount)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun commitInstallSession(apkFile: File) {
        val installer = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(packageName)
        val sessionId = installer.createSession(params)
        installer.openSession(sessionId).use { session ->
            session.openWrite("komit.apk", 0, apkFile.length()).use { output ->
                apkFile.inputStream().use { input -> input.copyTo(output) }
                session.fsync(output)
            }
            val statusIntent = Intent(this, UpdateInstallStatusReceiver::class.java)
            val pendingIntentFlags =
                PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
            val statusPendingIntent = PendingIntent.getBroadcast(this, sessionId, statusIntent, pendingIntentFlags)
            session.commit(statusPendingIntent.intentSender)
        }
    }
}
