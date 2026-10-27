import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/log.dart';

class LocationMetadataService with WidgetsBindingObserver {
  static const _channel = MethodChannel('eu.twonly/location_metadata');
  static final _instance = LocationMetadataService();
  static StreamSubscription<void>? _userUpdates;
  static Future<String?>? _pendingCity;
  static Completer<String?>? _pendingCoordinates;
  static String? _city;
  static String? _cityLocale;
  static DateTime? _cityResolvedAt;
  static bool? _stickersEnabled;
  static int _generation = 0;

  static bool get stickersEnabled =>
      userService.isUserCreated &&
      userService.currentUser.enableLocationSticker;

  /// Foreground startup never opens a permission sheet. Both features share
  /// Rust's one-shot acquisition and short-lived coordinate cache.
  static void initialize() {
    if (_userUpdates != null) return;
    WidgetsBinding.instance.addObserver(_instance);
    _userUpdates = userService.onUserUpdated.listen((_) => _settingsChanged());
    _settingsChanged();
  }

  static void dispose() {
    unawaited(_userUpdates?.cancel());
    _userUpdates = null;
    WidgetsBinding.instance.removeObserver(_instance);
    _stickersEnabled = null;
    _clearCity();
  }

  static void _clearCity() {
    _generation++;
    if (_pendingCoordinates?.isCompleted == false) {
      _pendingCoordinates!.complete(null);
    }
    _pendingCoordinates = null;
    _pendingCity = null;
    _city = null;
    _cityLocale = null;
    _cityResolvedAt = null;
  }

  static void _settingsChanged() {
    if (_stickersEnabled != stickersEnabled) {
      _stickersEnabled = stickersEnabled;
      _clearCity();
    }
    unawaited(_warmUp());
  }

  static bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  static Future<void> _warmUp() async {
    try {
      if (!_isForeground || !userService.isUserCreated) return;
      final user = userService.currentUser;
      if (!(user.storeLocationInMemories || user.enableLocationSticker)) return;
      if (!await _hasPermission()) return;
      if (!_isForeground) return;
      await RustApi.prewarmMemoryLocation();
      if (stickersEnabled) await currentCity();
    } on Object catch (error) {
      if (isBackgroundCancellation(error)) return;
      Log.warn('Could not warm up location: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_warmUp());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _clearCity();
    }
  }

  static Future<bool> _hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPrecisePermission') ?? false;

  /// Returns a city/town name, the country, or coordinates if geocoding fails.
  /// [onLocationAvailable] reports coordinates as soon as a fix is available,
  /// so the editor can stop loading while the place name is still resolving.
  /// Coordinates are never persisted for this
  /// feature, and no media metadata or outgoing message is changed here.
  static Future<String?> currentCity({
    String? languageTag,
    ValueChanged<String>? onLocationAvailable,
  }) async {
    if (!stickersEnabled || !_isForeground) return null;
    try {
      if (!await _hasPermission() || !stickersEnabled || !_isForeground) {
        _clearCity();
        return null;
      }
      final locale =
          languageTag ??
          userService.currentUser.language ??
          basicLocaleListResolution(
            WidgetsBinding.instance.platformDispatcher.locales,
            AppLocalizations.supportedLocales,
          ).toLanguageTag();
      if (_cityLocale != locale) {
        _clearCity();
        _cityLocale = locale;
      }
      if (_city != null &&
          _cityResolvedAt != null &&
          DateTime.now().difference(_cityResolvedAt!) <
              const Duration(minutes: 3)) {
        return _city;
      }
      final generation = _generation;
      if (_pendingCity == null) {
        _pendingCoordinates = Completer<String?>();
        _pendingCity = _resolveCity(locale, generation, _pendingCoordinates!);
      }
      final request = _pendingCity!;
      final coordinates = _pendingCoordinates!;
      if (onLocationAvailable != null) {
        unawaited(
          coordinates.future.then((label) {
            if (label != null &&
                generation == _generation &&
                stickersEnabled &&
                _isForeground) {
              onLocationAvailable(label);
            }
          }),
        );
      }
      try {
        return await request;
      } finally {
        if (!coordinates.isCompleted) coordinates.complete(null);
        if (identical(_pendingCity, request)) {
          _pendingCity = null;
          _pendingCoordinates = null;
        }
      }
    } on Object catch (error) {
      if (!isBackgroundCancellation(error)) {
        Log.warn('Could not resolve location sticker city: $error');
      }
      return null;
    }
  }

  static Future<String?> _resolveCity(
    String locale,
    int generation,
    Completer<String?> coordinates,
  ) async {
    final location = await RustApi.currentLocationForSticker();
    if (location == null) return null;
    final hasPermission = await _hasPermission();
    if (!hasPermission ||
        generation != _generation ||
        !stickersEnabled ||
        !_isForeground) {
      return null;
    }
    final coordinateLabel =
        '${location.latitude.toStringAsFixed(4)}, '
        '${location.longitude.toStringAsFixed(4)}';
    if (!coordinates.isCompleted) coordinates.complete(coordinateLabel);
    String? city;
    try {
      city =
          (await _channel
                  .invokeMethod<String>('resolveCity', {
                    'latitude': location.latitude,
                    'longitude': location.longitude,
                    'locale': locale,
                  })
                  .timeout(const Duration(seconds: 12)))
              ?.trim();
    } on Object catch (error) {
      Log.warn('Could not geocode location sticker: $error');
    }
    final stillHasPermission = await _hasPermission();
    if (!stillHasPermission ||
        generation != _generation ||
        !stickersEnabled ||
        !_isForeground) {
      return null;
    }
    if (city == null || city.isEmpty) return coordinateLabel;
    _city = city;
    _cityResolvedAt = DateTime.now();
    return city;
  }

  /// Opens the native permission sheet only after the user enables the switch.
  /// Approximate/reduced access is rejected because this feature promises a
  /// precise capture location.
  static Future<bool> requestPrecisePermission() async {
    return await _channel.invokeMethod<bool>('requestPrecisePermission') ??
        false;
  }
}
