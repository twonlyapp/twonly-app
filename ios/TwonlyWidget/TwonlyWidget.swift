import AppIntents
import ImageIO
import OSLog
import SwiftUI
import WidgetKit

struct AdvanceWidgetIntent: AppIntent {
  static let title: LocalizedStringResource = "Next image"
  static let openAppWhenRun = false

  @Parameter(title: "Contact groups") var groupIds: [String]

  init() { groupIds = [] }
  init(groupIds: [Int64]) { self.groupIds = groupIds.map(String.init) }

  func perform() async throws -> some IntentResult {
    WidgetStorage.advance(groupIds.compactMap(Int64.init))
    WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    return .result()
  }
}

/// Why the widget has nothing to show, so the placeholder can say it.
enum EmptyReason: Equatable {
  case notConfigured
  case noMatchingImages(total: Int)
  case fault(WidgetStorage.ManifestFault)

  var message: String {
    switch self {
    case .notConfigured:
      return "Hold to choose contact groups"
    case .noMatchingImages(let total):
      // The count separates "the app never delivered anything" from "images
      // arrived but carry other groups than the ones this widget selects".
      return total == 0 ? "No images yet" : "\(total) shared, none in your groups"
    case .fault(let fault):
      return fault.summary
    }
  }
}

struct TwonlyEntry: TimelineEntry {
  let date: Date
  let image: ManifestImage?
  let groupIds: [Int64]
  let emptyReason: EmptyReason?
  /// Longest edge this entry will ever be drawn at, in pixels. Decoding to the
  /// size actually shown is what keeps the extension inside its memory budget.
  let maxPixelSize: CGFloat
}

/// WidgetKit renders every timeline entry up front, so a timeline is a
/// multiplier on whatever one entry costs. Eight half-hour steps keep the
/// rotation going for four hours on a fraction of the memory a full day took.
private let timelineEntryCount = 8
private let timelineStepMinutes = 30

struct TwonlyProvider: AppIntentTimelineProvider {
  /// The widget is never drawn larger than its container, so this is the most
  /// detail any image needs. `displaySize` is in points; 3x covers the densest
  /// screen the extension can be asked to render for.
  private func maxPixelSize(in context: Context) -> CGFloat {
    max(context.displaySize.width, context.displaySize.height) * 3
  }

  func placeholder(in context: Context) -> TwonlyEntry {
    TwonlyEntry(
      date: .now,
      image: nil,
      groupIds: [],
      emptyReason: .noMatchingImages(total: 0),
      maxPixelSize: maxPixelSize(in: context)
    )
  }

  func snapshot(for configuration: TwonlyWidgetIntent, in context: Context) async -> TwonlyEntry {
    let ids = (configuration.groups ?? []).compactMap { Int64($0.id) }
    return entry(
      images: WidgetStorage.images(),
      ids: ids,
      index: WidgetStorage.index(for: ids),
      date: .now,
      maxPixelSize: maxPixelSize(in: context)
    )
  }

  func timeline(for configuration: TwonlyWidgetIntent, in context: Context) async -> Timeline<TwonlyEntry> {
    let ids = (configuration.groups ?? []).compactMap { Int64($0.id) }
    WidgetStorage.persistSelection(ids)
    // Read once: an extension that re-reads the manifest for every entry spends
    // its whole budget on JSON.
    let available = WidgetStorage.images()
    // The rotation starts at whatever just arrived, so an image shared into
    // this widget is on the home screen as soon as the timeline is rebuilt
    // rather than whenever the rotation next comes back around to it.
    let start = WidgetStorage.startIndex(
      for: ids,
      newestMediaId: newestMatching(in: available, ids: ids)?.mediaId
    )
    let pixels = maxPixelSize(in: context)
    let entries = (0..<timelineEntryCount).map { offset in
      entry(
        images: available,
        ids: ids,
        index: start + offset,
        date: Calendar.current.date(
          byAdding: .minute, value: offset * timelineStepMinutes, to: .now) ?? .now,
        maxPixelSize: pixels
      )
    }
    widgetLog.debug(
      "built \(entries.count, privacy: .public) entries at \(pixels, privacy: .public)px")
    return Timeline(entries: entries, policy: .atEnd)
  }

  /// The most recent image this selection can show right now. The manifest is
  /// written newest first, so that is simply the first one that matches.
  private func newestMatching(
    in images: Result<[ManifestImage], WidgetStorage.ManifestFault>,
    ids: [Int64]
  ) -> ManifestImage? {
    guard !ids.isEmpty, let available = try? images.get() else { return nil }
    let selected = Set(ids)
    let now = Int64(Date().timeIntervalSince1970)
    return available.first { $0.expiresAt > now && !selected.isDisjoint(with: $0.groupIds) }
  }

