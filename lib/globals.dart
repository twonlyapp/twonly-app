import 'package:camera/camera.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/api.service.dart';

late ApiService apiService;

// uses for background notification
late TwonlyDatabase twonlyDB;

List<CameraDescription> gCameras = <CameraDescription>[];
bool gIsDemoUser = false;

// The following global function can be called from anywhere to update
// the UI when something changed. The callbacks will be set by
// App widget.

// This callback called by the apiProvider
void Function({required bool isConnected}) globalCallbackConnectionState = ({
  required bool isConnected,
}) {};
void Function() globalCallbackAppIsOutdated = () {};
void Function() globalCallbackNewDeviceRegistered = () {};
void Function(String planId) globalCallbackUpdatePlan = (String planId) {};

bool globalIsAppInBackground = true;
int globalBestFriendUserId = -1;
