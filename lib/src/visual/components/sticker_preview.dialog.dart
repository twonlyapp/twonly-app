import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/stickers.dart' as rust_stickers;
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
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
  late StickerData _sticker = widget.sticker;
  late Uint8List _webp = Uint8List.fromList(_sticker.webp);
  late String _contentHash = hex.encode(_sticker.sha256);
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
      final local = await rust_stickers.getSticker(
        hash: _contentHash,
        transaction: currentDatabaseSession(),
      );
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
        await rust_stickers.removeSticker(
          hash: _contentHash,
          transaction: currentDatabaseSession(),
        );
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

  Future<void> _rotateSticker() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rotated = await StickerService.rotate(_sticker);
      if (!mounted) return;
      setState(() {
        _sticker = StickerService.fromLocal(rotated);
        _webp = rotated.webp;
        _contentHash = rotated.contentHash;
        _busy = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.lang.stickerRotateFailed;
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
                child: Image.memory(
                  _webp,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
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
              if (widget.collectionOnly) ...[
                const SizedBox(height: 12),
                MyButton(
                  variant: MyButtonVariant.secondaryDense,
                  onPressed: _busy ? null : _rotateSticker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rotate_right),
                      const SizedBox(width: 8),
                      Text(context.lang.rotateSticker),
                    ],
                  ),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  widget.collectionOnly
                      ? context.lang.close
                      : context.lang.cancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
