import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
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
    // microphone is only needed when
    return true;
  }
  return true;
}

class PermissionHandlerViewState extends State<PermissionHandlerView> {
  Future<Map<Permission, PermissionStatus>> permissionServices() async {
    // try {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      // Permission.microphone,
      Permission.notification
    ].request();
    // } catch (e) {}
    // You can request multiple permissions at once.

    // if (statuses[Permission.microphone]!.isPermanentlyDenied) {
    //   openAppSettings();
    //   // setState(() {});
    // } else {
    //   // if (statuses[Permission.microphone]!.isDenied) {
    //   // }
    // }

    if (statuses[Permission.camera]!.isPermanentlyDenied) {
      await openAppSettings();
      // setState(() {});
    } else {
      // if (statuses[Permission.camera]!.isDenied) {
      // }
    }

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
                    try {
                      await permissionServices();
                      if (await checkPermissions()) {
                        widget.onSuccess();
                      }
                    } catch (e) {
                      Logger("permissions_view").shout(e);
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
