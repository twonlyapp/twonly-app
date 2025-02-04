import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';

class MediaViewerView extends StatefulWidget {
  final Contact otherUser;
  final DbMessage message;
  const MediaViewerView(this.otherUser, this.message, {super.key});

  @override
  State<MediaViewerView> createState() => _MediaViewerViewState();
}

class _MediaViewerViewState extends State<MediaViewerView> {
  Uint8List? _imageByte;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future _initAsync() async {
    final content = widget.message.messageContent;
    if (content is MediaMessageContent) {
      List<int> token = content.downloadToken;
      _imageByte =
          await getDownloadedMedia(token, widget.message.messageOtherId!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageByte == null) return Container();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MediaViewSizing(Image.memory(
            _imageByte!,
            fit: BoxFit.contain,
          )),
          Positioned(
            left: 10,
            top: 60,
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.close, size: 30),
                  color: Colors.white,
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                FilledButton.icon(
                  icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () async {},
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                  ),
                  label: Text(
                    "Respond",
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
