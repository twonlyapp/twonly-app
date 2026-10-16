package eu.twonly.directmedia

import android.app.Application
import androidx.work.WorkInfo
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.SocketPolicy
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], application = Application::class)
class DirectMediaTransferTest {
    private fun request(server: MockWebServer, file: File) = JSONObject()
        .put("url", server.url("/upload").toString())
        .put("method", "POST")
        .put("headers", JSONObject().put("Content-Type", "application/octet-stream"))
        .put("body_path", file.absolutePath)

    @Test
    fun replayKeepsTheExactRequestBytesAndReportsFailedCompletion() {
        val server = MockWebServer()
        val file = File.createTempFile("media", ".multipart")
        try {
            file.writeBytes(byteArrayOf(0, 1, 2, -1, 10))
            server.enqueue(MockResponse().setResponseCode(204))
            server.enqueue(MockResponse().setResponseCode(503))
            server.enqueue(MockResponse().setResponseCode(202))
            val transport = DirectMediaHttpTransfer()
            assertEquals(204, transport.upload(request(server, file)))
            assertEquals(503, transport.upload(request(server, file)))
            assertEquals(202, transport.upload(request(server, file)))
            repeat(3) {
                val sent = server.takeRequest(2, TimeUnit.SECONDS)!!
                assertArrayEquals(file.readBytes(), sent.body.readByteArray())
                assertEquals(file.length().toString(), sent.getHeader("Content-Length"))
            }
        } finally {
            file.delete()
            server.shutdown()
        }
    }

    @Test
    fun interruptedAttemptTimesOutAndTheSameRequestCanBeRetried() {
        val server = MockWebServer()
        val file = File.createTempFile("media", ".multipart")
        try {
            file.writeText("encrypted image")
            server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.NO_RESPONSE))
            val client = OkHttpClient.Builder().callTimeout(200, TimeUnit.MILLISECONDS).build()
            assertThrows(IOException::class.java) {
                DirectMediaHttpTransfer(client).upload(request(server, file))
            }
            server.enqueue(MockResponse().setResponseCode(204))
            assertEquals(204, DirectMediaHttpTransfer().upload(request(server, file)))
            assertEquals("encrypted image", server.takeRequest(2, TimeUnit.SECONDS)!!.body.readUtf8())
            assertEquals("encrypted image", server.takeRequest(2, TimeUnit.SECONDS)!!.body.readUtf8())
        } finally {
            file.delete()
            server.shutdown()
        }
    }

    @Test
    fun stalledSocketWritesTimeOut() {
        val server = MockWebServer()
        val file = File.createTempFile("media", ".multipart")
        val executor = Executors.newSingleThreadExecutor()
        try {
            // More than the socket buffers can hold, with a peer that never
            // reads: reproduces the write stall the old HttpURLConnection
            // connect/read timeouts did not cover.
            file.writeBytes(ByteArray(8 * 1024 * 1024))
            server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.STALL_SOCKET_AT_START))
            val client = OkHttpClient.Builder().writeTimeout(200, TimeUnit.MILLISECONDS).build()
            val result = executor.submit<Boolean> {
                try {
                    DirectMediaHttpTransfer(client).upload(request(server, file))
                    false
                } catch (_: IOException) { true }
            }
            assertTrue(result.get(3, TimeUnit.SECONDS))
        } finally {
            executor.shutdownNow()
            file.delete()
            server.shutdown()
        }
    }

    @Test
    fun stoppingWorkerCancelsItsInflightRequest() {
        val server = MockWebServer()
        val file = File.createTempFile("media", ".multipart")
        val executor = Executors.newSingleThreadExecutor()
        try {
            file.writeText("encrypted image")
            server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.NO_RESPONSE))
            val transport = DirectMediaHttpTransfer()
            val result = executor.submit<Boolean> {
                try { transport.upload(request(server, file)); false } catch (_: IOException) { true }
            }
            assertNotNull(server.takeRequest(2, TimeUnit.SECONDS))
            transport.cancel()
            assertTrue(result.get(2, TimeUnit.SECONDS))
        } finally {
            executor.shutdownNow()
            file.delete()
            server.shutdown()
        }
    }

    @Test
    fun recoveryKeepsLiveAndAcceptedUploadsButRepairsLostOrStuckWork() {
        val now = TimeUnit.MINUTES.toMillis(20)
        for (state in listOf(WorkInfo.State.RUNNING, WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED, WorkInfo.State.SUCCEEDED)) {
            assertEquals(RecoveryAction.KEEP, recoveryAction(state, now - 1_000, now, false))
        }
        for (state in listOf(null, WorkInfo.State.FAILED, WorkInfo.State.CANCELLED)) {
            assertEquals(RecoveryAction.ENQUEUE, recoveryAction(state, now, now, false))
        }
        assertEquals(RecoveryAction.REPLACE,
            recoveryAction(WorkInfo.State.RUNNING, 0, now, false))
        // Backoff/offline waiting is not a stalled connection.
        assertEquals(RecoveryAction.KEEP,
            recoveryAction(WorkInfo.State.ENQUEUED, 0, now, false))
        // Only completion may repeat after an accepted response (e.g. 202).
        assertEquals(RecoveryAction.ENQUEUE,
            recoveryAction(WorkInfo.State.SUCCEEDED, 0, now, true))
    }
}
