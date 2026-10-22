import Foundation
import Intents
import UserNotifications
import WidgetKit
import rust_lib_twonly

private let runtimeAppGroup = "group.eu.twonly.runtime"

/// Optional maintenance runs before releasing the content handler. The whole
/// push shares one earlier deadline, reserving time for native lock cleanup.
private let finalizeDeadlineMs: UInt64 = 5_000
private let notificationRunBudgetMs: UInt64 = 25_000

private struct NativeNotificationResponse: Decodable {
  let ok: Bool
  let widgetRefresh: Bool
  let batch: NativeNotificationBatch?
  let fallback: NativeNotificationPresentation?
  let error: String?

  enum CodingKeys: String, CodingKey {
    case ok, batch, fallback, error
    case widgetRefresh = "widget_refresh"
  }
}

private struct NativeNotificationPresentation: Decodable {
  let title: String
  let body: String
}

private struct NativeNotificationBatch: Decodable {
  let additions: [NativeNotificationAddition]
  let removals: [String]
  let badgeCount: Int64
  let completed: Bool

  enum CodingKeys: String, CodingKey {
    case additions, removals, completed
    case badgeCount = "badge_count"
  }
}

private struct NativeNotificationAddition: Decodable {
  let eventId: String
  let notificationId: String
  let conversationId: String?
  let senderId: Int64
  let senderName: String
  let title: String
  let body: String
  let conversationName: String?
  let isGroup: Bool
  let messageId: String?
  let kind: String
  let content: String?
  let createdAt: Int64
  let avatarPath: String?
  let conversationAvatarPath: String?

  enum CodingKeys: String, CodingKey {
    case kind, content, title, body
    case eventId = "event_id"
    case notificationId = "notification_id"
    case conversationId = "conversation_id"
    case senderId = "sender_id"
    case senderName = "sender_name"
    case conversationName = "conversation_name"
    case isGroup = "is_group"
    case messageId = "message_id"
    case createdAt = "created_at"
    case avatarPath = "avatar_path"
    case conversationAvatarPath = "conversation_avatar_path"
  }

  var notificationGroup: String {
    return "chat:\(conversationId ?? ""):sender:\(senderId):kind:\(kind)"
  }
}

private struct RenderedNotification {
  let addition: NativeNotificationAddition
  let eventIds: [String]
  let notificationIds: [String]
  let replacingRequestIds: [String]

  var body: String {
    return addition.body
  }
}

final class NotificationService: UNNotificationServiceExtension {
  private let finishLock = NSLock()
  private var hasFinished = false
  private var runID: UInt64 = 0
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var fallbackContent: UNNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    NSLog("Native push received: requestId=%@", request.identifier)
    NativeErrorReporting.startIfAllowed()
    NativeErrorReporting.breadcrumb("notification_processing_started")
    finishLock.lock()
    self.contentHandler = contentHandler
    fallbackContent = request.content
    finishLock.unlock()

    let run = twonly_notification_run_create(notificationRunBudgetMs)
    finishLock.lock()
    runID = run
    let alreadyFinished = hasFinished
    finishLock.unlock()
    if alreadyFinished {
      twonly_database_operation_cancel(run)
      DispatchQueue.global(qos: .userInitiated).async { twonly_notification_run_finish(run) }
      return
    }
    guard run != 0 else {
      deliverFallback(reason: "notification runtime is unavailable", operation: "notification_runtime")
      return
    }

    guard let runtimeDirectory = Self.runtimeDirectory() else {
      deliverFallback(reason: "shared runtime directory is unavailable", operation: "notification_storage")
      return
    }

    runtimeDirectory.withCString { directory in
      request.identifier.withCString { identifier in
        twonly_notification_received(directory, identifier, 0)
      }
    }

    DispatchQueue.global(qos: .userInitiated).async {
      guard let response = Self.processWakeup(run: run, runtimeDirectory: runtimeDirectory) else {
        self.deliverFallback(reason: "notification worker returned no response", operation: "notification_response")
        return
      }
      guard response.ok else {
        self.deliverFallback(
          reason: response.error ?? "notification worker failed",
          presentation: response.fallback
        )
        return
      }
      if response.widgetRefresh {
        WidgetCenter.shared.reloadAllTimelines()
      }
      guard let batch = response.batch, !batch.additions.isEmpty else {
        // Nothing is waiting on screen for this wake-up — widget-only media, a
        // story the user muted or one that already expired — so the deferred
        // work runs while the extension is still guaranteed its time, rather
        // than after the content handler has made it eligible for termination.
        Self.finalizeRuntime(run: run)
        // The worker ran and decided there is nothing to announce. With the
        // notification filtering entitlement, empty content drops the push
        // instead of showing its "You got a new message" placeholder.
        NSLog("Twonly wake-up had nothing to announce; suppressing the alert")
        self.finish(with: UNNotificationContent())
        return
      }
      self.render(batch: batch, original: request.content, run: run)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    deliverFallback(reason: "notification service extension timed out", operation: "notification_expired")
  }

