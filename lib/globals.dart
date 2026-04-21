import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/api.service.dart';

class AppEnvironment {
  static late final String cacheDir;
  static late final String supportDir;
  static late final List<CameraDescription> cameras;

  static Future<void> init() async {
    cacheDir = (await getApplicationCacheDirectory()).path;
    supportDir = (await getApplicationSupportDirectory()).path;
    cameras = await availableCameras();
  }
}

class AppState {
  static bool isAppInBackground = true;
  static bool isInBackgroundTask = false;
  static bool allowErrorTrackingViaSentry = false;
  static bool gotMessageFromServer = false;
}

class AppGlobalKeys {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}

class AppSession {
  static late UserData currentUser;

  static final _userDataUpdateController = StreamController<void>.broadcast();
  static Stream<void> get onUserUpdated => _userDataUpdateController.stream;

  static void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }
}

late ApiService apiService;
late TwonlyDB twonlyDB;
