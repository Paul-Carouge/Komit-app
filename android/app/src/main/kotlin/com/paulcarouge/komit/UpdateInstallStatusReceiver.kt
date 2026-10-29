package com.paulcarouge.komit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.os.Build
import android.util.Log

/** Receives the installer session result and shows the system confirmation when needed. */
class UpdateInstallStatusReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        if (status != PackageInstaller.STATUS_PENDING_USER_ACTION) {
            Log.i("KomitUpdate", "Install session finished with status $status")
            installFailureReasonFor(status)?.let { reason -> onInstallFailed?.invoke(reason) }
            return
        }
        val confirmationIntent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_INTENT)
            }
        confirmationIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)?.let(context::startActivity)
    }

    companion object {
        /** Set by [MainActivity] while Flutter runs; receives a Dart `AppUpdateFailureReason` name. */
        var onInstallFailed: ((String) -> Unit)? = null

        /** Null on success. The names match the Dart `AppUpdateFailureReason` values. */
        fun installFailureReasonFor(status: Int): String? =
            when (status) {
                PackageInstaller.STATUS_SUCCESS -> null
                PackageInstaller.STATUS_FAILURE_ABORTED -> "installCancelled"
                PackageInstaller.STATUS_FAILURE_CONFLICT -> "installConflict"
                PackageInstaller.STATUS_FAILURE_INCOMPATIBLE -> "installIncompatible"
                PackageInstaller.STATUS_FAILURE_STORAGE -> "installStorage"
                PackageInstaller.STATUS_FAILURE_BLOCKED -> "installBlocked"
                else -> "installFailed"
            }
    }
}
