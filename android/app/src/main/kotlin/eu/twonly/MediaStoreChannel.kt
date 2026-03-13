package eu.twonly

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.io.OutputStream

object MediaStoreChannel {
    private const val CHANNEL = "eu.twonly/mediaStore"

    fun configure(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            try {
                if (call.method == "safeFileToDownload") {
                    val arguments = call.arguments<Map<String, String>>() as Map<String, String>
                    val sourceFile = arguments["sourceFile"]
                    if (sourceFile == null) {
                        result.success(false)
                    } else {
                        val inputStream = FileInputStream(File(sourceFile))
                        val outputName = File(sourceFile).name.takeIf { it.isNotEmpty() } ?: "memories.zip"

                        val savedUri = saveZipToDownloads(context, outputName, inputStream)
                        if (savedUri != null) {
                            result.success(savedUri.toString())
                        } else {
                            result.error("SAVE_FAILED", "Could not save ZIP", null)
                        }
                    }
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("EXCEPTION", e.message, null)
            }
        }
    }

    private fun saveZipToDownloads(
        context: Context,
        fileName: String = "archive.zip",
        sourceStream: InputStream
    ): android.net.Uri? {
        val resolver = context.contentResolver

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/zip")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri("external")
        }

        val uri = resolver.insert(collection, contentValues) ?: return null

        try {
            resolver.openOutputStream(uri).use { out: OutputStream? ->
                requireNotNull(out) { "Unable to open output stream" }
                sourceStream.use { input ->
                    input.copyTo(out)
                }
                out.flush()
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val done = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
                resolver.update(uri, done, null, null)
            }

            return uri
        } catch (e: Exception) {
            try { resolver.delete(uri, null, null) } catch (_: Exception) {}
            return null
        }
    }
}
