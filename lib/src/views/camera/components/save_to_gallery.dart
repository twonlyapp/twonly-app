import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:typed_data';

import 'package:twonly/src/utils/misc.dart';

class SaveToGalleryButton extends StatefulWidget {
  final Future<Uint8List?> Function() getMergedImage;
  final String? sendNextMediaToUserName;
  final File? videoFilePath;

  const SaveToGalleryButton(
      {super.key,
      required this.getMergedImage,
      this.sendNextMediaToUserName,
      this.videoFilePath});

  @override
  State<SaveToGalleryButton> createState() => SaveToGalleryButtonState();
}

class SaveToGalleryButtonState extends State<SaveToGalleryButton> {
  bool _imageSaving = false;
  bool _imageSaved = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        iconColor: _imageSaved
            ? Theme.of(context).colorScheme.outline
            : Theme.of(context).colorScheme.primary,
        foregroundColor: _imageSaved
            ? Theme.of(context).colorScheme.outline
            : Theme.of(context).colorScheme.primary,
      ),
      onPressed: () async {
        setState(() {
          _imageSaving = true;
        });

        String? res;

        if (widget.videoFilePath != null) {
          res = await saveVideoToGallery(widget.videoFilePath!.path);
        } else {
          Uint8List? imageBytes = await widget.getMergedImage();
          if (imageBytes == null || !context.mounted) return;
          res = await saveImageToGallery(imageBytes);
        }
        if (res == null) {
          setState(() {
            _imageSaved = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _imageSaving = false;
        });
      },
      child: Row(
        children: [
          _imageSaving
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1))
              : _imageSaved
                  ? Icon(Icons.check)
                  : FaIcon(FontAwesomeIcons.floppyDisk),
          if (widget.sendNextMediaToUserName == null) SizedBox(width: 10),
          if (widget.sendNextMediaToUserName == null)
            Text(_imageSaved
                ? context.lang.shareImagedEditorSavedImage
                : context.lang.shareImagedEditorSaveImage)
        ],
      ),
    );
  }
}
