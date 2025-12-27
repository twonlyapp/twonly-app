import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/subscription.service.dart';

late ApiService apiService;

// uses for background notification
late TwonlyDB twonlyDB;

List<CameraDescription> gCameras = <CameraDescription>[];

// Cached UserData in the memory. Every time the user data is changed the `updateUserdata` function is called,
// which will update this global variable. The variable is set in the main.dart and after the user has registered in the register.view.dart
late UserData gUser;

// The following global function can be called from anywhere to update
// the UI when something changed. The callbacks will be set by
// App widget.

// This callback called by the apiProvider
void Function({required bool isConnected}) globalCallbackConnectionState = ({
  required bool isConnected,
}) {};
void Function() globalCallbackAppIsOutdated = () {};
void Function() globalCallbackNewDeviceRegistered = () {};
void Function(SubscriptionPlan plan) globalCallbackUpdatePlan =
    (SubscriptionPlan plan) {};

Map<String, VoidCallback> globalUserDataChangedCallBack = {};

bool globalIsAppInBackground = true;
bool globalAllowErrorTrackingViaSentry = false;

late String globalApplicationCacheDirectory;
late String globalApplicationSupportDirectory;

final GlobalKey<ScaffoldMessengerState> globalRootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
