import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart';
import 'package:twonly/src/services/api/media_send.dart';
import 'dart:typed_data';

import 'package:twonly/src/utils/misc.dart';

class SaveToGalleryButton extends StatefulWidget {
  final Future<Uint8List?> Function() getMergedImage;
  final String? sendNextMediaToUserName;
  final File? videoFilePath;
  final int? mediaUploadId;

  const SaveToGalleryButton(
      {super.key,
      required this.getMergedImage,
      this.sendNextMediaToUserName,
      this.mediaUploadId,
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
        String memoryPath = await getMediaBaseFilePath("memories");

        if (widget.mediaUploadId != null) {
          memoryPath = join(memoryPath, "${widget.mediaUploadId!}");
        } else {
          final Random random = Random();
          String token = uint8ListToHex(
              List<int>.generate(32, (i) => random.nextInt(256)));
          memoryPath = join(memoryPath, token);
        }

        if (widget.videoFilePath != null) {
          memoryPath += ".mp4";
          await File(widget.videoFilePath!.path).copy(memoryPath);
          res = await saveVideoToGallery(widget.videoFilePath!.path);
        } else {
          memoryPath += ".png";
          Uint8List? imageBytes = await widget.getMergedImage();
          if (imageBytes == null || !mounted) return;
          await File(memoryPath).writeAsBytes(imageBytes);
          res = await saveImageToGallery(imageBytes);
        }
        if (res == null) {
          setState(() {
            _imageSaved = true;
          });
        } else if (mounted && context.mounted) {
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
