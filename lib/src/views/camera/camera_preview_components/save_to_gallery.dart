import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/thumbnail.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class SaveToGalleryButton extends StatefulWidget {
  const SaveToGalleryButton({
    required this.getMergedImage,
    required this.isLoading,
    required this.displayButtonLabel,
    super.key,
    this.mediaUploadId,
    this.videoFilePath,
  });
  final Future<Uint8List?> Function() getMergedImage;
  final bool displayButtonLabel;
  final File? videoFilePath;
  final int? mediaUploadId;
  final bool isLoading;

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
              var memoryPath = await getMediaBaseFilePath('memories');

              if (widget.mediaUploadId != null) {
                memoryPath = join(memoryPath, '${widget.mediaUploadId!}');
              } else {
                final random = Random();
                final token = uint8ListToHex(
                    List<int>.generate(32, (i) => random.nextInt(256)));
                memoryPath = join(memoryPath, token);
              }
              final user = await getUser();
              if (user == null) return;
              final storeToGallery = user.storeMediaFilesInGallery;

              if (widget.videoFilePath != null) {
                memoryPath += '.mp4';
                await File(widget.videoFilePath!.path).copy(memoryPath);
                unawaited(createThumbnailsForVideo(File(memoryPath)));
                if (storeToGallery) {
                  res = await saveVideoToGallery(widget.videoFilePath!.path);
                }
              } else {
                memoryPath += '.png';
                final imageBytes = await widget.getMergedImage();
                if (imageBytes == null || !mounted) return;
                await File(memoryPath).writeAsBytes(imageBytes);
                unawaited(createThumbnailsForImage(File(memoryPath)));
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
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              setState(() {
                _imageSaving = false;
              });
            },
      child: Row(
        children: [
          if (_imageSaving || widget.isLoading)
            const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1))
          else
            _imageSaved
                ? const Icon(Icons.check)
                : const FaIcon(FontAwesomeIcons.floppyDisk),
          if (widget.displayButtonLabel) const SizedBox(width: 10),
          if (widget.displayButtonLabel)
            Text(_imageSaved
                ? context.lang.shareImagedEditorSavedImage
                : context.lang.shareImagedEditorSaveImage)
        ],
      ),
    );
  }
}
