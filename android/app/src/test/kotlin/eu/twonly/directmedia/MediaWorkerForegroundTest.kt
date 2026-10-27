package eu.twonly.directmedia

import android.app.Application
import android.app.Notification
import android.app.ForegroundServiceStartNotAllowedException
import android.content.Context
import androidx.work.Data
import androidx.work.ForegroundUpdater
import androidx.work.ForegroundInfo
import androidx.work.ListenableWorker
import androidx.work.ProgressUpdater
import androidx.work.WorkerFactory
import androidx.work.WorkerParameters
import androidx.work.impl.utils.taskexecutor.WorkManagerTaskExecutor
import com.google.common.util.concurrent.Futures
import java.io.File
import java.nio.file.Files
import java.util.UUID
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import kotlin.coroutines.EmptyCoroutineContext
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36], application = Application::class)
class MediaWorkerForegroundTest {
    @Test
    fun promotionResultReflectsWhetherTheServiceStarted() {
        for (allowed in listOf(true, false)) {
            val worker = worker(Data.EMPTY, ForegroundUpdater { _, _, _ ->
                if (allowed) Futures.immediateVoidFuture()
                else Futures.immediateFailedFuture<Void>(ForegroundServiceStartNotAllowedException("background start"))
            })
            assertEquals(allowed, worker.setForegroundWhenAllowed(ForegroundInfo(1, Notification())))
        }
    }

    private fun worker(input: Data, foregroundUpdater: ForegroundUpdater): DirectMediaUploadWorker {
        val executor = Executor { it.run() }
        val params = WorkerParameters(
            UUID.randomUUID(), input, emptyList(), WorkerParameters.RuntimeExtras(), 0, 0,
            executor, EmptyCoroutineContext, WorkManagerTaskExecutor(executor),
            object : WorkerFactory() {
                override fun createWorker(context: Context, name: String, params: WorkerParameters): ListenableWorker? = null
            },
            ProgressUpdater { _, _, _ -> Futures.immediateVoidFuture() },
            foregroundUpdater,
        )
        return DirectMediaUploadWorker(RuntimeEnvironment.getApplication(), params)
    }

    private fun withUpload(block: (Data, MockWebServer) -> Unit) {
        val directory = Files.createTempDirectory("media-worker").toFile()
        val server = MockWebServer()
        try {
            val body = File(directory, "body").apply { writeText("encrypted media") }
            val request = JSONObject()
                .put("url", server.url("/upload").toString())
                .put("method", "POST")
                .put("headers", JSONObject())
                .put("body_path", body.absolutePath)
            // Each role uses the same worker, including small finalization calls.
            for (role in listOf("media", "manifest", "complete")) {
                val descriptor = File(directory, "descriptor.json")
                descriptor.writeText(JSONObject().put(role, request).toString())
                val input = Data.Builder()
                    .putString(DirectMediaUploadWorker.ATTACHMENT_ID, "test-attachment")
                    .putString(DirectMediaUploadWorker.ROLE, role)
                    .putString(DirectMediaUploadWorker.DESCRIPTOR_PATH, descriptor.absolutePath)
                    .putLong(DirectMediaUploadWorker.EXPIRES_AT, System.currentTimeMillis() / 1_000 + 600)
                    .build()
                block(input, server)
            }
        } finally {
            server.shutdown()
            directory.deleteRecursively()
        }
    }

    @Test
    fun deniedForegroundStartStillUploadsEveryRole() {
        withUpload { input, server ->
            server.enqueue(MockResponse().setResponseCode(204))
            var foregroundAttempts = 0
            val worker = worker(input, ForegroundUpdater { _, _, _ ->
                foregroundAttempts++
                // Future.get() wraps the platform exception in ExecutionException,
                // reproducing the reported production failure.
                Futures.immediateFailedFuture<Void>(ForegroundServiceStartNotAllowedException("background start"))
            })
            assertEquals(ListenableWorker.Result.success(), worker.doWork())
            assertEquals(1, foregroundAttempts)
            val sent = server.takeRequest(2, TimeUnit.SECONDS)!!
            assertEquals("encrypted media", sent.body.readUtf8())
        }
    }

    @Test
    @Config(sdk = [28, 36])
    fun allowedForegroundStartStillUploadsEveryRole() {
        withUpload { input, server ->
            server.enqueue(MockResponse().setResponseCode(204))
            var foregroundAttempts = 0
            val worker = worker(input, ForegroundUpdater { _, _, _ ->
                foregroundAttempts++
                Futures.immediateVoidFuture()
            })
            // WorkManager asks for this before starting expedited work on
            // Android < 12. A missing override fails before doWork is called.
            assertNotNull(worker.getForegroundInfoAsync().get(2, TimeUnit.SECONDS))
            assertEquals(ListenableWorker.Result.success(), worker.doWork())
            assertEquals(1, foregroundAttempts)
            assertNotNull(server.takeRequest(2, TimeUnit.SECONDS))
        }
    }

    @Test
    fun unrelatedForegroundFailureStillRetriesWithoutUploading() {
        withUpload { input, server ->
            val worker = worker(input, ForegroundUpdater { _, _, _ ->
                Futures.immediateFailedFuture<Void>(SecurityException("missing foreground permission"))
            })
            assertEquals(ListenableWorker.Result.retry(), worker.doWork())
            assertEquals(0, server.requestCount)
        }
    }
}
