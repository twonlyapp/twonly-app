import Foundation
import Intents
import UserNotifications
import WidgetKit
import rust_lib_twonly

private let runtimeAppGroup = "group.eu.twonly.runtime"

/// Budget for the work deferred behind the alert. Behind a rendered alert it
/// runs after the content handler has fired, so the system may reclaim the
/// extension before it ends; a wake-up with nothing to render spends it up
/// front instead, where the whole budget is actually available.
private let finalizeDeadlineMs: UInt64 = 5_000

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
  let textMessagesBody: String?
  let conversationName: String?
  let isGroup: Bool
  let messageId: String?
  let kind: String
  let content: String?
  let createdAt: Int64
  let avatarPath: String?

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
    case textMessagesBody = "text_messages_body"
  }

  var textGroup: String? {
    guard kind == "text" || kind == "response" else { return nil }
    return "text:\(conversationId ?? ""):\(senderId)"
  }
}

private struct RenderedNotification {
  let addition: NativeNotificationAddition
  let eventIds: [String]
  let notificationIds: [String]
  let replacingRequestIds: [String]

  var body: String {
    guard notificationIds.count > 1, let template = addition.textMessagesBody else {
      return addition.body
    }
    return template.replacingOccurrences(of: "{count}", with: String(notificationIds.count))
  }
}

final class NotificationService: UNNotificationServiceExtension {
  private let finishLock = NSLock()
  private var hasFinished = false
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var fallbackContent: UNNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    fallbackContent = request.content

    guard let runtimeDirectory = Self.runtimeDirectory() else {
      deliverFallback(reason: "shared runtime directory is unavailable")
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      guard let response = Self.processWakeup(runtimeDirectory: runtimeDirectory) else {
        self.deliverFallback(reason: "notification worker returned no response")
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
        Self.finalizeRuntime()
        // The worker ran and decided there is nothing to announce. With the
        // notification filtering entitlement, empty content drops the push
        // instead of showing its "You got a new message" placeholder.
        NSLog("Twonly wake-up had nothing to announce; suppressing the alert")
        self.finish(with: UNNotificationContent())
        return
      }
      self.render(batch: batch, original: request.content)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    deliverFallback(reason: "notification service extension timed out")
  }

  private func render(batch: NativeNotificationBatch, original: UNNotificationContent) {
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { [weak self] delivered in
      self?.render(
        groups: Self.groupedAdditions(batch.additions, delivered: delivered.map(\.request)),
        badgeCount: batch.badgeCount,
        original: original
      )
    }
  }

  private static func groupedAdditions(
    _ additions: [NativeNotificationAddition], delivered: [UNNotificationRequest]
  ) -> [RenderedNotification] {
    // A single request represents each sender's text messages in a chat, even
    // when they arrive in different wake-ups. Dismissed alerts are absent here
    // and therefore start a fresh group on the next message.
    let grouped = Dictionary(grouping: additions) {
      $0.textGroup ?? "event:\($0.eventId)"
    }
    return grouped.values.compactMap { entries -> RenderedNotification? in
      guard let latest = entries.last else { return nil }
      let previous = delivered.filter {
        guard let key = latest.textGroup else { return false }
        return $0.content.userInfo["text_group"] as? String == key
      }
      var ids = Set(entries.map(\.notificationId))
      for notification in previous {
        let info = notification.content.userInfo
        if let values = info["notification_ids"] as? [String] {
          ids.formUnion(values)
        } else if let value = info["notification_id"] as? String {
          ids.insert(value)
        }
      }
      return RenderedNotification(
        addition: latest,
        eventIds: entries.map(\.eventId),
        notificationIds: ids.sorted(),
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
    groups: [RenderedNotification], badgeCount: Int64, original: UNNotificationContent
  ) {
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
          identifier: rendered.addition.textGroup ?? rendered.addition.notificationId,
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
      stateLock.lock()
      let eventIds = deliveredEventIds
      let content = finalContent
      let replacedIds = replacedRequestIds
      stateLock.unlock()
      Self.acknowledge(eventIds: eventIds)
      center.removeDeliveredNotifications(withIdentifiers: replacedIds)
      self?.finish(with: content)
      // The alert is on screen. Whatever time the system still grants this
      // extension goes to the deferred work; being terminated part-way only
      // defers it to the next wake-up or app launch.
      Self.finalizeRuntime()
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
    mutable.threadIdentifier = addition.textGroup ?? addition.conversationId ?? String(addition.senderId)
    mutable.badge = NSNumber(value: badgeCount)
    mutable.sound = .default
    var userInfo = mutable.userInfo
    if let conversationId = addition.conversationId {
      userInfo["conversation_id"] = conversationId
    }
    userInfo["notification_kind"] = addition.kind
    userInfo["notification_id"] = addition.notificationId
    userInfo["notification_ids"] = rendered.notificationIds
    userInfo["text_group"] = addition.textGroup
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
      conversationIdentifier: addition.conversationId ?? String(addition.senderId),
      serviceName: "Twonly",
      sender: sender,
      attachments: nil
    )
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

  private func finish(with content: UNNotificationContent) {
    finishLock.lock()
    guard !hasFinished else {
      finishLock.unlock()
      return
    }
    hasFinished = true
    let handler = contentHandler
    fallbackContent = nil
    contentHandler = nil
    finishLock.unlock()
    handler?(content)
  }

  private func deliverFallback(
    reason: String,
    presentation: NativeNotificationPresentation? = nil
  ) {
    NSLog("Delivering Twonly wake-up fallback notification: \(reason)")
    guard let presentation else {
      finish(with: fallbackContent ?? UNMutableNotificationContent())
      return
    }
    let content = (fallbackContent?.mutableCopy() as? UNMutableNotificationContent)
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

  private static func processWakeup(runtimeDirectory: String) -> NativeNotificationResponse? {
    let locale = Locale.current.identifier
    let pointer = runtimeDirectory.withCString { databaseDirectory in
      runtimeDirectory.withCString { dataDirectory in
        locale.withCString { locale in
          twonly_notification_process(databaseDirectory, dataDirectory, locale, 22_000)
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

  private static func finalizeRuntime() {
    guard let pointer = twonly_notification_finalize(finalizeDeadlineMs) else { return }
    defer { twonly_notification_string_free(pointer) }
    let json = String(cString: pointer)
    guard
      let response = try? JSONDecoder().decode(
        NativeNotificationResponse.self,
        from: Data(json.utf8)
      )
    else { return }
    if let error = response.error {
      NSLog("Deferred Twonly notification maintenance failed: \(error)")
    }
    if response.widgetRefresh {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private static func acknowledge(eventIds: [String]) {
    guard !eventIds.isEmpty, let data = try? JSONEncoder().encode(eventIds),
      let json = String(data: data, encoding: .utf8)
    else { return }
    let pointer = json.withCString { twonly_notification_acknowledge($0) }
    guard let pointer else { return }
    twonly_notification_string_free(pointer)
  }

}
