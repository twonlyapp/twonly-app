import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';

class SaveToGalleryButton extends StatefulWidget {
  const SaveToGalleryButton({
    required this.isLoading,
    required this.displayButtonLabel,
    required this.mediaService,
    this.storeImageAsOriginal,
    super.key,
  });
  final Future<ScreenshotImageHelper?> Function()? storeImageAsOriginal;
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
    final isEnabled = !widget.isLoading && !_imageSaving;
    return MyButton(
      variant: MyButtonVariant.secondaryMiddle,
      onPressed: isEnabled
          ? () async {
              setState(() {
                _imageSaving = true;
              });
              try {
                if (widget.storeImageAsOriginal != null) {
                  await widget.storeImageAsOriginal!();
                }

                // Location lookup completes asynchronously after capture. Read
                // the current row so exporting keeps that fix and capture time.
                await widget.mediaService.updateFromDB();
                final capture = widget.mediaService.mediaFile;

                final newMediaFile = await twonlyDB.mediaFilesDao
                    .insertOrUpdateMedia(
                      MediaFilesCompanion(
                        type: Value(widget.mediaService.mediaFile.type),
                        createdAt: Value(capture.createdAt),
                        locationLatitude: Value(capture.locationLatitude),
                        locationLongitude: Value(capture.locationLongitude),
                        locationAccuracy: Value(capture.locationAccuracy),
                        locationStatus: Value(capture.locationStatus),
                        locationDeadlineAt: Value(capture.locationDeadlineAt),
                        removeAudio: Value(
                          widget.mediaService.mediaFile.removeAudio,
                        ),
                        trimStartMs: Value(
                          widget.mediaService.mediaFile.trimStartMs,
                        ),
                        trimEndMs: Value(
                          widget.mediaService.mediaFile.trimEndMs,
                        ),
                        // Rust publishes the Memory as stored only after the
                        // plaintext and its thumbnail have been written.
                        stored: const Value(false),
                      ),
                    );

                if (newMediaFile != null) {
                  final newService = MediaFileService(newMediaFile);

                  await RustApi.initializeMemoryLocation(
                    mediaId: newMediaFile.mediaId,
                  );

                  if (widget.mediaService.originalPath.existsSync()) {
                    await widget.mediaService.originalPath.copy(
                      newService.originalPath.path,
                    );
                  } else if (widget.mediaService.tempPath.existsSync()) {
                    await widget.mediaService.tempPath.copy(
                      newService.tempPath.path,
                    );
                  }
                  if (widget.mediaService.overlayImagePath.existsSync()) {
                    await widget.mediaService.overlayImagePath.copy(
                      newService.overlayImagePath.path,
                    );
                  }
                  await newService.storeMediaFile();
                  if (mounted) {
                    setState(() {
                      _imageSaved = newService.mediaFile.stored;
                    });
                  }
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _imageSaving = false;
                  });
                }
              }
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_imageSaving || widget.isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation(
                  context.appColor(AppColor.mediaForeground),
                ),
              ),
            )
          else if (_imageSaved)
            const Icon(Icons.check, size: 14)
          else
            const FaIcon(FontAwesomeIcons.floppyDisk, size: 14),
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
