package eu.twonly.directmedia

import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit
import okhttp3.Call
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.asRequestBody
import okio.BufferedSink
import okio.ForwardingSink
import okio.buffer
import org.json.JSONObject

/** Bounds writes as well as reads, and lets WorkManager stop a live transfer. */
internal class DirectMediaHttpTransfer(
    private val client: OkHttpClient? = null,
) {
    @Volatile private var activeCall: Call? = null
    @Volatile private var cancelled = false

    fun cancel() {
        cancelled = true
        activeCall?.cancel()
    }

    fun upload(request: JSONObject, activity: () -> Unit = {}): Int {
        val file = File(request.getString("body_path"))
        if (!file.isFile) return 0
        val fileBody = file.asRequestBody()
        val body = object : RequestBody() {
            override fun contentType() = fileBody.contentType()
            override fun contentLength() = fileBody.contentLength()
            override fun writeTo(sink: BufferedSink) {
                val tracking = object : ForwardingSink(sink) {
                    override fun write(source: okio.Buffer, byteCount: Long) {
                        super.write(source, byteCount)
                        activity()
                    }
                }.buffer()
                fileBody.writeTo(tracking)
                tracking.flush()
            }
        }
        val builder = Request.Builder()
            .url(request.getString("url"))
            .method(request.optString("method", "POST"), body)
        val headers = request.getJSONObject("headers")
        for (name in headers.keys()) builder.header(name, headers.getString(name))
        val call = (client ?: uploadClient).newCall(builder.build())
        if (client == null) {
            // Allow large videos to keep making progress on slow connections.
            // The idle write timeout still detects a broken connection in 60s.
            val deadlineSeconds = maxOf(5 * 60L, 60 + file.length() / (16 * 1024))
            call.timeout().timeout(deadlineSeconds, TimeUnit.SECONDS)
        }
        activeCall = call
        try {
            if (cancelled) throw IOException("Media transfer stopped")
            activity()
            return call.execute().use { it.code }
        } finally {
            activeCall = null
        }
    }

    private companion object {
        val uploadClient = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .callTimeout(5, TimeUnit.MINUTES)
            .followRedirects(false)
            .followSslRedirects(false)
            .build()
    }
}
