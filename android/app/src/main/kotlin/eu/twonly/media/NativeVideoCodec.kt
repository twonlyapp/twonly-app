package eu.twonly.media

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.OverlaySettings
import androidx.media3.common.util.Size
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.FrameDropEffect
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.StaticOverlaySettings
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.AudioEncoderSettings
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import com.google.common.collect.ImmutableList
import eu.twonly.MyApplication
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Burns the editor's overlay into the video and transcodes it, in a single
 * hardware pass. Media3 `Transformer` decodes and encodes through MediaCodec and
 * composites the overlay on the GPU with OpenGL, so no software codec and no
 * Flutter engine is involved.
 *
 * Called directly from Rust/JNI. Rust decides whether a render is needed at all
 * and owns every state transition around it; this only performs the work.
 */
@UnstableApi
object NativeVideoCodec {
    private const val TAG = "NativeVideoCodec"

    /**
     * Every send is normalised to 720p30 regardless of plan. The server caps a
     * single media object at 50MB on the free plan and 100MB on the paid ones,
     * and 720p30 is the largest format that keeps a clip of ordinary length
     * comfortably under the smaller of the two.
     */
    private const val SHORT_SIDE = 720
    private const val MAX_FRAME_RATE = 30.0

    /**
     * Bits per pixel per frame asked of the encoder. The previous 0.12 budget
     * reproduced the deliberately generous bitrate of a real-time camera
     * encode. Twonly is encoding an already captured clip and can use VBR plus
     * frame reordering, so 0.08 retains the useful detail without spending bits
     * on camera noise. The bitrate is derived from the output size and frame
     * rate rather than fixed, so smaller clips do not inherit a 720p budget.
     * Kept in sync with iOS so a clip has comparable size on either platform.
     */
    private const val BITS_PER_PIXEL_PER_FRAME = 0.08
    private const val MIN_BITRATE = 600_000
    private const val MAX_BITRATE = 2_500_000
    /** 720p30 at the rate above, used when the source cannot be probed. */
    private const val DEFAULT_BITRATE = 2_200_000
    private const val DEFAULT_FRAME_RATE = 30.0
    private const val AUDIO_BITRATE = 96_000
    private const val I_FRAME_INTERVAL_SECONDS = 2.0f
    private const val MAX_B_FRAMES = 2
    private const val PROGRESS_INTERVAL_MS = 500L
    /** No send should hold a background worker hostage indefinitely. */
    private const val RENDER_TIMEOUT_MINUTES = 30L

    @JvmStatic
    external fun reportProgress(mediaId: String, percent: Int)

    @JvmStatic
    fun render(
        inputPath: String,
        overlayPath: String?,
        outputPath: String,
        removeAudio: Boolean,
        trimStartMs: Long,
        trimEndMs: Long,
        mediaId: String,
    ): Boolean {
        val context = MyApplication.instance
        val output = File(outputPath)
        output.parentFile?.mkdirs()
        // Transformer refuses to write over an existing file.
        output.delete()

        val source = probe(inputPath)
        val bitrate = bitrateFor(source)

        val finished = CountDownLatch(1)
        var succeeded = false
        // Transformer posts its callbacks through a Looper, so it has to be
        // driven from the main thread while the calling Rust thread waits.
        val handler = Handler(Looper.getMainLooper())
        var transformer: Transformer? = null

        handler.post {
            try {
                val effects = buildEffects(overlayPath, source)
                val mediaItem = MediaItem.Builder()
                    .setUri(File(inputPath).toURI().toString())
                    // Transformer applies the cut while it decodes, so trimming
                    // costs nothing on top of the render that was happening
                    // anyway, and the recording on disk is left alone.
                    .setClippingConfiguration(clipping(trimStartMs, trimEndMs))
                    .build()
                val editedItem = EditedMediaItem.Builder(mediaItem)
                    .setRemoveAudio(removeAudio)
                    .setEffects(effects)
                    .build()

                val built = Transformer.Builder(context)
                    .setVideoMimeType(MimeTypes.VIDEO_H265)
                    // Without this the source audio is transmuxed untouched, and
                    // Android cameras record AMR-NB, which iOS cannot decode at
                    // all: AVPlayer then refuses the whole asset and the video
                    // never appears. AAC is the only audio codec both platforms
                    // are guaranteed to support.
                    .setAudioMimeType(MimeTypes.AUDIO_AAC)
                    .setEncoderFactory(
                        DefaultEncoderFactory.Builder(context)
                            .setRequestedVideoEncoderSettings(
                                VideoEncoderSettings.Builder()
                                    .setBitrate(bitrate)
                                    // Let quiet sections use fewer bits than the
                                    // average instead of padding every second to
                                    // the requested rate.
                                    .setBitrateMode(
                                        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR,
                                    )
                                    // Two seconds keeps seeking responsive without
                                    // paying the size penalty of an I-frame every
                                    // second. B-frames improve HEVC efficiency when
                                    // the device encoder supports them; fallback
                                    // below drops unsupported settings safely.
                                    .setiFrameIntervalSeconds(I_FRAME_INTERVAL_SECONDS)
                                    .setMaxBFrames(MAX_B_FRAMES)
                                    .build(),
                            )
                            .setRequestedAudioEncoderSettings(
                                AudioEncoderSettings.Builder()
                                    .setBitrate(AUDIO_BITRATE)
                                    .build(),
                            )
                            // Falling back lets a device without an HEVC encoder
                            // still produce a file rather than failing the send.
                            .setEnableFallback(true)
                            .build(),
                    )
                    .addListener(
                        object : Transformer.Listener {
                            override fun onCompleted(composition: Composition, result: ExportResult) {
                                // Recorded so a file the recipient cannot play
                                // can be diagnosed from a log rather than a
                                // round trip between two devices.
                                Log.i(
                                    TAG,
                                    "rendered ${result.width}x${result.height} " +
                                        "${result.videoMimeType}/${result.audioMimeType} " +
                                        "@ ${result.averageVideoBitrate}bps " +
                                        "(asked ${bitrate}bps for $source)",
                                )
                                succeeded = true
                                finished.countDown()
                            }

                            override fun onError(
                                composition: Composition,
                                result: ExportResult,
                                exception: ExportException,
                            ) {
                                Log.e(TAG, "video render failed", exception)
                                succeeded = false
                                finished.countDown()
                            }
                        },
                    )
                    .build()
                transformer = built
                built.start(editedItem, outputPath)
                pollProgress(handler, built, mediaId, finished)
            } catch (_: Throwable) {
                succeeded = false
                finished.countDown()
            }
        }

        val completed = finished.await(RENDER_TIMEOUT_MINUTES, TimeUnit.MINUTES)
        if (!completed) {
            handler.post { runCatching { transformer?.cancel() } }
            return false
        }
        return succeeded && output.isFile && output.length() > 0
    }

