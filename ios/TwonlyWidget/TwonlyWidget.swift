import AppIntents
import ImageIO
import OSLog
import SwiftUI
import WidgetKit

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
      // The count separates "the app never delivered anything" from "an image
      // is being held for other groups than the ones this widget selects".
      return total == 0 ? "No images yet" : "\(total) shared, none in your groups"
    case .fault(let fault):
      return fault.summary
    }
  }
}

struct TwonlyEntry: TimelineEntry {
  let date: Date
  let image: ManifestImage?
  let emptyReason: EmptyReason?
  /// Longest edge this entry will ever be drawn at, in pixels. Decoding to the
  /// size actually shown is what keeps the extension inside its memory budget.
  let maxPixelSize: CGFloat
}

/// A widget shows the image that arrived last and nothing else, so its
/// timeline is a single entry. The app pushes a reload whenever the manifest
/// changes, which is what actually puts a new image on the home screen; this
/// interval only keeps the widget rebuilding while nothing arrives, because a
/// rebuild is the sole evidence that the widget is still placed.
private let timelineRefreshHours = 4

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
      emptyReason: .noMatchingImages(total: 0),
      maxPixelSize: maxPixelSize(in: context)
    )
  }

  func snapshot(for configuration: TwonlyWidgetIntent, in context: Context) async -> TwonlyEntry {
    let ids = (configuration.groups ?? []).compactMap { Int64($0.id) }
    return entry(
      images: WidgetStorage.images(),
      ids: ids,
      date: .now,
      maxPixelSize: maxPixelSize(in: context)
    )
  }

  func timeline(for configuration: TwonlyWidgetIntent, in context: Context) async -> Timeline<TwonlyEntry> {
    let ids = (configuration.groups ?? []).compactMap { Int64($0.id) }
    WidgetStorage.persistSelection(ids)
    let entry = entry(
      images: WidgetStorage.images(),
      ids: ids,
      date: .now,
      maxPixelSize: maxPixelSize(in: context)
    )
    let next =
      Calendar.current.date(byAdding: .hour, value: timelineRefreshHours, to: .now) ?? .now
    widgetLog.debug("built 1 entry at \(entry.maxPixelSize, privacy: .public)px")
    return Timeline(entries: [entry], policy: .after(next))
  }

  /// The one image this widget shows: the most recent one published for any of
  /// its contact groups. The manifest is written newest first, so that is
  /// simply the first match.
  private func entry(
    images: Result<[ManifestImage], WidgetStorage.ManifestFault>,
    ids: [Int64],
    date: Date,
    maxPixelSize: CGFloat
  ) -> TwonlyEntry {
    let available: [ManifestImage]
    switch images {
    case .success(let value):
      available = value
    case .failure(let fault):
      return TwonlyEntry(
        date: date, image: nil,
        emptyReason: .fault(fault), maxPixelSize: maxPixelSize)
    }

    // An unconfigured widget selects nothing, and an empty set is disjoint from
    // every image, so this would silently filter everything away.
    guard !ids.isEmpty else {
      widgetLog.notice("no contact group configured; nothing can match")
      return TwonlyEntry(
        date: date, image: nil,
        emptyReason: .notConfigured, maxPixelSize: maxPixelSize)
    }

    let selected = Set(ids)
    guard let newest = available.first(where: { !selected.isDisjoint(with: $0.groupIds) }) else {
      // The offered groups are what separates "nobody has sent anything" from
      // "the sender is in groups this widget did not select", which look
      // identical on screen.
      widgetLog.notice(
        """
        no match: selected \(ids, privacy: .public), \
        \(available.count, privacy: .public) images, \
        offered groups \(Set(available.flatMap(\.groupIds)).sorted(), privacy: .public)
        """)
      return TwonlyEntry(
        date: date,
        image: nil,
        emptyReason: .noMatchingImages(total: available.count),
        maxPixelSize: maxPixelSize
      )
    }
    return TwonlyEntry(
      date: date,
      image: newest,
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
      // Opens the containing app. The scheme is not registered anywhere and
      // does not need to be: WidgetKit hands the URL to twonly itself, and the
      // app ignores links it does not recognise.
      .widgetURL(URL(string: "twonly://widget"))
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

