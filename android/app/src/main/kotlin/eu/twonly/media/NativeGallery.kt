package eu.twonly.media

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import eu.twonly.MyApplication
import java.io.File

/**
 * Writes a finished media file into the user's photo library.
 *
 * Called directly from Rust/JNI. Rust decides whether an export should happen,
 * embeds the EXIF metadata beforehand, and owns the resulting state; this only
 * hands the bytes to MediaStore.
 */
object NativeGallery {
    private const val ALBUM = "twonly"

    @JvmStatic
    fun save(path: String, isVideo: Boolean, displayName: String, createdAtMillis: Long): Boolean {
        val source = File(path)
        if (!source.isFile) return false
        val resolver = MyApplication.instance.contentResolver
        val collection = if (isVideo) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }
        val extension = source.extension.ifEmpty { if (isVideo) "mp4" else "webp" }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$displayName.$extension")
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType(isVideo, extension))
            // Galleries sort on this, so it has to carry the capture time
            // rather than the moment the file was exported.
            put(MediaStore.MediaColumns.DATE_ADDED, createdAtMillis / 1000)
            put(MediaStore.MediaColumns.DATE_MODIFIED, createdAtMillis / 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val directory = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$directory/$ALBUM")
                // Hide the entry until the bytes are fully written.
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            put(
                if (isVideo) MediaStore.Video.Media.DATE_TAKEN else MediaStore.Images.Media.DATE_TAKEN,
                createdAtMillis,
            )
        }

        val uri = runCatching { resolver.insert(collection, values) }.getOrNull() ?: return false
        return try {
            resolver.openOutputStream(uri).use { output ->
                if (output == null) return@use false
                source.inputStream().use { input -> input.copyTo(output) }
                true
            }.also { written ->
                if (written && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    resolver.update(
                        uri,
                        ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                        null,
                        null,
                    )
                }
                if (!written) resolver.delete(uri, null, null)
            }
        } catch (_: Throwable) {
            runCatching { resolver.delete(uri, null, null) }
            false
        }
    }

    private fun mimeType(isVideo: Boolean, extension: String): String = when {
        isVideo -> "video/mp4"
        extension.equals("gif", ignoreCase = true) -> "image/gif"
        extension.equals("png", ignoreCase = true) -> "image/png"
        else -> "image/webp"
    }
}
