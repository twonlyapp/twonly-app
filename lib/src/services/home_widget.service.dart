import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';

/// One widget the user has placed on their home screen.
class PlacedWidget {
  const PlacedWidget({
    required this.id,
    required this.platform,
    required this.contactGroupIds,
    this.family,
  });

  final String id;
  final String platform;
  final List<int> contactGroupIds;

  /// The widget's size, as WidgetKit names it (`systemSmall` and so on). Null
  /// on Android, which does not report one.
  final String? family;

  /// A widget with no contact group can never show anything: nobody is allowed
  /// to share with it, so nothing is ever delivered.
  bool get isConfigured => contactGroupIds.isNotEmpty;
}

/// An image a widget is currently rotating through.
class WidgetImage {
  const WidgetImage({
    required this.mediaId,
    required this.path,
    required this.sender,
    required this.contactGroupIds,
    required this.expiresAt,
  });

  final String mediaId;
  final String path;
  final String sender;
  final List<int> contactGroupIds;
  final DateTime expiresAt;

  Duration get remaining => expiresAt.difference(DateTime.now());
  bool get isExpired => remaining.isNegative;
  File get file => File(path);
}

/// Keeps native widget placement and Rust's derived sharing permissions in
/// sync. Native configuration UIs also persist their selection in the shared
/// widget configuration file, which Rust imports during every sync.
class HomeWidgetService {
  const HomeWidgetService._();

  static const _runtimeChannel = MethodChannel('eu.twonly/runtime_storage');

  static String get platform => Platform.isIOS ? 'ios' : 'android';

  static Future<void> register(String widgetId) async {
    await RustApi.registerHomeWidget(widgetId: widgetId, platform: platform);
    await refresh();
  }

  static Future<void> unregister(String widgetId) async {
    await RustApi.unregisterHomeWidget(widgetId: widgetId);
    await refresh();
  }

  static Future<void> setGroups(
    String widgetId,
    List<int> contactGroupIds,
  ) async {
    await RustApi.setHomeWidgetGroups(
      widgetId: widgetId,
      platform: platform,
      contactGroupIds: Int64List.fromList(contactGroupIds),
    );
    await refresh();
  }

  static Future<void> syncPermissions() async {
    // Must run first: Rust derives who may share from the placement file, so a
    // widget removed from the home screen has to disappear from it before that
    // import reads it.
    await reconcile();
    await RustApi.syncWidgetPermissions();
    await refresh();
  }

  /// Rewrites the placement file from the widgets WidgetKit says are placed.
  ///
  /// A WidgetKit extension is never told that its widget was removed, so its
  /// own entry would otherwise linger. Only the app can ask, and only on iOS —
  /// Android's provider already enumerates its widgets whenever one changes.
  static Future<void> reconcile() async => reconcileReport();

  /// Reconciles, and reports what WidgetKit answered.
  ///
  /// Returns null when the platform has nothing to reconcile, and rethrows
  /// nothing: a failed query leaves the placement file alone, because failing
  /// to ask is not evidence that a widget was removed. The diagnostics screen
  /// renders the report; ordinary callers use [reconcile].
  static Future<Map<String, dynamic>?> reconcileReport() async {
    if (!Platform.isIOS) return null;
    // Reconciling waits on the widget extension, so a screen that syncs and
    // then lists would otherwise pay for it twice in a row.
    if (_cachedReport case final cached?) {
      if (DateTime.now().difference(cached.at) < _reportCacheFor) {
        return cached.report;
      }
    }
    try {
      final report = await _runtimeChannel.invokeMapMethod<String, dynamic>(
        'reconcileWidgets',
      );
      _cachedReport = (at: DateTime.now(), report: report);
      return report;
    } catch (error) {
      Log.error('Could not reconcile the placed widgets: $error');
      return {'error': '$error'};
    }
  }

  static ({DateTime at, Map<String, dynamic>? report})? _cachedReport;
  static const _reportCacheFor = Duration(seconds: 10);

  /// Drops the cached reconcile so the next read asks the system again.
  static void invalidate() => _cachedReport = null;

  static Future<void> purgeExpiredMedia() async {
    await RustApi.purgeWidgetMedia();
    await refresh();
  }

  /// Republishes the manifest so the widgets see the current contact groups.
  ///
  /// A widget's configuration UI lists the groups from that file, so a group
  /// that was just created is invisible to it until this runs.
  static Future<void> refreshManifest() async {
    await RustApi.refreshWidgetManifest();
    await refresh();
  }

  /// Removes one image from every widget showing it, and from disk.
  static Future<void> deleteImage(String mediaId) async {
    await RustApi.deleteWidgetMedia(mediaId: mediaId);
    await refresh();
  }

