import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    List<int> token = widget.message.messageContent!.downloadToken!;
    _imageByte = await getDownloadedMedia(token, widget.message.messageId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            // bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: (_imageByte != null)
                      ? Image.memory(
                          _imageByte!,
                          fit: BoxFit.contain,
                        )
                      : Container()),
            ),
          ),
          _imageByte != null
              ? Positioned(
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
                )
              : Container(),
          _imageByte != null
              ? Positioned(
                  bottom: 70,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      FilledButton.icon(
                        icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                        onPressed: () async {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //       builder: (context) =>
                          //           ShareImageView(image: widget.image)),
                          // );
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                          ),
                        ),
                        label: Text(
                          AppLocalizations.of(context)!
                              .shareImagedEditorShareWith,
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
