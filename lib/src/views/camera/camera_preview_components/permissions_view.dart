// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/src/utils/log.dart';

class PermissionHandlerView extends StatefulWidget {
  const PermissionHandlerView({required this.onSuccess, super.key});

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
    final statuses = await [
      Permission.camera,
      // Permission.microphone,
      Permission.notification,
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
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'twonly needs access to the camera and microphone.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              FilledButton.icon(
                label: const Text('Request permissions'),
                icon: const Icon(Icons.perm_camera_mic),
                onPressed: () async {
                  try {
                    await permissionServices();
                    if (await checkPermissions()) {
                      widget.onSuccess();
                    }
                  } catch (e) {
                    Log.error(e);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
