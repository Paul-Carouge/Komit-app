package com.paulcarouge.komit

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
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
import javax.crypto.AEADBadTagException
import java.util.concurrent.Executors

private const val APP_UPDATE_CHANNEL = "com.paulcarouge.komit/app_update"
private const val NOTIFICATION_SETTINGS_CHANNEL = "com.paulcarouge.komit/notification_settings"
private const val LAUNCH_DESTINATION_CHANNEL = "com.paulcarouge.komit/launch_destination"
private const val BACKUP_ENCRYPTION_CHANNEL = "com.paulcarouge.komit/backup_encryption"
private const val RELEASES_PAGE_URL = "https://github.com/Paul-Carouge/Komit-app/releases"
private val SHA256_HEX_PATTERN = Regex("^[0-9a-f]{64}$")

class MainActivity : FlutterActivity() {
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private var launchDestinationChannel: MethodChannel? = null

    /** Taken once by Dart, so a configuration change never opens the same screen again. */
    private var initialLaunchDestination: LaunchDestination? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val appUpdateChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL)
        // The installer reports failures to a receiver after this call returned; relay them to Dart.
        UpdateInstallStatusReceiver.onInstallFailed = { reason -> appUpdateChannel.invokeMethod("installFailed", reason) }
        appUpdateChannel
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "currentVersionName" -> {
                        result.success(currentVersionName())
                    }

                    "canInstallPackages" -> {
                        result.success(canInstallPackages())
                    }

                    "openInstallPermissionSettings" -> {
                        startActivityOrReportUnavailable(result, installPermissionSettingsIntent())
                    }

                    "openReleasesPage" -> {
                        startActivityOrReportUnavailable(result, Intent(Intent.ACTION_VIEW, Uri.parse(RELEASES_PAGE_URL)))
                    }

                    "installApk" -> {
                        installApk(call, result)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "areNotificationsEnabled" -> {
                        result.success(getSystemService(NotificationManager::class.java).areNotificationsEnabled())
                    }

                    "openNotificationSettings" -> {
                        startActivityOrReportUnavailable(result, notificationSettingsIntent())
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOME_WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == SAVE_SNAPSHOT_METHOD) {
                    saveTodayWidgetSnapshot(call.arguments as? String, result)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_ENCRYPTION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "seal" -> runBackupEncryption(result) { sealBackup(call) }
                    "open" -> runBackupEncryption(result) { openBackup(call) }
                    else -> result.notImplemented()
                }
            }
        initialLaunchDestination = intent.launchDestination()
        launchDestinationChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCH_DESTINATION_CHANNEL).apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "takeInitialDestination") {
                        result.success(initialLaunchDestination?.dartName)
                        initialLaunchDestination = null
                    } else {
                        result.notImplemented()
                    }
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.launchDestination()?.let { destination ->
            launchDestinationChannel?.invokeMethod("openDestination", destination.dartName)
        }
    }

    private fun Intent.launchDestination(): LaunchDestination? =
        LaunchDestination.fromIntentAction(action, getStringExtra(DESTINATION_EXTRA))

    /** File I/O stays off the main thread; the widget redraws from what was saved. */
    private fun saveTodayWidgetSnapshot(
        json: String?,
        result: MethodChannel.Result,
    ) {
        if (json == null) {
            result.error("invalid_arguments", "saveSnapshot expects the snapshot JSON", null)
            return
        }
        backgroundExecutor.execute {
            val isSaved = TodayWidgetSnapshotStore.save(applicationContext, json)
            if (isSaved) refreshTodayWidgets(applicationContext)
            runOnUiThread { result.success(isSaved) }
        }
    }

    /** The key derivation takes about a second on purpose: never on the main thread. */
    private fun runBackupEncryption(
        result: MethodChannel.Result,
        operation: () -> Any,
    ) {
        backgroundExecutor.execute {
            try {
                val output = operation()
                runOnUiThread { result.success(output) }
            } catch (exception: AEADBadTagException) {
                runOnUiThread { result.error("wrong_passphrase", "Wrong passphrase or damaged file", null) }
            } catch (exception: IllegalArgumentException) {
                runOnUiThread { result.error("invalid_arguments", exception.message, null) }
            } catch (exception: Exception) {
                // Always answer: an unanswered call would leave the export spinning forever.
                runOnUiThread { result.error("encryption_failed", exception.javaClass.simpleName, null) }
            }
        }
    }

    private fun sealBackup(call: MethodCall): Map<String, ByteArray> {
        val plaintext = requireNotNull(call.argument<ByteArray>("plaintext")) { "plaintext missing" }
        val passphrase = requireNotNull(call.argument<String>("passphrase")) { "passphrase missing" }
        val iterationCount = requireNotNull(call.argument<Int>("iterationCount")) { "iterationCount missing" }
        val sealed = BackupEncryption.seal(plaintext, passphrase.toCharArray(), iterationCount)
        return mapOf("salt" to sealed.salt, "nonce" to sealed.nonce, "ciphertext" to sealed.ciphertext)
    }

    private fun openBackup(call: MethodCall): ByteArray {
        val sealed =
            SealedBackup(
                salt = requireNotNull(call.argument<ByteArray>("salt")) { "salt missing" },
                nonce = requireNotNull(call.argument<ByteArray>("nonce")) { "nonce missing" },
                ciphertext = requireNotNull(call.argument<ByteArray>("ciphertext")) { "ciphertext missing" },
            )
        val passphrase = requireNotNull(call.argument<String>("passphrase")) { "passphrase missing" }
        val iterationCount = requireNotNull(call.argument<Int>("iterationCount")) { "iterationCount missing" }
        return BackupEncryption.open(sealed, passphrase.toCharArray(), iterationCount)
    }

    override fun onDestroy() {
        UpdateInstallStatusReceiver.onInstallFailed = null
        launchDestinationChannel = null
        backgroundExecutor.shutdown()
        super.onDestroy()
    }

    /** Some phones lack a settings page or a browser; Dart then explains instead of doing nothing. */
    private fun startActivityOrReportUnavailable(
        result: MethodChannel.Result,
        intent: Intent,
    ) {
        try {
            startActivity(intent)
            result.success(null)
        } catch (exception: ActivityNotFoundException) {
            result.error("activity_unavailable", exception.message, null)
        }
    }

    private fun notificationSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        }

    private fun currentVersionName(): String? = packageManager.getPackageInfo(packageName, 0).versionName

    private fun canInstallPackages(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun installPermissionSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }

    /** Verifies the downloaded APK against the release digest, then hands it to the system installer. */
    private fun installApk(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val apkPath = call.argument<Any>("apkPath") as? String
        val expectedSha256 = (call.argument<Any>("expectedSha256") as? String)?.lowercase()
        // Only an APK this app downloaded into its own cache may be installed.
        val apkFile = apkPath?.let { File(it).canonicalFile }
        if (apkFile == null ||
            apkFile.parentFile != cacheDir.canonicalFile ||
            !apkFile.name.endsWith(".apk") ||
            expectedSha256 == null ||
            !SHA256_HEX_PATTERN.matches(expectedSha256)
        ) {
            result.error("invalid_arguments", "apkPath must be an APK in the cache and expectedSha256 a hex digest", null)
            return
        }
        backgroundExecutor.execute {
            try {
                val actualSha256 = sha256Of(apkFile)
                if (actualSha256 != expectedSha256) {
                    runOnUiThread { result.error("checksum_mismatch", "Downloaded file is corrupted", null) }
                    return@execute
                }
                commitInstallSession(apkFile)
                runOnUiThread { result.success(null) }
            } catch (exception: Exception) {
                runOnUiThread { result.error("install_failed", exception.message, null) }
            } finally {
                // The install session holds its own copy, so the cached APK is never needed again.
                apkFile.delete()
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
