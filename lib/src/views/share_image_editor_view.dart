import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twonly/src/utils.dart';
import 'package:twonly/src/views/share_image_view.dart';

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({super.key, required this.image});
  final String image;

  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _isImageLoaded = false;
  bool _imageSaved = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    imageIsLoaded();
  }

  Future imageIsLoaded() async {
    Future.delayed(Duration(milliseconds: 600), () {
      setState(() {
        _isImageLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isImageLoaded
          ? Theme.of(context).colorScheme.surface
          : Colors.white.withAlpha(0),
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
                child: Image.file(
                  File(widget.image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          _isImageLoaded
              ? Positioned(
                  left: 10,
                  top: 60,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 30,
                        ),
                        color: Colors.white,
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                )
              : Container(),
          _isImageLoaded
              ? Positioned(
                  bottom: 70,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: _imageSaved
                            ? Icon(Icons.check)
                            : Icon(Icons.save_rounded),
                        style: OutlinedButton.styleFrom(
                          iconColor: _imageSaved
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: _imageSaved
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (_imageSaved) return;
                          final res = await saveImageToGallery(widget.image);
                          if (res == null) {
                            setState(() {
                              _imageSaved = true;
                            });
                          }
                        },
                        label: Text(_imageSaved
                            ? AppLocalizations.of(context)!
                                .shareImagedEditorSavedImage
                            : AppLocalizations.of(context)!
                                .shareImagedEditorSaveImage),
                      ),
                      const SizedBox(width: 20),
                      FilledButton.icon(
                        icon: Icon(Icons.send),
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ShareImageView(image: widget.image)),
                          );
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                            EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                          ),
                        ),
                        label: Text(
                          AppLocalizations.of(context)!
                              .shareImagedEditorSendImage,
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
