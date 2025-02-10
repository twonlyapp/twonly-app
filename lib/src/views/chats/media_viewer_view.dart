import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/media_view_sizing.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/home_view.dart';

final _noScreenshot = NoScreenshot.instance;

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
  double progress = 0;
  Timer? _timer;
  Timer? _timer2;
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
    bool result = await _noScreenshot.screenshotOff();
    debugPrint('Screenshot Off: $result');
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

      flutterLocalNotificationsPlugin.cancel(widget.message.messageId);
      List<int> token = content.downloadToken;
      _imageByte = await getDownloadedMedia(
          token, widget.message.messageOtherId!, widget.message.otherUserId);
      if (_imageByte == null) {
        // image already deleted
        if (context.mounted) {
          Navigator.pop(context);
        }
        return;
      }
      // image loading does require some time
      Future.delayed(Duration(milliseconds: 200), () {
        setState(() {
          mediaOpened();
        });
      });
      setState(() {});
    }
  }

  startTimer() {
    _timer = Timer(canBeSeenUntil!.difference(DateTime.now()), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
    _timer2 = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (canBeSeenUntil != null) {
        Duration difference = canBeSeenUntil!.difference(DateTime.now());
        // Calculate the progress as a value between 0.0 and 1.0
        progress = (difference.inMilliseconds / (maxShowTime * 1000));
        setState(() {});
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
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer2?.cancel();
    _noScreenshot.screenshotOn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageByte != null && (canBeSeenUntil == null || progress >= 0))
              MediaViewSizing(
                Image.memory(
                  _imageByte!,
                  fit: BoxFit.contain,
                  frameBuilder:
                      ((context, child, frame, wasSynchronouslyLoaded) {
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
                      onPressed: () async {
                        context.read<SendNextMediaTo>().updateSendNextMediaTo(
                            widget.otherUser.userId.toInt());
                        globalUpdateOfHomeViewPageIndex(0);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
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
