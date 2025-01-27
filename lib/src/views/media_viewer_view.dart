import 'package:flutter/material.dart';
import 'package:twonly/src/model/contacts_model.dart';

class MediaViewerView extends StatefulWidget {
  final Contact otherUser;
  const MediaViewerView(this.otherUser, {super.key});

  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(widget.otherUser.displayName),
    );
  }
}
