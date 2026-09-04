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
  });

  final String id;
  final String platform;
  final List<int> contactGroupIds;
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

  /// Settles the widget media that arrived while nothing was running: an image
  /// is deleted by the next one for its contact groups, during the refresh that
  /// publishes that successor.
  static Future<void> pruneSupersededMedia() async {
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
  /// When iOS cannot be asked, this falls back to whatever the file last
  /// recorded, which may name widgets that are already gone.
  static Future<List<PlacedWidget>> placedWidgets() async {
    if (!Platform.isIOS) return _widgetsFromFile();
    final report = await reconcileReport();
    if (report == null || report['error'] != null) return _widgetsFromFile();
    final reported = ((report['widgets'] as List?) ?? const [])
        .cast<Map<Object?, Object?>>()
        .where((entry) => entry['mine'] == true && entry['live'] == true);
    final seen = <String>{};
    return [
      for (final entry in reported)
        if (seen.add('${entry['id']}'))
          PlacedWidget(
            id: '${entry['id']}',
            platform: 'ios',
            contactGroupIds: ((entry['group_ids'] as List?) ?? const [])
                .map((id) => (id as num).toInt())
                .toList(),
          ),
    ];
  }

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
}
