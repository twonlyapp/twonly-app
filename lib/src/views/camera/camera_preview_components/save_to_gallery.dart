import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/thumbnail.service.dart';
import 'dart:typed_data';

import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class SaveToGalleryButton extends StatefulWidget {
  final Future<Uint8List?> Function() getMergedImage;
  final bool displayButtonLabel;
  final File? videoFilePath;
  final int? mediaUploadId;
  final bool isLoading;

  const SaveToGalleryButton({
    super.key,
    required this.getMergedImage,
    required this.isLoading,
    required this.displayButtonLabel,
    this.mediaUploadId,
    this.videoFilePath,
  });

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
      onPressed: (widget.isLoading)
          ? null
          : () async {
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
              final user = await getUser();
              if (user == null) return;
              bool storeToGallery = user.storeMediaFilesInGallery;

              if (widget.videoFilePath != null) {
                memoryPath += ".mp4";
                await File(widget.videoFilePath!.path).copy(memoryPath);
                createThumbnailsForVideo(File(memoryPath));
                if (storeToGallery) {
                  res = await saveVideoToGallery(widget.videoFilePath!.path);
                }
              } else {
                memoryPath += ".png";
                Uint8List? imageBytes = await widget.getMergedImage();
                if (imageBytes == null || !mounted) return;
                await File(memoryPath).writeAsBytes(imageBytes);
                createThumbnailsForImage(File(memoryPath));
                if (storeToGallery) {
                  res = await saveImageToGallery(imageBytes);
                }
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
          (_imageSaving || widget.isLoading)
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1))
              : _imageSaved
                  ? Icon(Icons.check)
                  : FaIcon(FontAwesomeIcons.floppyDisk),
          if (widget.displayButtonLabel) SizedBox(width: 10),
          if (widget.displayButtonLabel)
            Text(_imageSaved
                ? context.lang.shareImagedEditorSavedImage
                : context.lang.shareImagedEditorSaveImage)
        ],
      ),
    );
  }
}
