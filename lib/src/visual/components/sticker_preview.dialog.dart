import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';

Future<void> showStickerPreview(
  BuildContext context,
  StickerData sticker, {
  bool collectionOnly = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _StickerPreviewDialog(
      sticker: sticker,
      collectionOnly: collectionOnly,
    ),
  );
}

class _StickerPreviewDialog extends StatefulWidget {
  const _StickerPreviewDialog({
    required this.sticker,
    required this.collectionOnly,
  });

  final StickerData sticker;
  final bool collectionOnly;

  @override
  State<_StickerPreviewDialog> createState() => _StickerPreviewDialogState();
}

class _StickerPreviewDialogState extends State<_StickerPreviewDialog> {
  late final Uint8List _webp = Uint8List.fromList(widget.sticker.webp);
  late final String _contentHash = hex.encode(widget.sticker.sha256);
  bool _stored = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStoredState();
  }

  Future<void> _loadStoredState() async {
    try {
      final local = await twonlyDB.stickersDao.getByHash(_contentHash);
      if (!mounted) return;
      setState(() {
        _stored = local != null;
        _busy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = context.lang.stickerSaveFailed;
        _busy = false;
      });
    }
  }

  Future<void> _performAction() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_stored || widget.collectionOnly) {
        await twonlyDB.stickersDao.remove(_contentHash);
      } else {
        await StickerService.saveReceived(widget.sticker);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.lang.stickerSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Image.memory(_webp, fit: BoxFit.contain),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: context.color.error)),
                const SizedBox(height: 12),
              ],
              MyButton(
                variant: _stored || widget.collectionOnly
                    ? MyButtonVariant.error
                    : MyButtonVariant.primary,
                onPressed: _busy ? null : _performAction,
                child: _busy
                    ? const ThreeRotatingDots(size: 24)
                    : Text(
                        widget.collectionOnly
                            ? context.lang.deleteSticker
                            : _stored
                            ? context.lang.removeSticker
                            : context.lang.storeSticker,
                      ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.lang.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
