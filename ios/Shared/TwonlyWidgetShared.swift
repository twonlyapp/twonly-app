import AppIntents
import Foundation
import OSLog
import WidgetKit

// Compiled into BOTH the app and the widget extension.
//
// The extension owns the widget's appearance, but only the app can ask
// WidgetKit which widgets are actually on the home screen
// (`getCurrentConfigurations`), and reading their configuration requires the
// very same intent and entity types the extension declares. Everything both
// sides need therefore lives here rather than inside the extension.
//
// The app deploys further back than the widget extension does, so the
// AppIntents declarations carry an explicit availability gate.

let runtimeAppGroup = "group.eu.twonly.runtime"
let widgetKind = "TwonlyWidget"

/// How long a widget may go without rebuilding its timeline before it is taken
/// to have been removed from the home screen. Timelines cover four hours, so a
/// widget that is still placed refreshes far inside this.
let staleWidgetSeconds: Double = 48 * 60 * 60

/// A widget extension is launched by WidgetKit, off any debugger, at moments
/// nobody is watching, and a failure just renders as an empty square. Every
/// step that can silently produce "no image" logs here instead.
///
///     log stream --predicate 'subsystem == "eu.twonly.widget"' --level debug
let widgetLog = Logger(subsystem: "eu.twonly.widget", category: "timeline")

struct Manifest: Decodable {
  let groups: [ManifestGroup]
  let images: [ManifestImage]
}

struct ManifestGroup: Decodable {
  let id: Int64
  let name: String
  let emoji: String?
}

struct ManifestImage: Decodable {
  let mediaId: String
  let path: String
  let sender: String
  let groupIds: [Int64]
  let expiresAt: Int64

  enum CodingKeys: String, CodingKey {
    case path, sender
    case mediaId = "media_id"
    case groupIds = "group_ids"
    case expiresAt = "expires_at"
  }
}

