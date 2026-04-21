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

late ApiService apiService;

// uses for background notification
late TwonlyDB twonlyDB;

// Cached UserData in the memory. Every time the user data is changed the `updateUserdata` function is called,
// which will update this global variable. The variable is set in the main.dart and after the user has registered in the register.view.dart
late UserData gUser;

// The following global function can be called from anywhere to update
// the UI when something changed. The callbacks will be set by
// App widget.

// This callback called by the apiProvider
void Function() globalCallbackAppIsOutdated = () {};
void Function() globalCallbackNewDeviceRegistered = () {};

Map<String, VoidCallback> globalUserDataChangedCallBack = {};

bool globalIsAppInBackground = true;
bool globalIsInBackgroundTask = false;
bool globalAllowErrorTrackingViaSentry = false;
bool globalGotMessageFromServer = false;

final GlobalKey<ScaffoldMessengerState> globalRootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
