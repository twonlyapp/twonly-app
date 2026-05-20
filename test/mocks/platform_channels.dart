// ignore_for_file: avoid_print, avoid_dynamic_calls

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupPlatformChannelMocks() {
  final secureStorageMock = <String, String>{};
  Future<dynamic> mockHandler(MethodCall methodCall) async {
    final userId = Zone.current[#userId] as int?;
    final keyPrefix = userId != null ? '${userId}_' : '';
    if (methodCall.method == 'read') {
      final key = methodCall.arguments['key'] as String;
      return secureStorageMock[keyPrefix + key];
    } else if (methodCall.method == 'write') {
      final key = methodCall.arguments['key'] as String;
      final value = methodCall.arguments['value'] as String;
      secureStorageMock[keyPrefix + key] = value;
      return true;
    } else if (methodCall.method == 'delete') {
      final key = methodCall.arguments['key'] as String;
      secureStorageMock.remove(keyPrefix + key);
      return true;
    } else if (methodCall.method == 'readAll') {
      final result = <String, String>{};
      secureStorageMock.forEach((k, v) {
        if (k.startsWith(keyPrefix)) {
          result[k.substring(keyPrefix.length)] = v;
        }
      });
      return result;
    } else if (methodCall.method == 'deleteAll') {
      if (userId != null) {
        secureStorageMock.removeWhere((k, v) => k.startsWith(keyPrefix));
      } else {
        secureStorageMock.clear();
      }
      return true;
    }
    return null;
  }

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel(
      'plugins.it_crowd.double_tapp/flutter_secure_storage',
    ),
    mockHandler,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    mockHandler,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/connectivity'),
    (call) async {
      if (call.method == 'check') {
        return ['wifi'];
      }
      return null;
    },
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel(
      'be.tramesch.workmanager/foreground_channel_workmanager',
    ),
    (call) async => true,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('com.bbflight.background_downloader'),
    (call) async {
      if (call.method == 'enqueue') {
        return true;
      }
      return null;
    },
  );
}
