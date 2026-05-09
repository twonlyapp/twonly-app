import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/utils/log.dart';

class AppEnvironment {
  static late final String cacheDir;
  static late final String supportDir;

  static bool _isInitialized = false;

  // will be loaded in the main_camera_controller.dart
  static List<CameraDescription> cameras = [];

  static Future<void> init() async {
    if (_isInitialized) return;
    cacheDir = (await getApplicationCacheDirectory()).path;
    supportDir = (await getApplicationSupportDirectory()).path;
    Log.init();
    _isInitialized = true;
  }

  static void initTesting() {
    if (_isInitialized) return;
    cacheDir = '/tmp/twonly_cache';
    supportDir = '/tmp/twonly_support';
    _isInitialized = true;
  }
}

class AppState {
  static bool isAppInBackground = true;
  static bool isInBackgroundTask = false;
  static bool allowErrorTrackingViaSentry = false;
  static bool gotMessageFromServer = false;
  static int latestAppVersionId = 110;
}

class AppGlobalKeys {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}
