package com.paulcarouge.komit

import android.app.Activity
import android.app.KeyguardManager
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

const val APP_LOCK_CHANNEL = "com.paulcarouge.komit/app_lock"

/** Any request code works: MainActivity starts no other activity for a result. */
private const val CONFIRM_DEVICE_CREDENTIAL_REQUEST_CODE = 7301

/** Results sent to Dart; keep in sync with AppLockAuthenticationResult in app_lock_service.dart. */
private const val RESULT_SUCCEEDED = "succeeded"
private const val RESULT_CANCELLED = "cancelled"
private const val RESULT_FAILED = "failed"
private const val RESULT_UNAVAILABLE = "unavailable"

/**
 * The optional app lock: a strong biometric or the device credential (PIN, pattern, password).
 * Android 11+ uses the system BiometricPrompt; earlier versions confirm the device credential,
 * since BIOMETRIC_STRONG or DEVICE_CREDENTIAL cannot be combined there.
 */
class AppLock(
    private val activity: Activity,
) {
    private var pendingCredentialResult: MethodChannel.Result? = null

    fun handle(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "canAuthenticate" -> {
                result.success(canAuthenticate())
            }

            "authenticate" -> {
                authenticate(call.argument<String>("title").orEmpty(), call.argument<String>("subtitle"), result)
            }

            "setRecentsScreenshotEnabled" -> {
                // Android 13+: the recents screen shows a blank card instead of the last frame.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activity.setRecentsScreenshotEnabled(call.argument<Boolean>("isEnabled") ?: true)
                }
                result.success(null)
            }

            "setSecureWindow" -> {
                if (call.argument<Boolean>("isSecure") == true) {
                    activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun canAuthenticate(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.getSystemService(BiometricManager::class.java).canAuthenticate(ALLOWED_AUTHENTICATORS) ==
                BiometricManager.BIOMETRIC_SUCCESS
        } else {
            activity.getSystemService(KeyguardManager::class.java).isDeviceSecure
        }

    private fun authenticate(
        title: String,
        subtitle: String?,
        result: MethodChannel.Result,
    ) {
        if (!canAuthenticate()) {
            result.success(RESULT_UNAVAILABLE)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            authenticateWithBiometricPrompt(title, subtitle, result)
        } else {
            confirmDeviceCredential(title, subtitle, result)
        }
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.R)
    private fun authenticateWithBiometricPrompt(
        title: String,
        subtitle: String?,
        result: MethodChannel.Result,
    ) {
        val prompt =
            BiometricPrompt
                .Builder(activity)
                .setTitle(title)
                .apply { if (subtitle != null) setSubtitle(subtitle) }
                .setAllowedAuthenticators(ALLOWED_AUTHENTICATORS)
                .build()
        // The callback may in theory fire twice (an error after success); answer Dart only once.
        var isAnswered = false

        fun answer(value: String) {
            if (isAnswered) return
            isAnswered = true
            result.success(value)
        }
        prompt.authenticate(
            CancellationSignal(),
            activity.mainExecutor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authenticationResult: BiometricPrompt.AuthenticationResult) {
                    answer(RESULT_SUCCEEDED)
                }

                override fun onAuthenticationError(
                    errorCode: Int,
                    errorString: CharSequence,
                ) {
                    val isCancellation =
                        errorCode == BiometricPrompt.BIOMETRIC_ERROR_USER_CANCELED ||
                            errorCode == BiometricPrompt.BIOMETRIC_ERROR_CANCELED
                    answer(if (isCancellation) RESULT_CANCELLED else RESULT_FAILED)
                }
                // onAuthenticationFailed is one rejected finger: the prompt stays open, nothing to answer.
            },
        )
    }

    @Suppress("DEPRECATION") // The only credential prompt before Android 11 without androidx.biometric.
    private fun confirmDeviceCredential(
        title: String,
        subtitle: String?,
        result: MethodChannel.Result,
    ) {
        val intent = activity.getSystemService(KeyguardManager::class.java).createConfirmDeviceCredentialIntent(title, subtitle)
        if (intent == null) {
            result.success(RESULT_UNAVAILABLE)
            return
        }
        pendingCredentialResult?.success(RESULT_CANCELLED)
        pendingCredentialResult = result
        activity.startActivityForResult(intent, CONFIRM_DEVICE_CREDENTIAL_REQUEST_CODE)
    }

    /** Returns true when the activity result was the credential confirmation. */
    fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
    ): Boolean {
        if (requestCode != CONFIRM_DEVICE_CREDENTIAL_REQUEST_CODE) return false
        pendingCredentialResult?.success(if (resultCode == Activity.RESULT_OK) RESULT_SUCCEEDED else RESULT_CANCELLED)
        pendingCredentialResult = null
        return true
    }

    private companion object {
        const val ALLOWED_AUTHENTICATORS =
            BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL
    }
}
