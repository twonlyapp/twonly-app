import Flutter
import Darwin
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testRustCanResolveNativeCallbacks() {
    // Use the same lookup as Rust, without a static reference that would keep
    // an otherwise stripped callback alive just for this test.
    let process = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
    for symbol in [
      "twonly_schedule_direct_media_uploads",
      "twonly_begin_background_task",
      "twonly_end_background_task",
      "twonly_decode_image_to_png",
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

}