  private func entry(
    images: Result<[ManifestImage], WidgetStorage.ManifestFault>,
    ids: [Int64],
    index: Int,
    date: Date,
    maxPixelSize: CGFloat
  ) -> TwonlyEntry {
    let available: [ManifestImage]
    switch images {
    case .success(let value):
      available = value
    case .failure(let fault):
      return TwonlyEntry(
        date: date, image: nil, groupIds: ids,
        emptyReason: .fault(fault), maxPixelSize: maxPixelSize)
    }

    // An unconfigured widget selects nothing, and an empty set is disjoint from
    // every image, so this would silently filter everything away.
    guard !ids.isEmpty else {
      widgetLog.notice("no contact group configured; nothing can match")
      return TwonlyEntry(
        date: date, image: nil, groupIds: ids,
        emptyReason: .notConfigured, maxPixelSize: maxPixelSize)
    }

    let selected = Set(ids)
    let now = Int64(date.timeIntervalSince1970)
    let unexpired = available.filter { $0.expiresAt > now }
    let matching = unexpired.filter { !selected.isDisjoint(with: $0.groupIds) }
    guard !matching.isEmpty else {
      // The two counts separate "everything aged out" from "the sender is in
      // groups this widget did not select", which look identical on screen.
      widgetLog.notice(
        """
        no match: selected \(ids, privacy: .public), \
        \(available.count, privacy: .public) images, \
        \(unexpired.count, privacy: .public) unexpired, \
        offered groups \(Set(available.flatMap(\.groupIds)).sorted(), privacy: .public)
        """)
      return TwonlyEntry(
        date: date,
        image: nil,
        groupIds: ids,
        emptyReason: .noMatchingImages(total: available.count),
        maxPixelSize: maxPixelSize
      )
    }
    return TwonlyEntry(
      date: date,
      image: matching[index % matching.count],
      groupIds: ids,
      emptyReason: nil,
      maxPixelSize: maxPixelSize
    )
  }
}

/// The widget extension has its own bundle, so it carries its own copy of the
/// logo in `TwonlyWidget/Assets.xcassets`; the Runner catalog is not visible
/// here.
private let placeholderLogo = UIImage(named: "logo")

/// Decodes straight to the size the widget draws at.
///
/// `UIImage(contentsOfFile:)` expands the whole file into a bitmap first — a
/// 1200px image costs about 5.8 MB that way, and WidgetKit renders every
/// timeline entry, so a handful of them is enough to pass the extension's
/// memory limit. Exceeding it is not an error the code can catch: the system
/// kills the extension and the home screen keeps showing a blank square.
/// ImageIO never materialises the full bitmap.
private func downsampledImage(at path: String, maxPixelSize: CGFloat) -> UIImage? {
  guard maxPixelSize > 0,
        let source = CGImageSourceCreateWithURL(
          URL(fileURLWithPath: path) as CFURL,
          [kCGImageSourceShouldCache: false] as CFDictionary
        )
  else { return nil }

  let options =
    [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ] as CFDictionary
  guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
    return nil
  }
  return UIImage(cgImage: thumbnail)
}

struct TwonlyWidgetView: View {
  let entry: TwonlyEntry

  var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay {
        Button(intent: AdvanceWidgetIntent(groupIds: entry.groupIds)) {
          Color.clear
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show next image")
      }
      .containerBackground(for: .widget) { brandBackground }
  }

  @ViewBuilder
  private var content: some View {
    if let image = entry.image,
       let uiImage = downsampledImage(at: image.path, maxPixelSize: entry.maxPixelSize) {
      photo(uiImage, sender: image.sender)
        .onAppear {
          widgetLog.debug(
            "rendering \(image.mediaId, privacy: .public) at \(uiImage.size.debugDescription, privacy: .public)")
        }
    } else if let image = entry.image {
      // The manifest named an image the extension cannot open: the file is
      // gone, or its data protection class keeps it sealed out here.
      placeholder(message: "Image could not be loaded")
        .onAppear {
          let manager = FileManager.default
          widgetLog.error(
            """
            cannot open \(image.path, privacy: .public) \
            (exists: \(manager.fileExists(atPath: image.path), privacy: .public), \
            readable: \(manager.isReadableFile(atPath: image.path), privacy: .public))
            """)
        }
    } else {
      placeholder(message: (entry.emptyReason ?? .noMatchingImages(total: 0)).message)
    }
  }

  /// A filled photo with the sender's name in the corner.
  ///
  /// `scaledToFill` reports a size larger than the space it was given, so an
  /// image placed directly in a stack drives that stack's bounds past the edges
  /// of the widget — and anything aligned to a corner goes off screen with it.
  /// Overlaying the image on a flexible, zero-cost base keeps the layout the
  /// size of the widget, so the name lands on the visible bottom-right corner.
  private func photo(_ uiImage: UIImage, sender: String) -> some View {
    Color.clear
      .overlay {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
      }
      .clipped()
      .overlay(alignment: .bottomTrailing) {
        Text(sender)
          .font(.caption2)
          .foregroundStyle(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(.black.opacity(0.42), in: Capsule())
          .padding(8)
      }
  }

  /// Shown whenever there is nothing to display, always with the reason: a
  /// blank widget is the one outcome that cannot be diagnosed from the home
  /// screen.
  private func placeholder(message: String) -> some View {
    VStack(spacing: 8) {
      Group {
        if let placeholderLogo {
          Image(uiImage: placeholderLogo).resizable().scaledToFit()
        } else {
          Image(systemName: "photo.on.rectangle.angled").resizable().scaledToFit()
        }
      }
      .frame(maxWidth: 64, maxHeight: 64)
      .foregroundStyle(.white)
      .opacity(0.9)
      Text(message)
        .font(.caption2)
        .multilineTextAlignment(.center)
        .foregroundStyle(.white.opacity(0.85))
        .lineLimit(3)
    }
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  /// `defaultPrimaryColor` from the Flutter theme (0xFF32BE80).
  private var brandBackground: some View {
    Color(red: 50.0 / 255.0, green: 190.0 / 255.0, blue: 128.0 / 255.0)
  }
}

@main
struct TwonlyWidgetBundle: WidgetBundle {
  var body: some Widget {
    TwonlyHomeWidget()
  }
}

struct TwonlyHomeWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: widgetKind, intent: TwonlyWidgetIntent.self, provider: TwonlyProvider()) {
      TwonlyWidgetView(entry: $0)
    }
    .configurationDisplayName("twonly")
    .description("Images your friends share with your widget.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