  /// Asks the placed widgets to redraw from the manifest Rust just wrote.
  ///
  /// Neither platform notices the rewrite on its own: WidgetKit keeps the
  /// timeline it built from the older manifest, and an AppWidget only redraws
  /// when its provider is asked to. Until this runs, an image that has already
  /// arrived is nowhere on the home screen.
  static Future<void> refresh() async {
    try {
      await _runtimeChannel.invokeMethod<void>('reloadWidgets');
    } catch (error) {
      Log.error('Could not reload the home widget: $error');
    }
  }

  static Directory get _root =>
      Directory('${AppEnvironment.supportDir}/widget');

  /// Mirrors `staleWidgetSeconds` in the iOS widget and `STALE_WIDGET_SECONDS`
  /// in Rust: an iOS entry that has not refreshed within this belongs to a
  /// widget that is no longer on the home screen.
  static const _staleWidget = Duration(hours: 48);

  /// The widgets currently on the home screen.
  ///
  /// On iOS this is WidgetKit's own answer rather than the placement file:
  /// the file is *derived* from this, so reading it back could only ever repeat
  /// a stale write. Android has no equivalent query, and its provider rewrites
  /// the file whenever a widget is added or removed, so there the file is the
  /// authority.
  ///
  /// The returned `error` is set when iOS could not be asked; the widgets are
  /// then whatever the file last recorded, which may name widgets that are
  /// already gone.
  static Future<({List<PlacedWidget> widgets, String? error})>
  placedWidgetsResult() async {
    if (!Platform.isIOS) {
      return (widgets: await _widgetsFromFile(), error: null);
    }
    final report = await reconcileReport();
    if (report == null || report['error'] != null) {
      return (
        widgets: await _widgetsFromFile(),
        error: '${report?['error'] ?? 'unknown'}',
      );
    }
    final reported = ((report['widgets'] as List?) ?? const [])
        .cast<Map<Object?, Object?>>()
        .where((entry) => entry['mine'] == true && entry['live'] == true);
    final seen = <String>{};
    return (
      widgets: [
        for (final entry in reported)
          if (seen.add('${entry['id']}'))
            PlacedWidget(
              id: '${entry['id']}',
              platform: 'ios',
              family: entry['family'] as String?,
              contactGroupIds: ((entry['group_ids'] as List?) ?? const [])
                  .map((id) => (id as num).toInt())
                  .toList(),
            ),
      ],
      error: null,
    );
  }

  static Future<List<PlacedWidget>> placedWidgets() async =>
      (await placedWidgetsResult()).widgets;

  static Future<List<PlacedWidget>> _widgetsFromFile() async {
    final file = File('${_root.path}/native-config.json');
    if (!file.existsSync()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      final widgets = ((decoded as Map<String, dynamic>)['widgets'] as List?)
          ?.cast<Map<String, dynamic>>();
      final oldestLive = DateTime.now().subtract(_staleWidget);
      return [
        for (final widget in widgets ?? const <Map<String, dynamic>>[])
          if (_isLive(widget['last_seen'], oldestLive))
            PlacedWidget(
              id: '${widget['id']}',
              platform: '${widget['platform']}',
              contactGroupIds: ((widget['group_ids'] as List?) ?? const [])
                  .map((id) => (id as num).toInt())
                  .toList(),
            ),
      ];
    } catch (error) {
      Log.error('Could not read the widget configuration: $error');
      return const [];
    }
  }

  /// An entry with no timestamp is Android's, which is always authoritative.
  static bool _isLive(Object? lastSeen, DateTime oldestLive) {
    if (lastSeen is! num) return true;
    return DateTime.fromMillisecondsSinceEpoch(
      lastSeen.toInt() * 1000,
    ).isAfter(oldestLive);
  }

  /// Every unexpired image Rust has published to the widgets, newest first.
  static Future<List<WidgetImage>> images() async {
    final file = File('${_root.path}/manifest.json');
    if (!file.existsSync()) return const [];
    try {
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final images = ((decoded['images'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      final parsed = [
        for (final image in images)
          WidgetImage(
            mediaId: '${image['mediaId'] ?? image['media_id']}',
            path: '${image['path']}',
            sender: '${image['sender']}',
            contactGroupIds: ((image['group_ids'] as List?) ?? const [])
                .map((id) => (id as num).toInt())
                .toList(),
            expiresAt: DateTime.fromMillisecondsSinceEpoch(
              ((image['expires_at'] as num?)?.toInt() ?? 0) * 1000,
            ),
          ),
      ]..sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
      return parsed.where((image) => !image.isExpired).toList();
    } catch (error) {
      Log.error('Could not read the widget manifest: $error');
      return const [];
    }
  }

  /// The images a single widget rotates through: only senders whose contact
  /// groups overlap the ones that widget selected.
  static Future<List<WidgetImage>> imagesFor(PlacedWidget widget) async {
    final selected = widget.contactGroupIds.toSet();
    final all = await images();
    return all
        .where((image) => image.contactGroupIds.any(selected.contains))
        .toList();
  }
}
