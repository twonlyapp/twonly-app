import Flutter
import Darwin
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testNativeErrorReportingRequiresExplicitConsent() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    XCTAssertFalse(NativeErrorReporting.readConsent(at: nil))
    XCTAssertFalse(NativeErrorReporting.readConsent(at: url))
    for value in ["", "false", "corrupt", "1"] {
      try Data(value.utf8).write(to: url, options: .atomic)
      XCTAssertFalse(NativeErrorReporting.readConsent(at: url))
    }
    try Data("true".utf8).write(to: url, options: .atomic)
    XCTAssertTrue(NativeErrorReporting.readConsent(at: url))
    try Data("false".utf8).write(to: url, options: .atomic)
    XCTAssertFalse(NativeErrorReporting.readConsent(at: url))
  }

  func testRustCanResolveNativeCallbacks() {
    // Use the same lookup as Rust, without a static reference that would keep
    // an otherwise stripped callback alive just for this test.
    let process = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
    for symbol in [
      "twonly_schedule_direct_media_uploads",
      "twonly_direct_media_transfer_finished",
      "twonly_begin_background_task",
      "twonly_end_background_task",
      "twonly_decode_image_to_png",
      "twonly_extract_sticker_foreground",
      "twonly_render_video",
      "twonly_extract_video_frame",
      "twonly_save_to_gallery",
      "twonly_current_location",
    ] {
      XCTAssertNotNil(dlsym(process, symbol), "Rust cannot resolve \(symbol)")
    }
  }

  func testRustCanCallUploadScheduler() throws {
    typealias ScheduleUpload = @convention(c) (UnsafePointer<CChar>?) -> Bool
    let pointer = try XCTUnwrap(
      dlsym(UnsafeMutableRawPointer(bitPattern: -2), "twonly_schedule_direct_media_uploads"))
    let schedule = unsafeBitCast(pointer, to: ScheduleUpload.self)
    // A nil descriptor is rejected without creating a transfer, but proves
    // that the runtime lookup reaches the actual Swift implementation.
    XCTAssertFalse(schedule(nil))
  }

  func testRustCanCallStickerForegroundExtraction() throws {
    typealias ExtractForeground = @convention(c) (
      UnsafePointer<CChar>?, UnsafePointer<CChar>?
    ) -> Int32
    let pointer = try XCTUnwrap(
      dlsym(UnsafeMutableRawPointer(bitPattern: -2), "twonly_extract_sticker_foreground"))
    let extract = unsafeBitCast(pointer, to: ExtractForeground.self)
    XCTAssertEqual(extract(nil, nil), 0)
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = directory.appendingPathComponent("invalid.png")
    let output = directory.appendingPathComponent("foreground.png")
    try Data("not an image".utf8).write(to: source)
    let status = source.path.withCString { input in
      output.path.withCString { extract(input, $0) }
    }
    if #available(iOS 17.0, *) {
      XCTAssertEqual(status, 0)
    } else {
      XCTAssertEqual(status, -1)
    }
    XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
  }

  func testNativeUploadCompletionCanCallRustWithoutFlutter() throws {
    typealias TransferFinished = @convention(c) () -> Bool
    let pointer = try XCTUnwrap(
      dlsym(UnsafeMutableRawPointer(bitPattern: -2), "twonly_direct_media_transfer_finished"))
    let finished = unsafeBitCast(pointer, to: TransferFinished.self)
    // This callback must be callable without entering a Tokio runtime. A
    // background URLSession can deliver events before Flutter is initialized.
    _ = finished()
  }

}
