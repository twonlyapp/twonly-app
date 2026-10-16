package eu.twonly.media

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File

/**
 * Called directly from Rust/JNI for the container formats Rust has no decoder
 * for, HEIC/HEIF above all. Rust owns every decision around this; the only job
 * here is to hand back pixels in a format Rust can read.
 *
 * HEIF decoding needs API 28. Below that the decode fails and Rust falls back
 * to sending the original file, exactly as it does for any unreadable input.
 */
object NativeImageCodec {
    @JvmStatic
    fun decodeToPng(inputPath: String, outputPath: String): Boolean {
        var bitmap: Bitmap? = null
        return try {
            bitmap = BitmapFactory.decodeFile(inputPath) ?: return false
            val output = File(outputPath)
            output.parentFile?.mkdirs()
            output.outputStream().use { stream ->
                // PNG is lossless, so nothing is thrown away before Rust
                // re-encodes to WebP at the quality it chose.
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            }
        } catch (_: Throwable) {
            false
        } finally {
            bitmap?.recycle()
        }
    }
}