    /**
     * Grabs the first frame as a PNG. Only the decode needs the platform; Rust
     * scales and encodes the thumbnail itself, exactly as it does for stills.
     */
    @JvmStatic
    fun extractFrame(inputPath: String, outputPath: String): Boolean {
        val retriever = MediaMetadataRetriever()
        var frame: Bitmap? = null
        return try {
            retriever.setDataSource(inputPath)
            frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                ?: return false
            val output = File(outputPath)
            output.parentFile?.mkdirs()
            output.outputStream().use { stream ->
                frame.compress(Bitmap.CompressFormat.PNG, 100, stream)
            }
        } catch (_: Throwable) {
            false
        } finally {
            frame?.recycle()
            runCatching { retriever.release() }
        }
    }

    /** What the source actually is, as far as the platform will tell us. */
    private data class SourceVideo(val width: Int, val height: Int, val frameRate: Double)

    /**
     * Reads the displayed size and the frame rate. Both only steer the encoder
     * settings, so a source that refuses to be probed still renders — it just
     * falls back to the 1080p30 defaults.
     */
    /**
     * The slice of the recording the editor's cutter selected.
     *
     * Bounds arrive as milliseconds, with a negative value meaning the clip
     * keeps that end. A pair that does not describe a real slice is dropped
     * altogether: sending the untrimmed moment beats sending an empty file.
     */
    private fun clipping(trimStartMs: Long, trimEndMs: Long): MediaItem.ClippingConfiguration {
        if (trimStartMs <= 0L && trimEndMs <= 0L) {
            return MediaItem.ClippingConfiguration.UNSET
        }
        val start = trimStartMs.coerceAtLeast(0L)
        if (trimEndMs > 0L && trimEndMs <= start) {
            return MediaItem.ClippingConfiguration.UNSET
        }
        val builder = MediaItem.ClippingConfiguration.Builder().setStartPositionMs(start)
        if (trimEndMs > 0L) {
            builder.setEndPositionMs(trimEndMs)
        }
        return builder.build()
    }

