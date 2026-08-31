import AVFoundation
import CoreImage
import Foundation
import ImageIO
import VideoToolbox

/// Burns the editor's overlay into the video and transcodes it in one pass:
/// Core Image composites each frame on the GPU and VideoToolbox encodes it.
/// No ffmpeg and no Flutter engine, so a send can finish in the background.
///
/// Called directly from Rust. Rust decides whether a render is needed and owns
/// every state transition around it; this only performs the work.
enum NativeVideoCodec {
  /// Every send is normalised to 720p30 regardless of plan. The server caps a
  /// single media object at 50MB on the free plan and 100MB on the paid ones,
  /// and 720p30 is the largest format that keeps a clip of ordinary length
  /// comfortably under the smaller of the two.
  private static let maxLongSide: CGFloat = 1280
  private static let maxShortSide: CGFloat = 720
  private static let maxFrameRate: Double = 30

  /// Bits per pixel per frame asked of VideoToolbox. The previous 0.12 budget
  /// reproduced the deliberately generous bitrate of a real-time camera encode.
  /// Twonly is encoding an already captured clip and can use VBR plus frame
  /// reordering, so 0.08 retains the useful detail without spending bits on
  /// camera noise. The bitrate is derived from the output size and frame rate
  /// rather than fixed, so smaller clips do not inherit a 720p budget. Kept in
  /// sync with Android so a clip has comparable size on either platform.
  ///
  /// `AVAssetExportSession` presets cannot express any of this, which is why
  /// the reader/writer pair is driven by hand.
  private static let bitsPerPixelPerFrame: Double = 0.08
  private static let minBitrate = 600_000
  private static let maxBitrate = 2_500_000
  private static let defaultFrameRate: Double = 30
  private static let audioBitrate = 96_000
  private static let keyFrameInterval: Double = 2

