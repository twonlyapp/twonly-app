import Foundation
import Flutter
import AVFoundation

class VideoCompressionChannel {
    private let channelName = "eu.twonly/videoCompression"
    
    // Hold a strong reference so the instance isn't immediately deallocated
    private static var activeInstance: VideoCompressionChannel?
    
    static func register(with messenger: FlutterBinaryMessenger) {
        let instance = VideoCompressionChannel()
        activeInstance = instance
        
        let channel = FlutterMethodChannel(name: instance.channelName, binaryMessenger: messenger)
        
        print("[VideoCompressionChannel] Registered channel: \(instance.channelName)")
        
        channel.setMethodCallHandler { [weak instance] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            print("[VideoCompressionChannel] Received method call: \(call.method)")
            instance?.handle(call, result: result, channel: channel)
        }
    }
    
    init() {}
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult, channel: FlutterMethodChannel) {
        if call.method == "compressVideo" {
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["input"] as? String,
                  let outputPath = args["output"] as? String else {
                print("[VideoCompressionChannel] Error: Missing input or output path in arguments")
                result(FlutterError(code: "INVALID_ARGS", message: "Input or output path missing", details: nil))
                return
            }
            
            print("[VideoCompressionChannel] Starting compressVideo from \(inputPath) to \(outputPath)")
            compress(inputPath: inputPath, outputPath: outputPath, channel: channel, result: result)
        } else {
            print("[VideoCompressionChannel] Method not implemented: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    func compress(inputPath: String, outputPath: String, channel: FlutterMethodChannel, result: @escaping FlutterResult) {
        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            print("[VideoCompressionChannel] Removing existing file at output path")
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        let asset = AVAsset(url: inputURL)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("[VideoCompressionChannel] Error: No video track found in asset")
            result(FlutterError(code: "NO_VIDEO_TRACK", message: "Video track not found", details: nil))
            return
        }
        
        let naturalSize = videoTrack.naturalSize
        let transform = videoTrack.preferredTransform
        let isPortrait = transform.a == 0 && abs(transform.b) == 1.0 && abs(transform.c) == 1.0 && transform.d == 0
        
        let originalWidth = isPortrait ? naturalSize.height : naturalSize.width
        let originalHeight = isPortrait ? naturalSize.width : naturalSize.height
        
        let maxDimension: CGFloat = 1920.0
        let minDimension: CGFloat = 1080.0
        
        var targetWidth = originalWidth
        var targetHeight = originalHeight
        
        if targetWidth > maxDimension || targetHeight > maxDimension {
            let widthRatio = maxDimension / targetWidth
            let heightRatio = minDimension / targetHeight
            let scaleFactor = min(widthRatio, heightRatio)
            
            targetWidth *= scaleFactor
            targetHeight *= scaleFactor
        }
        
        let targetBitrate = 3_000_000
        
        do {
            let reader = try AVAssetReader(asset: asset)
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            writer.shouldOptimizeForNetworkUse = true
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: Int(targetWidth),
                AVVideoHeightKey: Int(targetHeight),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: targetBitrate
                ]
            ]
            
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ])
            
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writerInput.expectsMediaDataInRealTime = false
            writerInput.transform = videoTrack.preferredTransform
            
            guard writer.canAdd(writerInput) else {
                result(FlutterError(code: "WRITER_ERROR", message: "Cannot add video writer input", details: nil))
                return
            }
            
            guard reader.canAdd(readerOutput) else {
                result(FlutterError(code: "READER_ERROR", message: "Cannot add video reader output", details: nil))
                return
            }
            reader.add(readerOutput)
            writer.add(writerInput)
            
            // Audio processing (re-encode to AAC)
            var audioReaderOutput: AVAssetReaderTrackOutput?
            var audioWriterInput: AVAssetWriterInput?
            
            if let audioTrack = asset.tracks(withMediaType: .audio).first {
                let audioReaderSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM
                ]
                let aReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)
                
                let audioWriterSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVNumberOfChannelsKey: 2,
                    AVSampleRateKey: 44100,
                    AVEncoderBitRateKey: 128000
                ]
                let aWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioWriterSettings)
                aWriterInput.expectsMediaDataInRealTime = false
                
                if reader.canAdd(aReaderOutput) && writer.canAdd(aWriterInput) {
                    reader.add(aReaderOutput)
                    writer.add(aWriterInput)
                    audioReaderOutput = aReaderOutput
                    audioWriterInput = aWriterInput
                } else {
                    print("[VideoCompressionChannel] Warning: Cannot add audio tracks, proceeding without audio")
                }
            }
            
            guard reader.startReading() else {
                result(FlutterError(code: "READER_ERROR", message: "Cannot start reading: \(reader.error?.localizedDescription ?? "unknown error")", details: nil))
                return
            }
            
            guard writer.startWriting() else {
                result(FlutterError(code: "WRITER_ERROR", message: "Cannot start writing: \(writer.error?.localizedDescription ?? "unknown error")", details: nil))
                return
            }
            writer.startSession(atSourceTime: .zero)
            
            let duration = CMTimeGetSeconds(asset.duration)
            let videoQueue = DispatchQueue(label: "videoQueue")
            let audioQueue = DispatchQueue(label: "audioQueue")
            let group = DispatchGroup()
            
            // State tracking flag to avoid sending completed messages prematurely
            var isVideoCompleted = false
            var isAudioCompleted = audioWriterInput == nil
            
            group.enter()
            writerInput.requestMediaDataWhenReady(on: videoQueue) {
                while writerInput.isReadyForMoreMediaData {
                    if reader.status != .reading {
                        if !isVideoCompleted {
                            isVideoCompleted = true
                            writerInput.markAsFinished()
                            group.leave()
                        }
                        return
                    }
                    
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        let timeInSeconds = CMTimeGetSeconds(presentationTime)
                        
                        if duration > 0 {
                            let progress = Int((timeInSeconds / duration) * 100)
                            DispatchQueue.main.async {
                                channel.invokeMethod("onProgress", arguments: ["progress": progress])
                            }
                        }
                        
                        writerInput.append(sampleBuffer)
                    } else {
                        if !isVideoCompleted {
                            isVideoCompleted = true
                            writerInput.markAsFinished()
                            group.leave()
                        }
                        break
                    }
                }
            }
            
            if let audioWriterInput = audioWriterInput, let audioReaderOutput = audioReaderOutput {
                group.enter()
                audioWriterInput.requestMediaDataWhenReady(on: audioQueue) {
                    while audioWriterInput.isReadyForMoreMediaData {
                        if reader.status != .reading {
                            if !isAudioCompleted {
                                isAudioCompleted = true
                                audioWriterInput.markAsFinished()
                                group.leave()
                            }
                            return
                        }
                        
                        if let sampleBuffer = audioReaderOutput.copyNextSampleBuffer() {
                            audioWriterInput.append(sampleBuffer)
                        } else {
                            if !isAudioCompleted {
                                isAudioCompleted = true
                                audioWriterInput.markAsFinished()
                                group.leave()
                            }
                            break
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                if reader.status == .completed {
                    writer.finishWriting {
                        if writer.status == .completed {
                            print("[VideoCompressionChannel] Compression completed successfully!")
                            result(outputPath)
                        } else {
                            print("[VideoCompressionChannel] Writer Error: \(writer.error?.localizedDescription ?? "Unknown error")")
                            result(FlutterError(code: "WRITER_ERROR", message: writer.error?.localizedDescription, details: nil))
                        }
                    }
                } else {
                    writer.cancelWriting()
                    print("[VideoCompressionChannel] Reader Error: \(reader.error?.localizedDescription ?? "Unknown error")")
                    result(FlutterError(code: "READER_ERROR", message: reader.error?.localizedDescription, details: nil))
                }
            }
            
        } catch {
            print("[VideoCompressionChannel] Exception: \(error.localizedDescription)")
            result(FlutterError(code: "COMPRESS_ERROR", message: error.localizedDescription, details: nil))
        }
    }
}
