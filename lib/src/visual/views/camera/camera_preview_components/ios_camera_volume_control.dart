import 'dart:async';

import 'package:flutter/services.dart';
import 'package:twonly/src/utils/log.dart';

/// Owns the volume plugin's iOS channel so registration failures can be awaited.
/// EventChannel reports activation failures through FlutterError, bypassing
/// stream error handlers, which is unsuitable for an optional camera shortcut.
class IosCameraVolumeControl {
  IosCameraVolumeControl({required this.onPressed});

  final Future<void> Function() onPressed;

  static const _methods = MethodChannel(
    'com.yosemiteyss.flutter_volume_controller/method',
  );
  static const _events = MethodChannel(
    'com.yosemiteyss.flutter_volume_controller/event',
  );

  Future<void> _pending = Future.value();
  int _generation = 0;
  bool _requested = false;
  bool _hasListener = false;
  double? _initialVolume;

  Future<void> start() {
    if (_requested) return _pending;
    _requested = true;
    final generation = ++_generation;
    return _pending = _pending.then((_) => _start(generation));
  }

  Future<void> stop() {
    _requested = false;
    ++_generation;
    return _pending = _pending.then((_) => _stop());
  }

  Future<void> _start(int generation) async {
    if (generation != _generation) return;
    _initialVolume = null;
    _hasListener = true;
    _events.binaryMessenger.setMessageHandler(
      _events.name,
      (message) => _handleVolume(message, generation),
    );
    try {
      await _methods.invokeMethod<void>('updateShowSystemUI', {
        'showSystemUI': false,
      });
      await _events.invokeMethod<void>('listen', {
        'audioSessionCategory': 0, // Plugin default: ambient.
        'emitOnStart': true,
      });
    } on PlatformException catch (error, stack) {
      Log.warn('iOS volume shutter unavailable', error, stack);
      if (generation == _generation) _requested = false;
      await _stop();
    } on MissingPluginException catch (error, stack) {
      Log.warn('iOS volume shutter unavailable', error, stack);
      if (generation == _generation) _requested = false;
      await _stop();
    }
  }

  Future<ByteData?> _handleVolume(ByteData? message, int generation) async {
    if (message == null || generation != _generation) return null;
    try {
      final volume = double.parse(
        _events.codec.decodeEnvelope(message) as String,
      );
      if (_initialVolume == null) {
        _initialVolume = volume;
        return null;
      }
      if (volume == _initialVolume) return null;
      await _methods.invokeMethod<void>('setVolume', {
        'volume': _initialVolume,
        'showSystemUI': false,
      });
    } on PlatformException catch (error, stack) {
      Log.warn('iOS volume shutter unavailable', error, stack);
      unawaited(stop());
      return null;
    } on MissingPluginException catch (error, stack) {
      Log.warn('iOS volume shutter unavailable', error, stack);
      unawaited(stop());
      return null;
    }
    if (generation == _generation) await onPressed();
    return null;
  }

  Future<void> _stop() async {
    if (!_hasListener) return;
    _hasListener = false;
    _initialVolume = null;
    _events.binaryMessenger.setMessageHandler(_events.name, null);
    // Cancel even after a failed registration to clean up native state.
    await _cleanup(_events, 'cancel');
    await _cleanup(_methods, 'updateShowSystemUI', {'showSystemUI': true});
  }

  Future<void> _cleanup(
    MethodChannel channel,
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (error, stack) {
      Log.warn('Could not clean up iOS volume shutter', error, stack);
    } on MissingPluginException catch (error, stack) {
      Log.warn('Could not clean up iOS volume shutter', error, stack);
    }
  }
}