enum WidgetStorage {
  static var runtimeDirectory: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: runtimeAppGroup)?
      .appendingPathComponent("runtime", isDirectory: true)
  }

  /// Every way reading the manifest can come up empty. The widget renders the
  /// reason, because none of these are distinguishable from the home screen
  /// otherwise: an unprovisioned App Group, a manifest the app never wrote and
  /// a manifest with nothing in it all look like one blank widget.
  enum ManifestFault: Error, Equatable {
    case appGroupUnavailable
    case missing
    case unreadable(String)

    var summary: String {
      switch self {
      case .appGroupUnavailable: return "No shared storage"
      case .missing: return "Open twonly once"
      case .unreadable(let detail): return "Unreadable data (\(detail))"
      }
    }
  }

  static func manifest() -> Result<Manifest, ManifestFault> {
    guard let url = runtimeDirectory?.appendingPathComponent("widget/manifest.json") else {
      widgetLog.error("App Group \(runtimeAppGroup, privacy: .public) is not reachable")
      return .failure(.appGroupUnavailable)
    }
    guard let data = try? Data(contentsOf: url) else {
      let exists = FileManager.default.fileExists(atPath: url.path)
      widgetLog.error(
        "manifest unreadable at \(url.path, privacy: .public) (exists: \(exists, privacy: .public))")
      return .failure(exists ? .unreadable("locked") : .missing)
    }
    do {
      let manifest = try JSONDecoder().decode(Manifest.self, from: data)
      widgetLog.debug(
        """
        manifest \(data.count, privacy: .public) bytes, \
        \(manifest.groups.count, privacy: .public) groups, \
        \(manifest.images.count, privacy: .public) images
        """)
      return .success(manifest)
    } catch {
      widgetLog.error("manifest decode failed: \(error, privacy: .public)")
      return .failure(.unreadable("\(error)"))
    }
  }

  static func images() -> Result<[ManifestImage], ManifestFault> {
    manifest().map(\.images)
  }

  static func selectionKey(_ ids: [Int64]) -> String {
    ids.sorted().map(String.init).joined(separator: "-")
  }

  static func index(for ids: [Int64]) -> Int {
    UserDefaults(suiteName: runtimeAppGroup)?.integer(forKey: "widget-index-\(selectionKey(ids))") ?? 0
  }

  /// Where the rotation starts, sent back to the front whenever an image has
  /// arrived since this selection was last drawn.
  ///
  /// The manifest is newest first, so an arriving image is prepended and a
  /// stored index keeps pointing at an older one: a timeline reload alone would
  /// never show what just came in. Recording which image was newest last time
  /// is what separates an arrival from every other reason a timeline is rebuilt.
  static func startIndex(for ids: [Int64], newestMediaId: String?) -> Int {
    guard let newestMediaId else { return index(for: ids) }
    let defaults = UserDefaults(suiteName: runtimeAppGroup)
    let newestKey = "widget-newest-\(selectionKey(ids))"
    guard defaults?.string(forKey: newestKey) != newestMediaId else {
      return index(for: ids)
    }
    defaults?.set(newestMediaId, forKey: newestKey)
    defaults?.set(0, forKey: "widget-index-\(selectionKey(ids))")
    return 0
  }

  static func advance(_ ids: [Int64]) {
    let defaults = UserDefaults(suiteName: runtimeAppGroup)
    let key = "widget-index-\(selectionKey(ids))"
    defaults?.set((defaults?.integer(forKey: key) ?? 0) + 1, forKey: key)
  }

  /// Records this widget's contact groups for Rust to import.
  ///
  /// Each placed widget builds its own timeline, so this only ever knows about
  /// one of them and has to merge into what the others wrote — replacing the
  /// list would make every widget erase its neighbours. Nothing tells an
  /// extension that a widget was removed either, so each entry carries the time
  /// it was last rebuilt and readers drop the ones that stopped reporting.
  /// Replaces every iOS entry with the widgets WidgetKit says are placed.
  ///
  /// The extension can only ever add itself, and is never told that its widget
  /// was removed, so a removal is invisible from that side. The app can ask
  /// outright, which makes this the only exact answer — call it before reading
  /// the configuration back.
  static func storedWidgets() -> [[String: Any]] {
    guard let directory = runtimeDirectory?.appendingPathComponent("widget", isDirectory: true),
      let data = try? Data(contentsOf: directory.appendingPathComponent("native-config.json")),
      let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let stored = decoded["widgets"] as? [[String: Any]]
    else { return [] }
    return stored
  }

  /// Selections that have rebuilt a timeline at or after `since`.
  ///
  /// This is the only evidence available that a widget is really on a home
  /// screen. WidgetKit keeps records of widgets it has known about and
  /// `getCurrentConfigurations` hands them all back, so its answer alone cannot
  /// tell a placed widget from one the system has simply not forgotten. Only a
  /// widget that is actually being displayed is asked for a timeline, and
  /// `persistSelection` — called from nowhere else — stamps the moment it was.
  static func recentlyRebuiltIds(since: Int) -> Set<String> {
    var ids = Set<String>()
    for entry in storedWidgets() {
      guard let id = entry["id"] as? String, let seen = entry["last_seen"] as? Int
      else { continue }
      if seen >= since { ids.insert(id) }
    }
    return ids
  }

  /// Rewrites the placement file from the widgets the app has established are
  /// really placed. Each entry keeps the timestamp its widget wrote: stamping
  /// `now` here would forge the very evidence the next reconcile depends on.
  static func replaceIosSelections(_ selections: [[Int64]]) {
    guard let directory = runtimeDirectory?.appendingPathComponent("widget", isDirectory: true)
    else { return }
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    var lastSeen: [String: Int] = [:]
    for entry in storedWidgets() {
      if let id = entry["id"] as? String, let seen = entry["last_seen"] as? Int {
        lastSeen[id] = seen
      }
    }

    // Two widgets configured with the same contact groups are interchangeable
    // here: the id is the selection, and Rust only reads the union anyway.
    var seen = Set<String>()
    var widgets: [[String: Any]] = []
    for ids in selections {
      let identifier = "ios:\(selectionKey(ids))"
      guard seen.insert(identifier).inserted else { continue }
      widgets.append([
        "id": identifier,
        "platform": "ios",
        "group_ids": ids,
        "last_seen": lastSeen[identifier] ?? 0,
      ])
    }
    write(widgets: widgets, to: directory)
  }

  /// Overwrites the placement file.
  ///
  /// `Data.write(.atomic)` already writes to a neighbouring temporary file and
  /// exchanges it, so this does not hand-roll that. The previous version did,
  /// and swallowed a failed exchange: the destination still existed, so its
  /// fallback never ran and the stale file survived a write that looked like it
  /// had succeeded.
  private static func write(widgets: [[String: Any]], to directory: URL) {
    let destination = directory.appendingPathComponent("native-config.json")
    do {
      let data = try JSONSerialization.data(withJSONObject: ["widgets": widgets])
      try data.write(
        to: destination,
        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
      )
      widgetLog.debug(
        "wrote \(widgets.count, privacy: .public) widget(s) to \(destination.path, privacy: .public)"
      )
    } catch {
      widgetLog.error("could not write the placement file: \(error, privacy: .public)")
    }
    // A crash between the two steps of the old implementation could have left
    // this behind, and it would otherwise sit in the App Group forever.
    try? FileManager.default.removeItem(
      at: directory.appendingPathComponent("native-config.json.tmp"))
  }

  static func persistSelection(_ ids: [Int64]) {
    guard let directory = runtimeDirectory?.appendingPathComponent("widget", isDirectory: true)
    else { return }
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try? (directory as NSURL).setResourceValue(
      URLFileProtection.completeUntilFirstUserAuthentication,
      forKey: .fileProtectionKey
    )
    let identifier = "ios:\(selectionKey(ids))"
    let widget: [String: Any] = [
      "id": identifier,
      "platform": "ios",
      "group_ids": ids,
      "last_seen": Int(Date().timeIntervalSince1970),
    ]

    let destination = directory.appendingPathComponent("native-config.json")
    var widgets: [[String: Any]] = []
    if let existing = try? Data(contentsOf: destination),
       let decoded = try? JSONSerialization.jsonObject(with: existing) as? [String: Any],
       let stored = decoded["widgets"] as? [[String: Any]] {
      // Android's entries are authoritative and carry no timestamp, so they are
      // always kept; only this platform's own stale rows are dropped.
      widgets = stored.filter { entry in
        guard entry["id"] as? String != identifier else { return false }
        guard let seen = entry["last_seen"] as? Int else { return true }
        return Date().timeIntervalSince1970 - Double(seen) < staleWidgetSeconds
      }
    }
    widgets.append(widget)

    write(widgets: widgets, to: directory)
  }
}

@available(iOS 17.0, *)
struct ContactGroupEntity: AppEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Contact group")
  static let defaultQuery = ContactGroupQuery()

  let id: String
  let name: String
  let emoji: String?

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(emoji.map { "\($0) " } ?? "")\(name)")
  }
}

@available(iOS 17.0, *)
struct ContactGroupQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [ContactGroupEntity] {
    let wanted = Set(identifiers)
    return allEntities().filter { wanted.contains($0.id) }
  }

  private func allEntities() -> [ContactGroupEntity] {
    let groups = (try? WidgetStorage.manifest().get())?.groups ?? []
    return groups.map {
      ContactGroupEntity(id: String($0.id), name: $0.name, emoji: $0.emoji)
    }
  }

  func suggestedEntities() async throws -> [ContactGroupEntity] { allEntities() }
}

@available(iOS 17.0, *)
struct TwonlyWidgetIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "twonly contact groups"
  static let description = IntentDescription("Choose who may share images with this widget.")

  @Parameter(title: "Contact groups")
  var groups: [ContactGroupEntity]?

  init() { groups = nil }
}

