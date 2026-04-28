import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AppEnvironment {
  static late final String cacheDir;
  static late final String supportDir;

  // will be loaded in the main_camera_controller.dart
  static List<CameraDescription> cameras = [];

  static Future<void> init() async {
    cacheDir = (await getApplicationCacheDirectory()).path;
    supportDir = (await getApplicationSupportDirectory()).path;
  }

  static void initTesting() {
    cacheDir = '/tmp/twonly_cache';
    supportDir = '/tmp/twonly_support';
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
