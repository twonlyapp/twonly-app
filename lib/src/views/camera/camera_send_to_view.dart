import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/views/camera/camera_preview_controller_view.dart';

class CameraSendToView extends StatefulWidget {
  const CameraSendToView(this.sendTo, {super.key});
  final Contact sendTo;
  @override
  State<CameraSendToView> createState() => CameraSendToViewState();
}

class CameraSendToViewState extends State<CameraSendToView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
    // return Scaffold(
    //   body:  CameraPreviewControllerView(sendTo: widget.sendTo),
    // );
  }
}
