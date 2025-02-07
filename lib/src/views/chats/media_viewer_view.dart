import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
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
  DateTime? canBeSeenUntil;
  int maxShowTime = 999999;
  bool isRealTwonly = false;
  Timer? _timer;
  // DateTime opened;

  @override
  void initState() {
    super.initState();
    final content = widget.message.messageContent;
    if (content is MediaMessageContent) {
      if (content.isRealTwonly) {
        isRealTwonly = true;
      }
    }
    loadMedia();
  }

  Future loadMedia({bool force = false}) async {
    final content = widget.message.messageContent;
    if (content is MediaMessageContent) {
      if (content.isRealTwonly) {
        if (!force) {
          return;
        }
        try {
          final LocalAuthentication auth = LocalAuthentication();
          bool didAuthenticate = await auth.authenticate(
              localizedReason: 'Please authenticate to see this twonly!',
              options: const AuthenticationOptions(useErrorDialogs: false));
          if (!didAuthenticate) {
            if (context.mounted) {
              Navigator.pop(context);
            }
            return;
          }
        } on PlatformException catch (e) {
          debugPrint(e.toString());
          // these errors because of hardware not available or bio is not enrolled
          // as this is just a nice gimig, do not interrupt the user experience
        }
      }

      List<int> token = content.downloadToken;
      _imageByte =
          await getDownloadedMedia(token, widget.message.messageOtherId!);

      setState(() {});
    }
  }

  startTimer() {
    _timer = Timer(canBeSeenUntil!.difference(DateTime.now()), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  mediaOpened() {
    if (canBeSeenUntil != null) return;
    final content = widget.message.messageContent;
    if (content is MediaMessageContent) {
      if (content.maxShowTime != 999999) {
        canBeSeenUntil = DateTime.now().add(
          Duration(seconds: content.maxShowTime),
        );
        maxShowTime = content.maxShowTime;
        startTimer();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    if (canBeSeenUntil != null) {
      Duration difference = canBeSeenUntil!.difference(DateTime.now());
      print(difference.inMilliseconds);
      // Calculate the progress as a value between 0.0 and 1.0
      progress = (difference.inMilliseconds / (maxShowTime * 1000));
      if (progress <= 0) {
        return Scaffold();
      }
    }
    // progress = 0.8;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageByte != null)
              MediaViewSizing(
                Image.memory(
                  _imageByte!,
                  fit: BoxFit.contain,
                  frameBuilder:
                      ((context, child, frame, wasSynchronouslyLoaded) {
                    if (frame != null || wasSynchronouslyLoaded) {
                      mediaOpened();
                    }
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: frame != null
                          ? child
                          : SizedBox(
                              height: 60,
                              width: 60,
                              child: CircularProgressIndicator(strokeWidth: 6),
                            ),
                    );
                  }),
                ),
              ),
            if (isRealTwonly && _imageByte == null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    loadMedia(force: true);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Lottie.asset(
                          'assets/animations/present.lottie.json',
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(bottom: 200),
                        child: Text("Tap to open your twonly!"),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 10,
              top: 10,
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
              right: 20,
              top: 27,
              child: Row(
                children: [
                  if (canBeSeenUntil != null)
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.0,
                        )),
                ],
              ),
            ),
            if (_imageByte != null)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const SizedBox(width: 20),
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
              ),
          ],
        ),
      ),
    );
  }
}
