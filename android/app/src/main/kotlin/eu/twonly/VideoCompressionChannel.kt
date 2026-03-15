package eu.twonly

import android.content.Context
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import com.otaliastudios.transcoder.Transcoder
import com.otaliastudios.transcoder.TranscoderListener
import com.otaliastudios.transcoder.strategy.DefaultAudioStrategy
import com.otaliastudios.transcoder.strategy.DefaultVideoStrategy
import com.otaliastudios.transcoder.strategy.TrackStrategy
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object VideoCompressionChannel {
    private const val CHANNEL = "eu.twonly/videoCompression"

    // Compression parameters defined natively (as requested)
    private const val VIDEO_BITRATE = 2_000_000L // 2 Mbps
    
    // Audio parameters defined natively
    private const val AUDIO_BITRATE = 128_000L // 128 kbps
    private const val AUDIO_SAMPLE_RATE = 44_100
    private const val AUDIO_CHANNELS = 2

    fun configure(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            try {
                if (call.method == "compressVideo") {
                    val arguments = call.arguments<Map<String, Any>>() ?: emptyMap()
                    val inputPath = arguments["input"] as? String
                    val outputPath = arguments["output"] as? String

                    if (inputPath == null || outputPath == null) {
                        result.error("INVALID_ARGS", "Input or output path missing", null)
                        return@setMethodCallHandler
                    }

                    val mainHandler = Handler(Looper.getMainLooper())

                    val baseVideoStrategy = DefaultVideoStrategy.Builder()
                        .keyFrameInterval(3f)
                        .bitRate(VIDEO_BITRATE)
                        .addResizer(com.otaliastudios.transcoder.resize.AtMostResizer(1920, 1080))
                        .build()

                    val trackStrategyClass = TrackStrategy::class.java
                    val hevcStrategy = java.lang.reflect.Proxy.newProxyInstance(
                        trackStrategyClass.classLoader,
                        arrayOf(trackStrategyClass)
                    ) { _, method, args ->
                        val result = if (args != null) method.invoke(baseVideoStrategy, *args) else method.invoke(baseVideoStrategy)
                        if (method.name == "createOutputFormat" && result is MediaFormat) {
                            result.setString(MediaFormat.KEY_MIME, MediaFormat.MIMETYPE_VIDEO_HEVC)
                        }
                        result
                    } as TrackStrategy

                    Transcoder.into(outputPath)
                        .addDataSource(inputPath)
                        .setVideoTrackStrategy(hevcStrategy)
                        .setAudioTrackStrategy(
                            DefaultAudioStrategy.builder()
                                .channels(AUDIO_CHANNELS)
                                .sampleRate(AUDIO_SAMPLE_RATE)
                                .bitRate(AUDIO_BITRATE)
                                .build()
                        )
                        .setListener(object : TranscoderListener {
                            override fun onTranscodeProgress(progress: Double) {
                                mainHandler.post {
                                    val mappedProgress = (progress * 100).toInt()
                                    channel.invokeMethod("onProgress", mapOf("progress" to mappedProgress))
                                }
                            }

                            override fun onTranscodeCompleted(successCode: Int) {
                                mainHandler.post {
                                    result.success(outputPath)
                                }
                            }

                            override fun onTranscodeCanceled() {
                                mainHandler.post {
                                    result.error("CANCELED", "Video compression canceled", null)
                                }
                            }

                            override fun onTranscodeFailed(exception: Throwable) {
                                mainHandler.post {
                                    result.error("FAILED", exception.message, null)
                                }
                            }
                        })
                        .transcode()

                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("EXCEPTION", e.message, null)
            }
        }
    }
}