    private fun probe(inputPath: String): SourceVideo? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(inputPath)
            fun key(id: Int) = retriever.extractMetadata(id)?.toIntOrNull()
            val storedWidth = key(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH) ?: return null
            val storedHeight = key(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT) ?: return null
            if (storedWidth <= 0 || storedHeight <= 0) return null
            // The frame is stored unrotated; a portrait clip from the camera is
            // a landscape frame plus a rotation, and it is the displayed size
            // that gets scaled and encoded.
            val rotation = key(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION) ?: 0
            val sideways = rotation % 180 != 0
            SourceVideo(
                width = if (sideways) storedHeight else storedWidth,
                height = if (sideways) storedWidth else storedHeight,
                frameRate = frameRate(inputPath),
            )
        } catch (_: Throwable) {
            null
        } finally {
            runCatching { retriever.release() }
        }
    }

    /**
     * `MediaMetadataRetriever` only exposes the frame rate from API 30, so it is
     * read off the track format instead, which every supported release has.
     */
    private fun frameRate(inputPath: String): Double {
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(inputPath)
            (0 until extractor.trackCount)
                .asSequence()
                .map { extractor.getTrackFormat(it) }
                .firstOrNull { it.getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true }
                // The key is optional, and is an int in practice but a float by
                // specification, so neither accessor can be relied on alone.
                ?.let { format ->
                    runCatching { format.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble() }
                        .recoverCatching { format.getFloat(MediaFormat.KEY_FRAME_RATE).toDouble() }
                        .getOrNull()
                }
                ?.takeIf { it > 0 }
                ?: DEFAULT_FRAME_RATE
        } catch (_: Throwable) {
            DEFAULT_FRAME_RATE
        } finally {
            runCatching { extractor.release() }
        }
    }

    /**
     * A rate the output size and frame rate actually justify. A fixed bitrate
     * either starves a 1080p60 clip or wastes bits on a 480p one; this spends
     * the same amount per pixel either way, within bounds that keep a send both
     * watchable and small enough to upload.
     */
    private fun bitrateFor(source: SourceVideo?): Int {
        if (source == null) return DEFAULT_BITRATE
        val scale = outputScale(source)
        val pixels = source.width * scale * source.height * scale
        val bits = pixels * outputFrameRate(source) * BITS_PER_PIXEL_PER_FRAME
        return bits.coerceIn(MIN_BITRATE.toDouble(), MAX_BITRATE.toDouble()).toInt()
    }

    /** The rate frames actually leave the pipeline at; never above the cap. */
    private fun outputFrameRate(source: SourceVideo) = minOf(source.frameRate, MAX_FRAME_RATE)

    /** How much the source is shrunk to meet [SHORT_SIDE]; never above 1. */
    private fun outputScale(source: SourceVideo): Double {
        val shortSide = minOf(source.width, source.height)
        return if (shortSide > SHORT_SIDE) SHORT_SIDE.toDouble() / shortSide else 1.0
    }

    private fun buildEffects(overlayPath: String?, source: SourceVideo?): Effects {
        val videoEffects = mutableListOf<androidx.media3.common.Effect>()
        // Cap the resolution before the overlay so both scale together. A source
        // already below the cap is left alone: scaling it up would only spend
        // bits on pixels the camera never recorded.
        if (source == null || outputScale(source) < 1.0) {
            videoEffects.add(Presentation.createForShortSide(SHORT_SIDE))
        }
        // A 60fps clip encoded at 30fps spends its whole budget on the frames it
        // keeps instead of halving the bits every frame gets. Dropping is only
        // asked for when there is something to drop: targeting 30 on a 24fps
        // source would make the effect duplicate frames back up to the target.
        if (source != null && source.frameRate > MAX_FRAME_RATE) {
            videoEffects.add(FrameDropEffect.createDefaultFrameDropEffect(MAX_FRAME_RATE.toFloat()))
        }
        if (overlayPath != null) {
            val bitmap = BitmapFactory.decodeFile(overlayPath)
            if (bitmap != null) {
                val overlays: ImmutableList<TextureOverlay> =
                    ImmutableList.of(FullFrameBitmapOverlay(bitmap))
                videoEffects.add(OverlayEffect(overlays))
            }
        }
        return Effects(ImmutableList.of(), ImmutableList.copyOf(videoEffects))
    }

    /**
     * Stretches the editor's overlay across the whole frame.
     *
     * Media3 draws a [BitmapOverlay] at the bitmap's own pixel size, centred:
     * the default settings only normalise the bitmap against the frame, they do
     * not fit it to one. The overlay is captured at the phone's device pixel
     * ratio over the video's on-screen rectangle, so it is comfortably larger
     * than the 720p a send is normalised to, and drawn as-is it would appear
     * enlarged with whatever the user put near an edge cut off. It shares the
     * video's aspect ratio, having been drawn over it, so filling the frame
     * does not distort it. The iOS renderer scales its overlay onto the render
     * size the same way.
     *
     * The frame size is only settled once every resolution-changing effect
     * ahead of this one has run, which is what [configure] reports, so the
     * scale is taken from there rather than from the probed source.
     */
    private class FullFrameBitmapOverlay(private val bitmap: Bitmap) : BitmapOverlay() {
        private var settings: OverlaySettings = StaticOverlaySettings.Builder().build()

        override fun getBitmap(presentationTimeUs: Long): Bitmap = bitmap

        override fun configure(videoSize: Size) {
            if (bitmap.width <= 0 || bitmap.height <= 0) return
            settings = StaticOverlaySettings.Builder()
                .setScale(
                    videoSize.width.toFloat() / bitmap.width,
                    videoSize.height.toFloat() / bitmap.height,
                )
                .build()
        }

        override fun getOverlaySettings(presentationTimeUs: Long): OverlaySettings = settings
    }

    private fun pollProgress(
        handler: Handler,
        transformer: Transformer,
        mediaId: String,
        finished: CountDownLatch,
    ) {
        val holder = ProgressHolder()
        handler.postDelayed(
            object : Runnable {
                override fun run() {
                    if (finished.count == 0L) return
                    runCatching {
                        if (transformer.getProgress(holder) == Transformer.PROGRESS_STATE_AVAILABLE) {
                            reportProgress(mediaId, holder.progress)
                        }
                    }
                    handler.postDelayed(this, PROGRESS_INTERVAL_MS)
                }
            },
            PROGRESS_INTERVAL_MS,
        )
    }
}
