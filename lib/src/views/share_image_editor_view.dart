import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/image_editor/image_editor.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/share_image_view.dart';

class ShareImageEditorView extends StatefulWidget {
  const ShareImageEditorView({super.key, required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<ShareImageEditorView> createState() => _ShareImageEditorView();
}

class _ShareImageEditorView extends State<ShareImageEditorView> {
  bool _imageSaved = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: true
          ? Theme.of(context).colorScheme.surface
          : Colors.white.withAlpha(0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            bottom: 70,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                // child: Container(),
                child: ImageEditor(
                  image: widget.imageBytes,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: _imageSaved
                      ? Icon(Icons.check)
                      : FaIcon(FontAwesomeIcons.floppyDisk),
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
                    final res = await saveImageToGallery(widget.imageBytes);
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
                  icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ShareImageView(imageBytes: widget.imageBytes)),
                    );
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.shareImagedEditorShareWith,
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