  static func render(
    inputPath: String,
    overlayPath: String?,
    outputPath: String,
    removeAudio: Bool,
    onProgress: @escaping (Int) -> Void
  ) -> Bool {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inputPath))
    guard let videoTrack = asset.tracks(withMediaType: .video).first else { return false }

    let outputURL = URL(fileURLWithPath: outputPath)
    try? FileManager.default.removeItem(at: outputURL)
    try? FileManager.default.createDirectory(
      at: outputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    // The frame is stored unrotated; its displayed size is what has to be
    // scaled, and what the overlay was drawn against.
    let transformed = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    let displayed = CGSize(width: abs(transformed.width), height: abs(transformed.height))
    let target = evenScaledSize(displayed)
    guard target.width > 0, target.height > 0 else { return false }

    // A track with no declared frame rate still has to be given a budget.
    let nominal = Double(videoTrack.nominalFrameRate)
    let sourceFrameRate = nominal > 0 ? nominal : defaultFrameRate
    let frameRate = min(sourceFrameRate, maxFrameRate)
    let videoBitrate = bitrate(for: target, frameRate: frameRate)

    let overlay = overlayPath.flatMap { CIImage(contentsOf: URL(fileURLWithPath: $0)) }
    let composition = ciComposition(
      for: asset,
      target: target,
      overlay: overlay,
      // A 60fps clip encoded at 30fps spends its whole budget on the frames it
      // keeps instead of halving the bits every frame gets. The source rate is
      // left alone when it is already at or below the cap, so a 24fps clip is
      // not resampled up to 30.
      frameRate: sourceFrameRate > maxFrameRate ? maxFrameRate : nil
    )

    do {
      let reader = try AVAssetReader(asset: asset)
      let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
      writer.shouldOptimizeForNetworkUse = true

      let videoOutput = AVAssetReaderVideoCompositionOutput(
        videoTracks: asset.tracks(withMediaType: .video),
        videoSettings: [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
      )
      videoOutput.videoComposition = composition
      videoOutput.alwaysCopiesSampleData = false

      let videoInput = AVAssetWriterInput(
        mediaType: .video,
        outputSettings: [
          AVVideoCodecKey: AVVideoCodecType.hevc,
          AVVideoWidthKey: Int(target.width),
          AVVideoHeightKey: Int(target.height),
          // The source frame rate lets rate control budget a whole second
          // instead of guessing from the samples it has seen so far.
          AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: videoBitrate,
            AVVideoExpectedSourceFrameRateKey: Int(frameRate.rounded()),
            AVVideoProfileLevelKey: kVTProfileLevel_HEVC_Main_AutoLevel,
            // A two-second GOP still seeks accurately while spending less on
            // intra frames than the previous one-second default. VideoToolbox
            // can reorder frames here because this is an offline export.
            AVVideoMaxKeyFrameIntervalDurationKey: keyFrameInterval,
            AVVideoAllowFrameReorderingKey: true,
          ],
        ]
      )
      videoInput.expectsMediaDataInRealTime = false
      // The composition already applied the track's transform, so tagging the
      // output again would rotate it a second time on playback.

      guard reader.canAdd(videoOutput), writer.canAdd(videoInput) else { return false }
      reader.add(videoOutput)
      writer.add(videoInput)

      var audioOutput: AVAssetReaderTrackOutput?
      var audioInput: AVAssetWriterInput?
      if !removeAudio, let audioTrack = asset.tracks(withMediaType: .audio).first {
        let audioChannels = channelCount(for: audioTrack)
        let output = AVAssetReaderTrackOutput(
          track: audioTrack,
          outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM]
        )
        let input = AVAssetWriterInput(
          mediaType: .audio,
          outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            // Do not turn the common mono camera track into stereo. It carries
            // no additional information and makes the AAC encoder less
            // efficient at the same total bitrate.
            AVNumberOfChannelsKey: audioChannels,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: audioBitrate,
          ]
        )
        input.expectsMediaDataInRealTime = false
        if reader.canAdd(output), writer.canAdd(input) {
          reader.add(output)
          writer.add(input)
          audioOutput = output
          audioInput = input
        }
      }

      guard reader.startReading(), writer.startWriting() else { return false }
      writer.startSession(atSourceTime: .zero)

      let duration = CMTimeGetSeconds(asset.duration)
      let group = DispatchGroup()
      pump(
        input: videoInput,
        output: videoOutput,
        label: "video",
        group: group,
        duration: duration,
        onProgress: onProgress
      )
      if let audioInput, let audioOutput {
        pump(
          input: audioInput,
          output: audioOutput,
          label: "audio",
          group: group,
          duration: nil,
          onProgress: nil
        )
      }
      group.wait()

      guard reader.status != .failed else {
        writer.cancelWriting()
        return false
      }
      let finished = DispatchSemaphore(value: 0)
      writer.finishWriting { finished.signal() }
      finished.wait()

      guard writer.status == .completed else { return false }
      let size = try FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? Int
      return (size ?? 0) > 0
    } catch {
      return false
    }
  }

  /// Core Image runs on the GPU, and unlike `AVVideoCompositionCoreAnimationTool`
  /// it also works with a reader/writer pair, which is what lets the bitrate
  /// stay under our control.
  private static func ciComposition(
    for asset: AVAsset,
    target: CGSize,
    overlay: CIImage?,
    frameRate: Double?
  ) -> AVMutableVideoComposition {
    let composition = AVMutableVideoComposition(asset: asset) { request in
      let source = request.sourceImage
      var frame = source
      if source.extent.width > 0, source.extent.height > 0 {
        frame = source.transformed(
          by: CGAffineTransform(
            scaleX: target.width / source.extent.width,
            y: target.height / source.extent.height
          )
        )
      }
      if let overlay, overlay.extent.width > 0, overlay.extent.height > 0 {
        let scaled = overlay.transformed(
          by: CGAffineTransform(
            scaleX: target.width / overlay.extent.width,
            y: target.height / overlay.extent.height
          )
        )
        frame = scaled.composited(over: frame)
      }
      request.finish(with: frame, context: nil)
    }
    composition.renderSize = target
    if let frameRate {
      composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
    }
    return composition
  }

  /// A rate the output size and frame rate actually justify. A fixed bitrate
  /// either starves a 1080p60 clip or wastes bits on a 480p one; this spends the
  /// same amount per pixel either way, within bounds that keep a send both
  /// watchable and small enough to upload.
  private static func bitrate(for size: CGSize, frameRate: Double) -> Int {
    let bits = Double(size.width) * Double(size.height) * frameRate * bitsPerPixelPerFrame
    return min(maxBitrate, max(minBitrate, Int(bits.rounded())))
  }

  /// Keeps mono sources mono and limits unusual multichannel camera input to
  /// stereo, which is the most widely supported AAC layout on mobile players.
  private static func channelCount(for track: AVAssetTrack) -> Int {
    guard let rawDescription = track.formatDescriptions.first else { return 2 }
    // The track is an audio track, so its descriptions use the corresponding
    // Core Media alias. AVFoundation exposes the collection as `[Any]`.
    let description = rawDescription as! CMAudioFormatDescription
    guard let format = CMAudioFormatDescriptionGetStreamBasicDescription(description) else {
      return 2
    }
    return min(2, max(1, Int(format.pointee.mChannelsPerFrame)))
  }

  /// Caps the long and short side the way the previous exporter did, and never
  /// scales a smaller source up. Hardware encoders produce edge artifacts on
  /// odd dimensions.
  private static func evenScaledSize(_ size: CGSize) -> CGSize {
    guard size.width > 0, size.height > 0 else { return .zero }
    let scale = min(
      1,
      min(maxLongSide / max(size.width, size.height), maxShortSide / min(size.width, size.height))
    )
    let width = (size.width * scale).rounded(.down)
    let height = (size.height * scale).rounded(.down)
    return CGSize(
      width: width - width.truncatingRemainder(dividingBy: 2),
      height: height - height.truncatingRemainder(dividingBy: 2)
    )
  }

  private static func pump(
    input: AVAssetWriterInput,
    output: AVAssetReaderOutput,
    label: String,
    group: DispatchGroup,
    duration: Double?,
    onProgress: ((Int) -> Void)?
  ) {
    group.enter()
    let queue = DispatchQueue(label: "eu.twonly.video.\(label)")
    input.requestMediaDataWhenReady(on: queue) {
      while input.isReadyForMoreMediaData {
        guard let sample = output.copyNextSampleBuffer() else {
          input.markAsFinished()
          group.leave()
          return
        }
        if let duration, duration > 0, let onProgress {
          let seconds = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample))
          onProgress(Int((seconds / duration * 100).rounded()))
        }
        input.append(sample)
      }
    }
  }
}

