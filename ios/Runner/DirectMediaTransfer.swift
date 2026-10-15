import Foundation

private struct DirectMediaRequest: Codable {
  let role: String
  let url: String
  let method: String
  let headers: [String: String]
  let bodyPath: String
}

/// A media upload names all three requests. A queued message envelope is the
/// single-request form: there is nothing to describe beyond the POST itself.
private struct DirectMediaDescriptor: Codable {
  let attachmentId: String
  let expiresAt: Int64
  let media: DirectMediaRequest
  let manifest: DirectMediaRequest?
  let complete: DirectMediaRequest?
}

/// Thin transport-only adapter. Rust supplies immutable request files and all
/// retry/expiry metadata; Swift only gives those files to background URLSession.
final class DirectMediaTransfer: NSObject, URLSessionTaskDelegate, URLSessionDelegate {
  static let shared = DirectMediaTransfer()
  static let sessionIdentifier = "eu.twonly.direct-media-transfer"

  private let defaults = UserDefaults.standard
  private let descriptorPrefix = "direct-media-descriptor-"
  private var backgroundCompletion: (() -> Void)?
  private var sessionStorage: URLSession?

  private lazy var decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  private var session: URLSession {
    if let sessionStorage { return sessionStorage }
    let configuration = URLSessionConfiguration.background(
      withIdentifier: Self.sessionIdentifier
    )
    configuration.sessionSendsLaunchEvents = true
    configuration.isDiscretionary = false
    configuration.waitsForConnectivity = true
    configuration.allowsCellularAccess = true
    let created = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    sessionStorage = created
    return created
  }

  func schedule(json: String) -> Bool {
    guard
      let data = json.data(using: .utf8),
      let descriptor = try? decoder.decode(DirectMediaDescriptor.self, from: data),
      descriptor.expiresAt > Int64(Date().timeIntervalSince1970),
      FileManager.default.fileExists(atPath: descriptor.media.bodyPath)
    else { return false }
    if let manifest = descriptor.manifest,
      !FileManager.default.fileExists(atPath: manifest.bodyPath)
    {
      return false
    }

    defaults.set(data, forKey: descriptorPrefix + descriptor.attachmentId)
    // Every durable transfer is created before any of them is resumed, so
    // process death cannot leave a media object with no corresponding manifest
    // task.
    guard let mediaTask = makeTask(descriptor.media, attachmentId: descriptor.attachmentId)
    else { return false }
    var manifestTask: URLSessionUploadTask?
    if let manifest = descriptor.manifest {
      guard let task = makeTask(manifest, attachmentId: descriptor.attachmentId) else {
        return false
      }
      manifestTask = task
    }
    mediaTask.resume()
    manifestTask?.resume()
    return true
  }

  func handleEvents(identifier: String, completion: @escaping () -> Void) -> Bool {
    guard identifier == Self.sessionIdentifier else { return false }
    backgroundCompletion = completion
    _ = session
    return true
  }

  private func makeTask(_ request: DirectMediaRequest, attachmentId: String) -> URLSessionUploadTask? {
    guard let url = URL(string: request.url) else { return nil }
    let fileURL = URL(fileURLWithPath: request.bodyPath)
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method
    for (name, value) in request.headers {
      urlRequest.setValue(value, forHTTPHeaderField: name)
    }
    let task = session.uploadTask(with: urlRequest, fromFile: fileURL)
    task.taskDescription = "\(attachmentId)|\(request.role)"
    NSLog("twonly: scheduled direct-media request %@", task.taskDescription ?? "unknown")
    return task
  }

  private func descriptor(attachmentId: String) -> DirectMediaDescriptor? {
    guard let data = defaults.data(forKey: descriptorPrefix + attachmentId) else { return nil }
    return try? decoder.decode(DirectMediaDescriptor.self, from: data)
  }

  private func request(_ role: String, from descriptor: DirectMediaDescriptor) -> DirectMediaRequest? {
    switch role {
    case "media": return descriptor.media
    case "manifest": return descriptor.manifest
    case "complete": return descriptor.complete
    default: return nil
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    guard
      let description = task.taskDescription,
      description.split(separator: "|", maxSplits: 1).count == 2
    else { return }
    let parts = description.split(separator: "|", maxSplits: 1)
    let attachmentId = String(parts[0])
    let role = String(parts[1])
    guard let descriptor = descriptor(attachmentId: attachmentId) else { return }
    let status = (task.response as? HTTPURLResponse)?.statusCode ?? 0
    let expired = descriptor.expiresAt <= Int64(Date().timeIntervalSince1970)
    let success = error == nil && (200...299).contains(status)

    NSLog(
      "twonly: finished direct-media request %@ HTTP %d error %@",
      description, status, error?.localizedDescription ?? "none"
    )
    // A callback only wakes Rust to read the server's durable state. A 202
    // still means uploading; callbacks may also arrive before Flutter starts.
    // Run after scheduling any completion/retry task below, so Rust cannot
    // remove its body file before URLSession has taken ownership of it.
    defer {
      if descriptor.manifest != nil {
        _ = twonly_direct_media_transfer_finished()
      }
    }

    if success && role == "media" {
      // A descriptor with no completion step — a queued message envelope — is
      // finished as soon as its POST is accepted.
      if let complete = descriptor.complete {
        makeTask(complete, attachmentId: attachmentId)?.resume()
      }
      return
    }
    if success {
      return
    }
    // Authentication/policy failures are permanent. Connectivity failures,
    // throttling and server failures remain retryable for the slot lifetime.
    let retryable = error != nil || status == 0 || status == 408 || status == 429 || status >= 500
    if !expired, retryable, let retry = request(role, from: descriptor) {
      let retryTask = makeTask(retry, attachmentId: attachmentId)
      retryTask?.earliestBeginDate = Date().addingTimeInterval(15)
      retryTask?.resume()
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didFinishCollecting metrics: URLSessionTaskMetrics
  ) {
    let transferSeconds = metrics.transactionMetrics.reduce(0.0) { total, transaction in
      guard let start = transaction.requestStartDate, let end = transaction.responseEndDate else {
        return total
      }
      return total + end.timeIntervalSince(start)
    }
    NSLog(
      "twonly: direct-media timing %@ total %.3fs HTTP %.3fs sent %lld bytes",
      task.taskDescription ?? "unknown", metrics.taskInterval.duration,
      transferSeconds, task.countOfBytesSent
    )
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    // The HTTP tasks can finish while Rust is not loaded. Ask the OS for a
    // durable reconciliation opportunity rather than relying on an in-process
    // callback or websocket receipt.
    BackgroundWork.scheduleFlush()
    DispatchQueue.main.async { [weak self] in
      let completion = self?.backgroundCompletion
      self?.backgroundCompletion = nil
      completion?()
    }
  }
}

/// C ABI called directly by Rust. Flutter and Dart never participate in
/// scheduling or executing these background uploads.
/// Keep this public and preserve global symbols when stripping the archive:
/// Rust finds it with dlsym, so neither Swift nor the linker can see the caller.
@_cdecl("twonly_schedule_direct_media_uploads")
public func twonlyScheduleDirectMediaUploads(_ descriptor: UnsafePointer<CChar>?) -> Bool {
  guard let descriptor else { return false }
  return DirectMediaTransfer.shared.schedule(json: String(cString: descriptor))
}
