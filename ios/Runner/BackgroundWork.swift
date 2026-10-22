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
///   of a preparation. The execution allowance is finite and may expire;
///   preparations must leave durable work for a subsequent run.
/// * A `BGProcessingTask`, scheduled whenever the app goes away with work
///   still outstanding. The system runs it later, on its own schedule, and it
///   is the only thing that resumes a send after the app has been suspended for
///   real. Nothing survives a force quit; that case is picked up on next launch.
enum BackgroundWork {
  static let processingTaskIdentifier = "eu.twonly.outbox-flush"

  /// Registered from `didFinishLaunchingWithOptions`. iOS requires every
  /// identifier to be registered before the app finishes launching.
  static func register() {
    DatabaseExecutionCoordinator.register()
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
    // Flutter publishes this only after copying the complete legacy store,
    // including WAL sidecars. Never create a competing empty database first.
    guard FileManager.default.fileExists(
      atPath: directory.appendingPathComponent(".runtime_storage_migrated_v1").path
    ) else { return nil }
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
    NativeErrorReporting.breadcrumb("outbox_flush_started")
    // Register before queueing: expiration while waiting must cancel this run,
    // and a late expiration must never cancel a replacement worker.
    let runID = twonly_background_run_create()
    let queue = DispatchQueue(label: "eu.twonly.outbox-flush", qos: .utility)
    var finished = false
    let finishLock = NSLock()
    let finish: (Bool) -> Void = { success in
      finishLock.lock()
      guard !finished else {
        finishLock.unlock()
        return
      }
      finished = true
      finishLock.unlock()
      task.setTaskCompleted(success: success)
    }
    task.expirationHandler = {
      NativeErrorReporting.failure("outbox_flush_expired")
      twonly_database_operation_cancel(runID)
      scheduleFlush()
      // Completion belongs to the worker, after actual SQLite cleanup.
    }
    // Begin draining before the system's expiration callback. This is a short
    // work chunk, not an assumption about a guaranteed iOS execution grant.
    let earlyStop = DispatchWorkItem { twonly_database_operation_cancel(runID) }
    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 15, execute: earlyStop)
    queue.async {
      defer { earlyStop.cancel() }
      guard let directory = runtimeDirectory() else {
        twonly_background_run_dispose(runID)
        NativeErrorReporting.failure("outbox_flush_storage")
        finish(false)
        return
      }
      let response = directory.withCString { databaseDirectory in
        directory.withCString { dataDirectory in
          twonly_background_run_with_id(runID, databaseDirectory, dataDirectory, nil)
        }
      }
      let json = response.map { pointer -> String in
        let value = String(cString: pointer)
        twonly_background_string_free(pointer)
        return value
      }
      let result = json?.data(using: .utf8).flatMap {
        (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any]
      }
      let ok = result?["ok"] as? Bool ?? false
      let pending = (result?["pending_uploads"] as? Bool ?? false)
        || (result?["pending_messages"] as? Bool ?? false)
      if !ok { NativeErrorReporting.failure("outbox_flush") }
      NativeErrorReporting.breadcrumb("outbox_flush_finished")
      // Keep a rolling reservation: as long as anything is unsent, there is a
      // scheduled chance to send it.
      scheduleFlush()
      finish(ok && !pending)
    }
  }
}

/// Serialize native admission and assertion termination with UIKit lifecycle
/// notifications. Callers need admission's result before starting their work.
private func onMain<T>(_ work: @escaping () -> T) -> T {
  if Thread.isMainThread {
    return work()
  }
  return DispatchQueue.main.sync(execute: work)
}

@_cdecl("twonly_end_background_task")
public func twonlyEndBackgroundTask(_ identifier: UInt64) {
  onMain { DatabaseExecutionCoordinator.end(identifier) }
}

@_cdecl("twonly_begin_database_operation")
public func twonlyBeginDatabaseOperation(_ operation: UInt64) -> UInt64 {
  onMain {
    guard UIApplication.shared.applicationState == .active else { return 0 }
    return DatabaseExecutionCoordinator.begin(operation: operation)
  }
}

/// All state and UIKit calls are confined to the main queue. Lease IDs are
/// independent of UIKit IDs, so late Rust cleanup cannot end a newer assertion.
private enum DatabaseExecutionCoordinator {
  private static var assertion = UIBackgroundTaskIdentifier.invalid
  private static var nextLease: UInt64 = 1
  private static var leases: [UInt64: UInt64] = [:]
  private static var expired = false
  private static var observers: [NSObjectProtocol] = []

  static func register() {
    guard observers.isEmpty else { return }
    let center = NotificationCenter.default
    observers.append(center.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
    ) { _ in
      // Optional exports stop as soon as we leave the foreground, reserving
      // the assertion's remaining budget for native SQLite cleanup.
      twonly_database_set_foreground(false)
      cancelDatabaseOperations()
      BackgroundWork.scheduleFlush()
    })
    observers.append(center.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      expired = false
      twonly_database_set_foreground(true)
    })
    twonly_database_set_foreground(UIApplication.shared.applicationState == .active)
  }

  static func begin(operation: UInt64?) -> UInt64 {
    dispatchPrecondition(condition: .onQueue(.main))
    guard !expired else { return 0 }
    if assertion == .invalid {
      assertion = UIApplication.shared.beginBackgroundTask(withName: "eu.twonly.native-work") {
        expire()
      }
      guard assertion != .invalid else { return 0 }
    }
    let lease = nextLease
    nextLease &+= 1
    leases[lease] = operation ?? 0
    return lease
  }

  static func end(_ lease: UInt64) {
    dispatchPrecondition(condition: .onQueue(.main))
    guard leases.removeValue(forKey: lease) != nil else { return }
    if leases.isEmpty { endAssertion() }
  }

  private static func cancelDatabaseOperations() {
    for operation in leases.values where operation != 0 {
      twonly_database_operation_cancel(operation)
    }
  }

  private static func endAssertion() {
    guard assertion != .invalid else { return }
    let previous = assertion
    assertion = .invalid
    UIApplication.shared.endBackgroundTask(previous)
  }

  fileprivate static func expire() {
    dispatchPrecondition(condition: .onQueue(.main))
    expired = true
    cancelDatabaseOperations()
    // Expiration is an emergency terminal event, not extra cleanup time.
    // Late lease releases become no-ops for this UIKit assertion.
    endAssertion()
  }
}

@_cdecl("twonly_database_is_foreground")
public func twonlyDatabaseIsForeground() -> Bool {
  onMain { UIApplication.shared.applicationState == .active }
}
