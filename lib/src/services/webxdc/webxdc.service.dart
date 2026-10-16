import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Expression, TableUpdateQuery;
import 'package:twonly/core/bridge/webxdc.dart' as rust_webxdc;
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

/// The Flutter side of the webxdc runtime.
///
/// Everything that decides anything -- which bundle an instance runs, what an
/// app may send, what its text may contain -- lives in Rust. This class moves
/// values across and reads the mirrored tables for the chat UI; it deliberately
/// makes no judgements of its own, because the calls it forwards originate in
/// a webview running third-party code.
class WebxdcService {
  /// The last row seen for an instance and for a store entry, held for the
  /// life of the process.
  ///
  /// A chat recycles a card's state whenever it scrolls out of view, and both
  /// lookups behind a card are asynchronous, so a rebuilt card would paint
  /// nothing for a frame or two and then pop back in with a freshly decoded
  /// icon. Reading the last known values synchronously means it comes back
  /// looking the way it left, while the queries behind it still run and
  /// correct anything that changed.
  static final Map<String, WebxdcInstance> _instanceCache = {};
  static final Map<String, WebxdcApp> _appCache = {};

  static String _appKey(String appId, int version) => '$appId:$version';

  /// Refreshes the store listing from the API. Metadata only, no bundles.
  static Future<bool> refreshCatalog() async {
    try {
      await rust_webxdc.refreshCatalog();
      return true;
    } catch (error) {
      Log.warn('refreshing the webxdc catalog failed: $error');
      return false;
    }
  }

  /// What the store currently offers: newest published version of each app.
  ///
  /// `languages` is what the UI prefers, most preferred first. Every app is
  /// cached with all its translations, so choosing one costs nothing and is
  /// never sent anywhere.
  static Future<List<rust_webxdc.WebxdcStoreApp>> catalog(
    String groupId,
    List<String> languages,
  ) async {
    try {
      return await rust_webxdc.catalog(groupId: groupId, languages: languages);
    } catch (error) {
      Log.warn('reading the webxdc catalog failed: $error');
      return [];
    }
  }

  static Future<List<rust_webxdc.WebxdcOneTimeInstance>> oneTimeInstances(
    String groupId,
    List<String> languages,
  ) async {
    try {
      return await rust_webxdc.oneTimeInstances(
        groupId: groupId,
        languages: languages,
      );
    } catch (error) {
      Log.warn('reading one-time webxdc apps for $groupId failed: $error');
      return [];
    }
  }

  /// Places an app into a chat. Returns the id of the message carrying it,
  /// which is also the instance id.
  static Future<String?> createInstance(
    String groupId,
    String appId,
    int version,
  ) async {
    try {
      return await rust_webxdc.createInstance(
        groupId: groupId,
        appId: appId,
        version: version,
      );
    } catch (error) {
      Log.error('placing a webxdc app into $groupId failed: $error');
      return null;
    }
  }

  /// Gets the bundle an instance runs onto disk, verified.
  ///
  /// Opens cached code without a network update check. Only a bundle that
  /// has not been downloaded yet needs the server.
  static Future<String?> prepareBundle(String instanceId) async {
    try {
      return await rust_webxdc.prepareBundle(instanceId: instanceId);
    } catch (error) {
      Log.warn('preparing the bundle for $instanceId failed: $error');
      return null;
    }
  }

  static final Set<String> _updatingInstances = {};

  /// Best effort after closing. A failed check leaves the existing code usable.
  static Future<void> cacheUpdate(String instanceId) async {
    if (!_updatingInstances.add(instanceId)) return;
    try {
      await rust_webxdc.cacheUpdate(instanceId: instanceId);
    } catch (error) {
      Log.warn('checking for a webxdc update after closing failed: $error');
    } finally {
      _updatingInstances.remove(instanceId);
    }
  }

  static Future<rust_webxdc.WebxdcInstanceInfo?> instance(
    String instanceId,
  ) async {
    try {
      return await rust_webxdc.instance(instanceId: instanceId);
    } catch (error) {
      Log.warn('reading webxdc instance $instanceId failed: $error');
      return null;
    }
  }

  static Future<List<rust_webxdc.WebxdcUpdateEntry>> updatesAfter(
    String instanceId,
    int serial,
  ) async {
    try {
      return await rust_webxdc.updatesAfter(
        instanceId: instanceId,
        serial: serial,
      );
    } catch (error) {
      Log.warn('reading updates for $instanceId failed: $error');
      return [];
    }
  }

