package com.paulcarouge.komit

import org.testng.Assert.assertEquals
import org.testng.Assert.assertFalse
import org.testng.Assert.assertNotEquals
import org.testng.Assert.assertTrue
import org.testng.annotations.Test
import java.nio.file.Files

class ImageShareTest {
    private val pngSignature = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

    @Test
    fun `accepts a PNG and refuses other bytes`() {
        assertTrue(isShareablePng(pngSignature + byteArrayOf(0)))
        assertFalse(isShareablePng(pngSignature))
        assertFalse(isShareablePng("GIF89a-not-a-png".toByteArray()))
        assertFalse(isShareablePng(ByteArray(0)))
    }

    @Test
    fun `refuses an image above the size limit`() {
        assertFalse(isShareablePng(pngSignature + ByteArray(10 * 1024 * 1024)))
    }

    @Test
    fun `each share gets its own file name`() {
        assertNotEquals(sharedImageFileName(1_000), sharedImageFileName(1_001))
        assertEquals(sharedImageFileName(1_000), "komit-1000.png")
    }

    @Test
    fun `deleting shared images empties only their folder`() {
        val cacheDirectory = Files.createTempDirectory("komit-cache").toFile()
        val sharedImages = java.io.File(cacheDirectory, "shared_images").apply { mkdirs() }
        java.io.File(sharedImages, "komit-1.png").writeBytes(pngSignature)
        val otherCacheFile = java.io.File(cacheDirectory, "komit-update.apk").apply { writeBytes(byteArrayOf(1)) }

        deleteSharedImages(cacheDirectory)

        assertEquals(sharedImages.listFiles()?.size, 0)
        assertEquals(otherCacheFile.exists(), true)
        deleteSharedImages(java.io.File(cacheDirectory, "missing"))
    }
}