/// C ABI called directly by Rust.
@_cdecl("twonly_render_video")
func twonlyRenderVideo(
  _ input: UnsafePointer<CChar>?,
  _ overlay: UnsafePointer<CChar>?,
  _ output: UnsafePointer<CChar>?,
  _ removeAudio: Bool,
  _ mediaId: UnsafePointer<CChar>?,
  _ progress: @convention(c) (UnsafePointer<CChar>?, Int32) -> Void
) -> Bool {
  guard let input, let output, let mediaId else { return false }
  let mediaIdString = String(cString: mediaId)
  return NativeVideoCodec.render(
    inputPath: String(cString: input),
    overlayPath: overlay.map { String(cString: $0) },
    outputPath: String(cString: output),
    removeAudio: removeAudio,
    onProgress: { percent in
      mediaIdString.withCString { progress($0, Int32(percent)) }
    }
  )
}

/// Grabs the first frame as a PNG. Only the decode needs the platform; Rust
/// scales and encodes the thumbnail itself, exactly as it does for stills.
@_cdecl("twonly_extract_video_frame")
func twonlyExtractVideoFrame(
  _ input: UnsafePointer<CChar>?,
  _ output: UnsafePointer<CChar>?
) -> Bool {
  guard let input, let output else { return false }
  let asset = AVURLAsset(url: URL(fileURLWithPath: String(cString: input)))
  let generator = AVAssetImageGenerator(asset: asset)
  // The frame has to arrive upright, the way the video is played back.
  generator.appliesPreferredTrackTransform = true
  guard let frame = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return false }

  let outputURL = URL(fileURLWithPath: String(cString: output))
  try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  guard
    let destination = CGImageDestinationCreateWithURL(
      outputURL as CFURL, "public.png" as CFString, 1, nil)
  else { return false }
  CGImageDestinationAddImage(destination, frame, nil)
  return CGImageDestinationFinalize(destination)
}