  private func render(batch: NativeNotificationBatch, original: UNNotificationContent, run: UInt64) {
    guard !isCompleting else { return }
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { [weak self] delivered in
      self?.render(
        groups: Self.groupedAdditions(batch.additions, delivered: delivered.map(\.request)),
        badgeCount: batch.badgeCount,
        original: original,
        run: run
      )
    }
  }

  private static func groupedAdditions(
    _ additions: [NativeNotificationAddition], delivered: [UNNotificationRequest]
  ) -> [RenderedNotification] {
    // Keep one alert per sender and kind, including across separate wake-ups.
    let grouped = Dictionary(grouping: additions) {
      $0.notificationGroup
    }
    return grouped.values.compactMap { entries -> RenderedNotification? in
      guard let latest = entries.sorted(by: {
        if $0.createdAt == $1.createdAt { return $0.eventId < $1.eventId }
        return $0.createdAt < $1.createdAt
      }).last else { return nil }
      let previous = delivered.filter {
        $0.content.userInfo["notification_group"] as? String == latest.notificationGroup
      }
      return RenderedNotification(
        addition: latest,
        eventIds: entries.map(\.eventId),
        notificationIds: [latest.notificationId],
        replacingRequestIds: previous.map(\.identifier)
      )
    }.sorted {
      if $0.addition.createdAt == $1.addition.createdAt {
        return $0.addition.eventId < $1.addition.eventId
      }
      return $0.addition.createdAt < $1.addition.createdAt
    }
  }