  /// Forwards an update the running app produced. Rust applies the size, rate
  /// and text limits and throws when one is exceeded, which the caller passes
  /// back to the app as a rejected promise.
  static Future<void> sendUpdate({
    required String instanceId,
    required String payload,
    String? info,
    String? href,
    String? summary,
    String? document,
    String? notify,
  }) => rust_webxdc.sendUpdate(
    instanceId: instanceId,
    payload: payload,
    info: info,
    href: href,
    summary: summary,
    document: document,
    notify: notify,
  );

  /// Removes an instance, its whole update log, and the web storage its origin
  /// accumulated. The log is only half the state: an app is free to keep
  /// everything in `localStorage`, which no database delete reaches.
  static Future<void> deleteInstance(String instanceId) async {
    _instanceCache.remove(instanceId);
    final origin = await rust_webxdc.deleteInstance(instanceId: instanceId);
    if (origin != null) {
      await WebxdcWebviewStorage.clearOrigin(origin);
    }
  }

  /// The store entry an instance runs, for the chat card. Null while the
  /// catalog has not been fetched on this device yet.
  static Future<WebxdcApp?> appFor(WebxdcInstance instance) =>
      appNamed(instance.appId, instance.version);

  static Future<WebxdcApp?> appNamed(String appId, int version) async {
    final app =
        await (twonlyDB.select(twonlyDB.webxdcApps)..where(
              (app) => Expression.and([
                app.appId.equals(appId),
                app.version.equals(version),
              ]),
            ))
            .getSingleOrNull();
    if (app != null) _appCache[_appKey(appId, version)] = app;
    return app;
  }

  /// What to call an app on the card in a chat, in the language the reader
  /// asked for.
  ///
  /// The same rules Rust applies to the store list, because the two are read
  /// side by side: an exact tag wins, then one sharing its primary language
  /// (`de-at` for a reader of `de`), then English, then whatever the app is
  /// translated into at all. `name` is what an app translated into none of the
  /// reader's languages is called.
  static String localizedName(WebxdcApp app, List<String> languages) {
    Map<String, dynamic> byLanguage;
    try {
      final decoded = jsonDecode(app.nameTranslations);
      if (decoded is! Map<String, dynamic>) return app.name;
      byLanguage = decoded;
    } catch (_) {
      return app.name;
    }

    String? named(bool Function(String tag) matches) {
      for (final entry in byLanguage.entries) {
        final value = entry.value;
        if (value is String && value.isNotEmpty && matches(entry.key)) {
          return value;
        }
      }
      return null;
    }

    for (final language in languages.map((tag) => tag.toLowerCase())) {
      final exact = named((tag) => tag == language);
      if (exact != null) return exact;
      final primary = language.split('-').first;
      final related = named((tag) => tag.split('-').first == primary);
      if (related != null) return related;
    }
    return named((tag) => tag == 'en') ?? named((_) => true) ?? app.name;
  }

  /// The store entry as it was last read, without touching the database, for
  /// the first frame of a card whose state was just recreated. Null until some
  /// card has looked the version up; the caller still runs [appNamed].
  static WebxdcApp? cachedApp(String appId, int version) =>
      _appCache[_appKey(appId, version)];

  /// The instance as it was last read, for the same reason as [cachedApp].
  static WebxdcInstance? cachedInstance(String instanceId) =>
      _instanceCache[instanceId];

  /// The instance row, if this device has the app card the message points at.
  /// A `sendToChat` message can land in a chat that has no instance of its own.
  static Future<WebxdcInstance?> instanceRow(String instanceId) async {
    final row = await (twonlyDB.select(
      twonlyDB.webxdcInstances,
    )..where((row) => row.instanceId.equals(instanceId))).getSingleOrNull();
    if (row != null) _instanceCache[instanceId] = row;
    return row;
  }

  static Stream<WebxdcInstance?> watchInstance(String instanceId) {
    return (twonlyDB.select(twonlyDB.webxdcInstances)
          ..where((row) => row.instanceId.equals(instanceId)))
        .watchSingleOrNull()
        .map((row) {
          if (row != null) _instanceCache[instanceId] = row;
          return row;
        });
  }

  /// Fires whenever any update lands. The caller filters by serial, so a tick
  /// for another instance costs one query and nothing else; only one app is
  /// ever open at a time.
  static Stream<void> watchUpdates() {
    return twonlyDB
        .tableUpdates(TableUpdateQuery.onTable(twonlyDB.webxdcUpdates))
        .map((_) {});
  }
}

/// Clearing a webview origin is the platform's job; the channel is declared
/// here so the service can finish a deletion without reaching into the view
/// layer.
abstract final class WebxdcWebviewStorage {
  static Future<void> Function(String origin)? clear;

  static Future<void> clearOrigin(String origin) async {
    final clear = WebxdcWebviewStorage.clear;
    if (clear == null) {
      Log.warn('no webview storage cleaner registered, $origin kept its data');
      return;
    }
    await clear(origin);
  }
}
