import 'dart:async';

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

class PermissionHandlerViewState extends State<PermissionHandlerView>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _isSuccessTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      await _checkAndTriggerSuccess();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndTriggerSuccess();
    }
  }

  Future<void> _checkAndTriggerSuccess() async {
    if (_isSuccessTriggered) return;
    try {
      if (await checkPermissions()) {
        _isSuccessTriggered = true;
        _timer?.cancel();
        // ignore: avoid_dynamic_calls
        widget.onSuccess();
      }
    } catch (e) {
      Log.error(e);
    }
  }

  Future<Map<Permission, PermissionStatus>> permissionServices() async {
    final statuses = await [
      Permission.camera,
      Permission.notification,
    ].request();

    if (statuses[Permission.camera]!.isPermanentlyDenied) {
      await openAppSettings();
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
                      // ignore: avoid_dynamic_calls
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
