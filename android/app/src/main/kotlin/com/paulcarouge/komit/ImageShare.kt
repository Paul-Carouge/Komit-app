package com.paulcarouge.komit

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

const val IMAGE_SHARE_CHANNEL = "com.paulcarouge.komit/image_share"

/** Matches res/xml/file_paths.xml; the folder only ever holds the last shared image. */
private const val SHARED_IMAGES_DIRECTORY = "shared_images"

/** A shared card is a few hundred kilobytes; anything far larger is not one of Komit's images. */
private const val MAXIMUM_SHARED_IMAGE_BYTES = 10 * 1024 * 1024
private val PNG_SIGNATURE = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

/**
 * A new name for each share: an app granted the previous image keeps a URI that no longer
 * points anywhere, so it can never read a later one (say, with habit names shown).
 */
internal fun sharedImageFileName(sharedAtMillis: Long): String = "komit-$sharedAtMillis.png"

/** Removes every image shared before; the receiving app has had time to read it. */
fun deleteSharedImages(cacheDirectory: File) {
    File(cacheDirectory, SHARED_IMAGES_DIRECTORY).listFiles()?.forEach { it.delete() }
}

internal fun isShareablePng(bytes: ByteArray): Boolean =
    bytes.size in (PNG_SIGNATURE.size + 1)..MAXIMUM_SHARED_IMAGE_BYTES &&
        bytes.copyOfRange(0, PNG_SIGNATURE.size).contentEquals(PNG_SIGNATURE)

/**
 * Opens the system share sheet with a PNG rendered by Dart. The file lives in the cache and is
 * readable only through a one-time grant to the app the user picks.
 */
class ImageShare(
    private val activity: Activity,
) {
    fun handle(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (call.method != "sharePng") {
            result.notImplemented()
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null || !isShareablePng(bytes)) {
            result.error("invalid_image", "Not a PNG of an accepted size", null)
            return
        }
        val uri =
            try {
                deleteSharedImages(activity.cacheDir)
                val directory = File(activity.cacheDir, SHARED_IMAGES_DIRECTORY).apply { mkdirs() }
                val file = File(directory, sharedImageFileName(System.currentTimeMillis())).apply { writeBytes(bytes) }
                FileProvider.getUriForFile(activity, "${activity.packageName}.files", file)
            } catch (error: IOException) {
                // A full storage must end in Dart's "could not share" message, not a crash.
                result.error("write_failed", error.javaClass.simpleName, null)
                return
            }
        val sendIntent =
            Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        try {
            activity.startActivity(Intent.createChooser(sendIntent, call.argument<String>("chooserTitle")))
            result.success(null)
        } catch (error: ActivityNotFoundException) {
            result.error("unavailable", error.message, null)
        }
    }
}