  private func render(
    groups: [RenderedNotification], badgeCount: Int64, original: UNNotificationContent, run: UInt64
  ) {
    guard !isCompleting else { return }
    let center = UNUserNotificationCenter.current()
    let group = DispatchGroup()
    let stateLock = NSLock()
    var deliveredEventIds: [String] = []
    var replacedRequestIds: [String] = []
    var finalContent: UNNotificationContent = original

    for (index, rendered) in groups.enumerated() {
      group.enter()
      communicationContent(for: rendered, badgeCount: badgeCount, original: original) {
        content in
        guard !self.isCompleting else {
          group.leave()
          return
        }
        let isFinal = index == groups.count - 1
        if isFinal {
          stateLock.lock()
          finalContent = content
          deliveredEventIds.append(contentsOf: rendered.eventIds)
          replacedRequestIds.append(contentsOf: rendered.replacingRequestIds)
          stateLock.unlock()
          group.leave()
          return
        }

        let request = UNNotificationRequest(
          identifier: rendered.addition.notificationGroup,
          content: content,
          trigger: nil
        )
        center.add(request) { error in
          if let error {
            NSLog("Could not schedule Twonly notification: \(error)")
          } else {
            stateLock.lock()
            deliveredEventIds.append(contentsOf: rendered.eventIds)
            // A local replacement may reuse the same request identifier.
            replacedRequestIds.append(contentsOf: rendered.replacingRequestIds.filter {
              $0 != request.identifier
            })
            stateLock.unlock()
          }
          group.leave()
        }
      }
    }

    group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
      guard let self, !self.isCompleting else { return }
      stateLock.lock()
      let eventIds = deliveredEventIds
      let content = finalContent
      let replacedIds = replacedRequestIds
      stateLock.unlock()
      Self.acknowledge(run: run, eventIds: eventIds)
      center.removeDeliveredNotifications(withIdentifiers: replacedIds)
      // Returning the extension's content handler makes it eligible for
      // termination. Finish all database work and close first.
      Self.finalizeRuntime(run: run)
      self.finish(with: content)
    }
  }

  private func communicationContent(
    for rendered: RenderedNotification,
    badgeCount: Int64,
    original: UNNotificationContent,
    completion: @escaping (UNNotificationContent) -> Void
  ) {
    let addition = rendered.addition
    let mutable = (original.mutableCopy() as? UNMutableNotificationContent)
      ?? UNMutableNotificationContent()
    mutable.title = addition.senderName
    mutable.body = rendered.body
    mutable.threadIdentifier = addition.notificationGroup
    mutable.badge = NSNumber(value: badgeCount)
    mutable.sound = .default
    var userInfo = mutable.userInfo
    if let conversationId = addition.conversationId {
      userInfo["conversation_id"] = conversationId
    }
    userInfo["notification_kind"] = addition.kind
    userInfo["notification_id"] = addition.notificationId
    userInfo["notification_ids"] = rendered.notificationIds
    userInfo.removeValue(forKey: "text_group")
    userInfo["notification_group"] = addition.notificationGroup
    mutable.userInfo = userInfo

    let avatar = addition.avatarPath
      .flatMap { try? Data(contentsOf: URL(fileURLWithPath: $0)) }
      .map(INImage.init(imageData:))
    let sender = INPerson(
      personHandle: INPersonHandle(value: String(addition.senderId), type: .unknown),
      nameComponents: nil,
      displayName: addition.senderName,
      image: avatar,
      contactIdentifier: nil,
      customIdentifier: String(addition.senderId)
    )
    let groupName = addition.isGroup
      ? addition.conversationName.map(INSpeakableString.init(spokenPhrase:))
      : nil
    let intent = INSendMessageIntent(
      recipients: nil,
      outgoingMessageType: .outgoingMessageText,
      content: rendered.body,
      speakableGroupName: groupName,
      conversationIdentifier: addition.notificationGroup,
      serviceName: "Twonly",
      sender: sender,
      attachments: nil
    )
    if addition.isGroup, let path = addition.conversationAvatarPath,
      let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
      intent.setImage(INImage(imageData: data), forParameterNamed: \.speakableGroupName)
    }
    let interaction = INInteraction(intent: intent, response: nil)
    interaction.direction = .incoming
    interaction.donate { error in
      if let error {
        NSLog("Could not donate Twonly communication intent: \(error)")
        completion(mutable)
        return
      }
      do {
        let content = try mutable.updating(from: intent)
        // Keep our grouping and tap metadata after SiriKit enriches the alert.
        if let enriched = content.mutableCopy() as? UNMutableNotificationContent {
          enriched.title = addition.senderName
          enriched.threadIdentifier = mutable.threadIdentifier
          enriched.userInfo = mutable.userInfo
          completion(enriched)
        } else {
          completion(content)
        }
      } catch {
        NSLog("Could not create Twonly communication notification: \(error)")
        completion(mutable)
      }
    }
  }

  private var isCompleting: Bool {
    finishLock.lock()
    defer { finishLock.unlock() }
    return hasFinished
  }

  private func finish(with content: UNNotificationContent) {
    finishLock.lock()
    guard !hasFinished else {
      finishLock.unlock()
      return
    }
    hasFinished = true
    let handler = contentHandler
    let run = runID
    fallbackContent = nil
    contentHandler = nil
    finishLock.unlock()
    // Expiration stays nonblocking on the calling thread. The content handler
    // runs only once the Rust supervisor has acknowledged actual cleanup.
    twonly_database_operation_cancel(run)
    DispatchQueue.global(qos: .userInitiated).async {
      twonly_notification_run_finish(run)
      handler?(content)
    }
  }

  private func deliverFallback(
    reason: String,
    operation: String = "notification_processing",
    presentation: NativeNotificationPresentation? = nil
  ) {
    NativeErrorReporting.failure(operation)
    NSLog("Delivering Twonly wake-up fallback notification: \(reason)")
    finishLock.lock()
    let fallback = fallbackContent
    finishLock.unlock()
    guard let presentation else {
      finish(with: fallback ?? UNMutableNotificationContent())
      return
    }
    let content = (fallback?.mutableCopy() as? UNMutableNotificationContent)
      ?? UNMutableNotificationContent()
    content.title = presentation.title
    content.body = presentation.body
    finish(with: content)
  }

  private static func runtimeDirectory() -> String? {
    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: runtimeAppGroup
      )
    else { return nil }
    let directory = container.appendingPathComponent("runtime", isDirectory: true)
    // A push may arrive before the first foreground launch after an upgrade.
    // Leave its mailbox pending until the complete legacy store is installed.
    guard FileManager.default.fileExists(
      atPath: directory.appendingPathComponent(".runtime_storage_migrated_v1").path
    ) else { return nil }
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try (directory as NSURL).setResourceValue(
        URLFileProtection.completeUntilFirstUserAuthentication,
        forKey: .fileProtectionKey
      )
      return directory.path
    } catch {
      NSLog("Could not open Twonly runtime directory: \(error)")
      return nil
    }
  }

  private static func processWakeup(run: UInt64, runtimeDirectory: String) -> NativeNotificationResponse? {
    let locale = Locale.current.identifier
    let pointer = runtimeDirectory.withCString { databaseDirectory in
      runtimeDirectory.withCString { dataDirectory in
        locale.withCString { locale in
          twonly_notification_process_with_id(run, databaseDirectory, dataDirectory, locale, 20_000)
        }
      }
    }
    guard let pointer else { return nil }
    defer { twonly_notification_string_free(pointer) }
    let json = String(cString: pointer)
    do {
      return try JSONDecoder().decode(
        NativeNotificationResponse.self,
        from: Data(json.utf8)
      )
    } catch {
      NSLog("Could not decode Twonly notification worker response: \(error)")
      return nil
    }
  }

  private static func finalizeRuntime(run: UInt64) {
    guard let pointer = twonly_notification_finalize_with_id(run, finalizeDeadlineMs) else { return }
    defer { twonly_notification_string_free(pointer) }
    let json = String(cString: pointer)
    guard
      let response = try? JSONDecoder().decode(
        NativeNotificationResponse.self,
        from: Data(json.utf8)
      )
    else { return }
    if let error = response.error {
      NativeErrorReporting.failure("notification_finalize")
      NSLog("Deferred Twonly notification maintenance failed: \(error)")
    }
    if response.widgetRefresh {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private static func acknowledge(run: UInt64, eventIds: [String]) {
    guard !eventIds.isEmpty, let data = try? JSONEncoder().encode(eventIds),
      let json = String(data: data, encoding: .utf8)
    else { return }
    let pointer = json.withCString { twonly_notification_acknowledge_with_id(run, $0) }
    guard let pointer else { return }
    twonly_notification_string_free(pointer)
  }

}
