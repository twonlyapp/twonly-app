import 'dart:async';

import 'package:flutter/services.dart';
import 'package:twonly/src/utils/log.dart';

/// Awaits the volume plugin's stream setup and cleanup directly, since
/// EventChannel reports those failures through FlutterError instead.
class AndroidCameraVolumeControl {
  AndroidCameraVolumeControl({required this.onPressed});

  final Future<void> Function() onPressed;

  static const _events = MethodChannel(
    'dart-tools.dev/flutter_android_volume_keydown',
  );

  Future<void> _pending = Future.value();
  int _generation = 0;
  bool _requested = false;
  bool _hasListener = false;

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
    _hasListener = true;
    _events.binaryMessenger.setMessageHandler(
      _events.name,
      (message) => _handleButton(message, generation),
    );
    try {
      await _events.invokeMethod<void>('listen');
    } on PlatformException catch (error, stack) {
      Log.warn('Android volume shutter unavailable', error, stack);
      if (generation == _generation) _requested = false;
      await _stop();
    } on MissingPluginException catch (error, stack) {
      Log.warn('Android volume shutter unavailable', error, stack);
      if (generation == _generation) _requested = false;
      await _stop();
    }
  }

  Future<ByteData?> _handleButton(ByteData? message, int generation) async {
    if (generation != _generation) return null;
    if (message == null) {
      unawaited(stop());
      return null;
    }
    try {
      // Both volume buttons trigger the shutter; the plugin sends their
      // direction as a boolean in a standard event envelope.
      _events.codec.decodeEnvelope(message) as bool;
    } on PlatformException catch (error, stack) {
      Log.warn('Android volume shutter unavailable', error, stack);
      unawaited(stop());
      return null;
    }
    await onPressed();
    return null;
  }

  Future<void> _stop() async {
    if (!_hasListener) return;
    _hasListener = false;
    _events.binaryMessenger.setMessageHandler(_events.name, null);
    // Clean up native state even when registration failed partway through.
    try {
      await _events.invokeMethod<void>('cancel');
    } on PlatformException catch (error, stack) {
      Log.warn('Could not clean up Android volume shutter', error, stack);
    } on MissingPluginException catch (error, stack) {
      Log.warn('Could not clean up Android volume shutter', error, stack);
    }
  }
}
