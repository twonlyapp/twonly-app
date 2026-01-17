import 'dart:async';
import 'dart:typed_data';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';

class SaveToGalleryButton extends StatefulWidget {
  const SaveToGalleryButton({
    required this.isLoading,
    required this.displayButtonLabel,
    required this.mediaService,
    this.storeImageAsOriginal,
    super.key,
  });
  final Future<Uint8List?> Function()? storeImageAsOriginal;
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

              if (widget.storeImageAsOriginal != null) {
                await widget.storeImageAsOriginal!();
              }

              final newMediaFile = await twonlyDB.mediaFilesDao.insertMedia(
                MediaFilesCompanion(
                  type: Value(widget.mediaService.mediaFile.type),
                  createdAt: Value(clock.now()),
                  stored: const Value(true),
                ),
              );

              if (newMediaFile != null) {
                final newService = MediaFileService(newMediaFile);

                if (widget.mediaService.tempPath.existsSync()) {
                  widget.mediaService.tempPath.copySync(
                    newService.tempPath.path,
                  );
                } else if (widget.mediaService.originalPath.existsSync()) {
                  widget.mediaService.originalPath.copySync(
                    newService.originalPath.path,
                  );
                }
                await newService.storeMediaFile();
              }

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
