import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';

class SaveToGalleryButton extends StatefulWidget {
  const SaveToGalleryButton({
    required this.storeImageAsOriginal,
    required this.isLoading,
    required this.displayButtonLabel,
    required this.mediaService,
    super.key,
  });
  final Future<Uint8List?> Function() storeImageAsOriginal;
  final bool displayButtonLabel;
  final MediaFileService mediaService;
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

              await widget.storeImageAsOriginal();
              await widget.mediaService.storeMediaFile();

              setState(() {
                _imageSaved = true;
                _imageSaving = false;
              });
            },
      child: Row(
        children: [
          if (_imageSaving || widget.isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1),
            )
          else
            _imageSaved
                ? const Icon(Icons.check)
                : const FaIcon(FontAwesomeIcons.floppyDisk),
          if (widget.displayButtonLabel) const SizedBox(width: 10),
          if (widget.displayButtonLabel)
            Text(
              _imageSaved
                  ? context.lang.shareImagedEditorSavedImage
                  : context.lang.shareImagedEditorSaveImage,
            ),
        ],
      ),
    );
  }
}
