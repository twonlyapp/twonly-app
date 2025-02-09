import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerView extends StatefulWidget {
  const PermissionHandlerView({super.key, required this.onSuccess});

  final Function onSuccess;

  @override
  PermissionHandlerViewState createState() => PermissionHandlerViewState();
}

Future<bool> checkPermissions() async {
  if (!await Permission.camera.isGranted) {
    return false;
  }
  if (!await Permission.microphone.isGranted) {
    return false;
  }
  return true;
}

class PermissionHandlerViewState extends State<PermissionHandlerView> {
  Future<Map<Permission, PermissionStatus>> permissionServices() async {
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.notification
    ].request();

    if (statuses[Permission.microphone]!.isPermanentlyDenied) {
      openAppSettings();
      // setState(() {});
    } else {
      // if (statuses[Permission.microphone]!.isDenied) {
      // }
    }

    if (statuses[Permission.camera]!.isPermanentlyDenied) {
      openAppSettings();
      // setState(() {});
    } else {
      // if (statuses[Permission.camera]!.isDenied) {
      // }
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      // if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      // When you call this function, will be gone to the settings page.
      // So you need to explain to the user why set it.
      //   await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      // }
    }

    /*{Permission.camera: PermissionStatus.granted, Permission.storage: PermissionStatus.granted}*/
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {},
      child: Scaffold(
        body: Center(
          child: Container(
            padding: EdgeInsets.all(100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "twonly needs access to the camera and microphone.",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50),
                FilledButton.icon(
                  label: Text("Request permissions"),
                  icon: const Icon(Icons.perm_camera_mic),
                  onPressed: () async {
                    permissionServices();
                    if (await checkPermissions()) {
                      widget.onSuccess();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
