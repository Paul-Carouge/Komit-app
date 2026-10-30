package com.paulcarouge.komit

import org.testng.Assert.assertEquals
import org.testng.annotations.Test

private const val ANDROID_12L = 32
private const val ANDROID_13 = 33

class WindowProtectionsTest {
    @Test
    fun `the app lock blanks the recents card with FLAG_SECURE below Android 13`() {
        assertEquals(
            windowProtectionsFor(sdkInt = ANDROID_12L, isAppLockEnabled = true, isScreenContentHidden = false),
            WindowProtections(isSecureFlagSet = true, isRecentsScreenshotEnabled = false),
        )
    }

    @Test
    fun `the app lock relies on the recents screenshot setting from Android 13`() {
        assertEquals(
            windowProtectionsFor(sdkInt = ANDROID_13, isAppLockEnabled = true, isScreenContentHidden = false),
            WindowProtections(isSecureFlagSet = false, isRecentsScreenshotEnabled = false),
        )
    }

    @Test
    fun `hiding screen content sets FLAG_SECURE on every version`() {
        for (sdkInt in listOf(ANDROID_12L, ANDROID_13)) {
            assertEquals(
                windowProtectionsFor(sdkInt, isAppLockEnabled = false, isScreenContentHidden = true),
                WindowProtections(isSecureFlagSet = true, isRecentsScreenshotEnabled = true),
            )
        }
    }

    @Test
    fun `nothing is hidden when both settings are off`() {
        for (sdkInt in listOf(ANDROID_12L, ANDROID_13)) {
            assertEquals(
                windowProtectionsFor(sdkInt, isAppLockEnabled = false, isScreenContentHidden = false),
                WindowProtections(isSecureFlagSet = false, isRecentsScreenshotEnabled = true),
            )
        }
    }
}
