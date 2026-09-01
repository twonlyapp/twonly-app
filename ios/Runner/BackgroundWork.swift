import BackgroundTasks
import Foundation
import UIKit

/// Keeps a send alive while iOS is taking the app away.
///
/// Everything between the send button and the point where a background
/// `URLSession` owns the transfer — transcoding, encryption, one Signal ratchet
/// step per recipient — runs inside this process. iOS suspends a backgrounded
/// app within seconds unless something has asked it not to, which used to leave
/// a send stranded until the next launch.
///
/// Two mechanisms, because iOS offers no single one that covers both cases:
///
/// * A `UIApplication` background task assertion, taken by Rust for the length
///   of a preparation. It buys the roughly thirty seconds an app gets after
///   being backgrounded, which is what an ordinary send needs.
/// * A `BGProcessingTask`, scheduled whenever the app goes away with work
///   still outstanding. The system runs it later, on its own schedule, and it
///   is the only thing that resumes a send after the app has been suspended for
///   real. Nothing survives a force quit; that case is picked up on next launch.
enum BackgroundWork {
  static let processingTaskIdentifier = "eu.twonly.outbox-flush"

  /// Registered from `didFinishLaunchingWithOptions`. iOS requires every
  /// identifier to be registered before the app finishes launching.
  static func register() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: processingTaskIdentifier,
      using: nil
    ) { task in
      guard let task = task as? BGProcessingTask else {
        task.setTaskCompleted(success: false)
        return
      }
      run(task)
    }
  }

  /// Asks the system for a later chance to finish whatever is still queued.
  /// Submitting again replaces the pending request rather than stacking up.
  static func scheduleFlush() {
    let request = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // Simulators and devices with background refresh disabled refuse this.
      // The next launch still resumes everything, which is where this
      // behaviour was before.
      NSLog("twonly: could not schedule the outbox flush: \(error.localizedDescription)")
    }
  }

  /// The App Group container the app and its extensions share, which is where
  /// the Rust databases live.
  private static func runtimeDirectory() -> String? {
    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: runtimeAppGroup
      )
    else { return nil }
    let directory = container.appendingPathComponent("runtime", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      return directory.path
    } catch {
      NSLog("twonly: could not open the runtime directory: \(error.localizedDescription)")
      return nil
    }
  }

  private static let runtimeAppGroup = "group.eu.twonly.runtime"

  private static func run(_ task: BGProcessingTask) {
    // The system may reclaim the task at any point; ask Rust to stop by ending
    // the run, and reschedule so the work is not simply dropped.
    let queue = DispatchQueue(label: "eu.twonly.outbox-flush", qos: .utility)
    var finished = false
    let finish: (Bool) -> Void = { success in
      guard !finished else { return }
      finished = true
      task.setTaskCompleted(success: success)
    }
    task.expirationHandler = {
      scheduleFlush()
      finish(false)
    }
    queue.async {
      guard let directory = runtimeDirectory() else {
        finish(false)
        return
      }
      let response = directory.withCString { databaseDirectory in
        directory.withCString { dataDirectory in
          twonly_background_run(databaseDirectory, dataDirectory, nil)
        }
      }
      let json = response.map { pointer -> String in
        let value = String(cString: pointer)
        twonly_background_string_free(pointer)
        return value
      }
      let ok = json?.contains("\"ok\":true") ?? false
      // Keep a rolling reservation: as long as anything is unsent, there is a
      // scheduled chance to send it.
      scheduleFlush()
      finish(ok)
    }
  }
}

/// The background task assertion Rust takes around a media preparation.
///
/// Called over the C ABI so the preparation does not have to know it is on iOS.
/// Returns zero when no assertion could be taken, which Rust reads as "run
/// unprotected" rather than as a failure.
/// Rust calls this from one of its own worker threads, never from the main
/// one, so `UIApplication` is reached through the main queue rather than
/// directly. A `sync` hop cannot deadlock here for that same reason, and the
/// caller needs the identifier back before it can start working.
private func onMain<T>(_ work: @escaping () -> T) -> T {
  if Thread.isMainThread {
    return work()
  }
  return DispatchQueue.main.sync(execute: work)
}

@_cdecl("twonly_begin_background_task")
func twonlyBeginBackgroundTask() -> UInt64 {
  let identifier: UIBackgroundTaskIdentifier = onMain {
    var identifier = UIBackgroundTaskIdentifier.invalid
    identifier = UIApplication.shared.beginBackgroundTask(withName: "eu.twonly.media-preparation")
    {
      // The system is reclaiming the time. Ending the assertion here is
      // required; the preparation itself is resumed by the flush task or by
      // the next launch.
      if identifier != .invalid {
        UIApplication.shared.endBackgroundTask(identifier)
        identifier = .invalid
      }
    }
    return identifier
  }
  guard identifier != .invalid else { return 0 }
  // A preparation that outlives its assertion has to be picked up later.
  BackgroundWork.scheduleFlush()
  return UInt64(identifier.rawValue)
}

@_cdecl("twonly_end_background_task")
func twonlyEndBackgroundTask(_ identifier: UInt64) {
  guard identifier != 0, let raw = Int(exactly: identifier) else { return }
  onMain {
    UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: raw))
  }
}
